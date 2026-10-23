// VPI Secure — Session Gate
//
// The single source of routing truth on app launch and after every auth-state
// change (sign-in, sign-out, token refresh).
//
// ── Flow ─────────────────────────────────────────────────────────────────────
//
//   authStateChanges() emits
//     user == null         → OnboardingScreen  (sign-in flow)
//     user != null         → resolveProfile(user)
//       ProfileComplete    → VpiHomePlaceholder (dashboard)
//       ProfileIncomplete  → ProfileCompletionScreen
//       ProfileMissing     → initProfile() → ProfileCompletionScreen
//       ProfileError       → SessionErrorScreen (Retry / Sign Out)
//
// ── Stale-result safety ───────────────────────────────────────────────────────
//   _generation is incremented on every auth event.  Any async callback that
//   finishes with an outdated generation silently discards its result, so a
//   slow Firestore read from a prior sign-in can never route the user after a
//   subsequent sign-out.
//
// ── Navigation contract ────────────────────────────────────────────────────
//   All routing goes through _navigate() which calls pushAndRemoveUntil so
//   the back-stack is always cleared.  Login / completion screens are never
//   reachable via the back button once the user reaches the dashboard.

library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../home/shell/main_shell.dart';
import '../services/user_profile_service.dart';
import 'phone_login_screen.dart';
import 'profile_completion_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SessionGate
// ─────────────────────────────────────────────────────────────────────────────

class SessionGate extends StatefulWidget {
  /// Overridable for testing.
  final UserProfileService? profileService;

  const SessionGate({super.key, this.profileService});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final UserProfileService _profileService;
  late final StreamSubscription<User?> _authSub;

  /// Incremented on every new auth event — allows stale async results to be
  /// detected and discarded before they can affect navigation.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? UserProfileService();
    // Listen to the Firebase auth stream.  The first event fires immediately
    // with the current auth state, so no explicit "check on launch" is needed.
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthEvent);
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  // ── Auth event handler ────────────────────────────────────────────────────

  Future<void> _onAuthEvent(User? user) async {
    final gen = ++_generation;

    if (user == null) {
      // Signed out — show onboarding immediately, no Firestore needed.
      _navigate(gen, _onboardingRoute());
      return;
    }

    // Signed in — resolve Firestore profile before routing.
    // The gate widget itself shows a loading screen while we wait.
    if (mounted) setState(() {}); // trigger rebuild to show loader if needed

    ProfileResolution resolution = await _profileService.resolveProfile(user);
    if (gen != _generation || !mounted) return;

    // Missing document: safely create it (transaction checks existence first),
    // then treat the user as having an incomplete profile.
    if (resolution is ProfileMissing) {
      final error = await _profileService.initProfile(user);
      if (gen != _generation || !mounted) return;

      if (error != null) {
        _navigate(gen, _errorRoute(user, error));
        return;
      }
      resolution = const ProfileIncomplete(['fullName']);
    }

    switch (resolution) {
      case ProfileComplete():
        _navigate(gen, _dashboardRoute(user));
      case ProfileIncomplete():
        _navigate(gen, _completionRoute(user));
      case ProfileMissing():
        // Unreachable — already handled above; keeps the switch exhaustive.
        _navigate(gen, _completionRoute(user));
      case ProfileError(:final message):
        _navigate(gen, _errorRoute(user, message));
    }
  }

  // ── Navigation helper ─────────────────────────────────────────────────────

  /// Replaces the entire navigator stack with [route].
  /// No-ops if [gen] has been superseded by a newer auth event.
  void _navigate(int gen, Route<void> route) {
    if (gen != _generation || !mounted) return;
    Navigator.of(context).pushAndRemoveUntil(route, (_) => false);
  }

  // ── Route factories ───────────────────────────────────────────────────────

  Route<void> _onboardingRoute() => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => OnboardingScreen(onCompleted: _goToLogin),
    transitionsBuilder: _fade,
    transitionDuration: const Duration(milliseconds: 500),
  );

  Route<void> _dashboardRoute(User user) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => MainShell(user: user),
    transitionsBuilder: _fade,
    transitionDuration: const Duration(milliseconds: 500),
  );

  Route<void> _completionRoute(User user) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) =>
        ProfileCompletionScreen(user: user, profileService: _profileService),
    transitionsBuilder: _fade,
    transitionDuration: const Duration(milliseconds: 500),
  );

  Route<void> _errorRoute(User user, String message) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => SessionErrorScreen(
      message: message,
      onRetry: () => _onAuthEvent(user),
      onSignOut: () => FirebaseAuth.instance.signOut(),
    ),
    transitionsBuilder: _fade,
    transitionDuration: const Duration(milliseconds: 400),
  );

  static Widget _fade(
    BuildContext _,
    Animation<double> a,
    Animation<double> _,
    Widget child,
  ) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
    child: child,
  );

  // ── Onboarding completion ─────────────────────────────────────────────────

  /// Called when the user taps Skip or Get Started in OnboardingScreen.
  /// Pushes PhoneLoginScreen onto the stack so the user can sign in.
  /// The gate remains alive on the root so that after a successful sign-in the
  /// auth stream fires and the gate routes them forward automatically.
  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => const PhoneLoginScreen(),
        transitionsBuilder: _fade,
        transitionDuration: const Duration(milliseconds: 500),
      ),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // The gate itself shows a loading screen.  _onAuthEvent navigates away as
    // soon as the profile resolution is done.  For an already-signed-in user
    // this is shown only for the Firestore round-trip (~100 ms on a good
    // connection).
    return const _SessionLoadingScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SessionLoadingScreen
// ─────────────────────────────────────────────────────────────────────────────

class _SessionLoadingScreen extends StatelessWidget {
  const _SessionLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primaryBright,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Loading…', style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SessionErrorScreen
//
// Shown when Firestore fails during the startup profile read.
// Provides Retry (re-reads without re-authenticating) and Sign Out.
// ─────────────────────────────────────────────────────────────────────────────

class SessionErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSignOut;

  const SessionErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Error icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.danger,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'Could Not Load Profile',
                  style: AppTextStyles.h2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  message,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Retry
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.blueGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blueGlow40,
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onRetry,
                        borderRadius: BorderRadius.circular(14),
                        splashColor: Colors.white12,
                        child: Center(
                          child: Text(
                            'Retry',
                            style: AppTextStyles.buttonLarge,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sign out
                TextButton(
                  onPressed: onSignOut,
                  child: Text(
                    'Sign Out',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
