// VPI Secure — Profile Completion Screen
//
// Shown when the authenticated user's Firestore profile exists but fullName is
// missing, null, empty, or whitespace — whether on first sign-in or after an
// app restart with an incomplete prior session.
//
// Responsibilities:
//   • Collect the user's full name (required, trimmed, ≥2 chars, ≤80 chars).
//   • Write it to Firestore via UserProfileService.saveFullName, which also
//     writes nameSource, profileCompleted, and updatedAt in one update().
//   • Navigate to VpiHomePlaceholder on success (pushAndRemoveUntil clears
//     back stack so the user cannot swipe back here).
//   • On save failure stay on screen with the Retry and preserve the typed name.
//   • Provide a Sign Out action for users who want to start a fresh session.

library;

import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../services/user_profile_service.dart';
import '../../home/vpi_dashboard_screen.dart';

class ProfileCompletionScreen extends StatefulWidget {
  final User user;
  final UserProfileService profileService;

  ProfileCompletionScreen({
    super.key,
    required this.user,
    UserProfileService? profileService,
  }) : profileService = profileService ?? UserProfileService();

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nameFocus = FocusNode();

  bool _saving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _onSave() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    // saveFullName writes: fullName, nameSource, profileCompleted, updatedAt.
    final error = await widget.profileService.saveFullName(
      widget.user,
      _nameCtrl.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _errorMessage = error;
      });
      return;
    }

    // Success — navigate to dashboard and clear the back stack so the user
    // cannot press Back to return to profile completion.
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) => VpiDashboardScreen(user: widget.user),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (_) => false,
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────

  Future<void> _onSignOut() async {
    // Dismiss keyboard first so there is no layout flash.
    FocusScope.of(context).unfocus();
    await FirebaseAuth.instance.signOut();
    // The SessionGate's authStateChanges listener fires on sign-out and
    // routes back to OnboardingScreen automatically — no explicit navigation
    // is needed here.
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: SizedBox.expand(),
            ),
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blueGlow10,
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.base,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppSpacing.xl3),

                      // ── Icon ──────────────────────────────────────────────
                      Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.blueGradient,
                              boxShadow: AppDecorations.glowBlueMedium,
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppColors.textPrimary,
                              size: 38,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Wordmark ──────────────────────────────────────────
                      Text(
                        'VPI SECURE',
                        style: AppTextStyles.overlineLarge,
                      ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: AppSpacing.md),

                      // ── Heading ───────────────────────────────────────────
                      Text(
                            'Complete Your Profile',
                            style: AppTextStyles.display3,
                            textAlign: TextAlign.center,
                          )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.15, end: 0),

                      const SizedBox(height: AppSpacing.sm),

                      // ── Description ───────────────────────────────────────
                      Text(
                        'Enter your full name to continue.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl3),

                      // ── Name field ────────────────────────────────────────
                      _NameField(
                            controller: _nameCtrl,
                            focusNode: _nameFocus,
                            enabled: !_saving,
                            onSubmitted: (_) => _onSave(),
                          )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      // ── Error banner ──────────────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: _errorMessage != null
                            ? Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.md,
                                    ),
                                    child: _ErrorBanner(
                                      message: _errorMessage!,
                                    ),
                                  )
                                  .animate()
                                  .fadeIn(duration: 300.ms)
                                  .shakeX(hz: 4, amount: 4)
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Continue to Dashboard button ──────────────────────
                      _SaveButton(isSaving: _saving, onPressed: _onSave)
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Sign out link ─────────────────────────────────────
                      TextButton.icon(
                        onPressed: _saving ? null : _onSignOut,
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        label: Text(
                          'Sign Out',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.base,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 400.ms),

                      const SizedBox(height: AppSpacing.xl3),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NameField
// ─────────────────────────────────────────────────────────────────────────────

class _NameField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 550), () {
        if (mounted) widget.focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.outline,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused ? AppDecorations.glowBlueSoft : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        enabled: widget.enabled,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        keyboardType: TextInputType.name,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        onFieldSubmitted: widget.onSubmitted,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return 'Please enter your full name.';
          if (trimmed.length < 2) return 'Name must be at least 2 characters.';
          if (trimmed.length > 80) {
            return 'Name must be 80 characters or fewer.';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Full name',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(
            Icons.person_outline_rounded,
            color: _focused ? AppColors.primaryBright : AppColors.textMuted,
            size: 20,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          errorStyle: const TextStyle(height: 0, fontSize: 0),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SaveButton  — "Continue to Dashboard"
// ─────────────────────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !isSaving,
      label: 'Continue to Dashboard',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: AppSpacing.buttonHeightLG,
        width: double.infinity,
        decoration: AppDecorations.buttonPrimary,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSaving ? null : onPressed,
            borderRadius: AppSpacing.roundedMD,
            splashColor: AppColors.blueGlow20,
            highlightColor: Colors.transparent,
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppColors.textPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'CONTINUE TO DASHBOARD',
                          style: AppTextStyles.buttonLarge,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedMD,
        color: AppColors.redGlow20,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
