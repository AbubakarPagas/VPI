/// VPI Secure — Dashboard Screen (Stage 2).
///
/// Architecture:
///   • Owns both [DashboardController] (profile) and [TrustController]
///     (trust score + verification state) as independent ChangeNotifiers.
///   • Both are created in [initState] and disposed in [dispose].
///   • A single [_onControllerUpdate] listener is shared; it calls
///     [setState] on either notification, keeping rebuilds cheap.
///
/// Trust refresh:
///   • [_trustCtrl.refresh()] is called when the user returns from any of
///     the three feature screens so status changes made on those screens
///     are reflected without requiring a manual pull-to-refresh.
///
/// Layout (unchanged from Stage 1):
///   • [Scaffold] + custom [DashboardAppBar]
///   • [CustomScrollView] with [SliverToBoxAdapter] per section
///   • Max content width 600 dp (tablet-safe)
///
/// Sections (in order):
///   1. WelcomeHeroSection
///   2. TrustScoreCard              ← Stage 2 addition
///   3. CompletionStepsSection      ← Stage 2 addition
///   4. (future: My Device, Quick Actions, Recent Activity, …)
///
/// Navigation:
///   • Profile  → ProfileScreen (slide from right)
///   • Alerts   → AlertsScreen  (slide from right)
///   • Step 0   → DeviceVerificationScreen   (slide from right, refresh on return)
///   • Step 1   → IdentityVerificationScreen (slide from right, refresh on return)
///   • Step 2   → ProtectionActivationScreen (slide from right, refresh on return)
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import 'alerts/alerts_screen.dart';
import 'controllers/dashboard_controller.dart';
import 'features/device_verification_screen.dart';
import 'features/identity_verification_screen.dart';
import 'features/protection_activation_screen.dart';
import '../auth/models/user_profile.dart';
import 'profile/profile_screen.dart';
import 'trust/trust_controller.dart';
import 'trust/trust_record.dart';
import 'widgets/completion_steps_section.dart';
import 'widgets/dashboard_app_bar.dart';
import 'widgets/trust_score_card.dart';
import 'widgets/welcome_hero_section.dart';

// ── Max content width (phone fills fully; tablet centres) ────────────────────
const double _kMaxContentWidth = 600;

// ─────────────────────────────────────────────────────────────────────────────
// VpiDashboardScreen
// ─────────────────────────────────────────────────────────────────────────────

class VpiDashboardScreen extends StatefulWidget {
  final User user;

  /// Called when the user taps the notification bell.
  /// In [MainShell] this switches to the Alerts tab instead of pushing a
  /// new route, keeping the tab's state alive.
  final VoidCallback? onBellTap;

  const VpiDashboardScreen({
    super.key,
    required this.user,
    this.onBellTap,
  });

  @override
  State<VpiDashboardScreen> createState() => _VpiDashboardScreenState();
}

class _VpiDashboardScreenState extends State<VpiDashboardScreen> {
  late final DashboardController _profileCtrl;
  late final TrustController _trustCtrl;

  @override
  void initState() {
    super.initState();
    _profileCtrl = DashboardController(user: widget.user)
      ..addListener(_onUpdate);
    _trustCtrl = TrustController(user: widget.user)
      ..addListener(_onUpdate);
  }

  @override
  void dispose() {
    _profileCtrl
      ..removeListener(_onUpdate)
      ..dispose();
    _trustCtrl
      ..removeListener(_onUpdate)
      ..dispose();
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  static Route<T> _slideRoute<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (ctx, animation, secAnim) => page,
        transitionsBuilder: (ctx, animation, secAnim, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOut),
          ),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 320),
      );

  void _goToProfile() {
    Navigator.of(context)
        .push(_slideRoute<void>(ProfileScreen(user: widget.user)));
  }

  /// Delegates to [MainShell.switchToAlerts] when available (tab mode),
  /// or falls back to pushing AlertsScreen as a full route (standalone use).
  void _onBellTap() {
    if (widget.onBellTap != null) {
      widget.onBellTap!();
    } else {
      Navigator.of(context)
          .push(_slideRoute<void>(const AlertsScreen(unreadCount: 0)));
    }
  }

  // Feature screens — refresh trust data on return so any status change
  // made on those screens is reflected in the dashboard immediately.
  Future<void> _goToStep(int stepIndex) async {
    final Widget destination;
    switch (stepIndex) {
      case 0:
        destination = const DeviceVerificationScreen();
      case 1:
        destination = const IdentityVerificationScreen();
      case 2:
        destination = const ProtectionActivationScreen();
      default:
        return;
    }
    await Navigator.of(context).push(_slideRoute<void>(destination));
    // Refresh trust state after returning — the feature screen may have
    // triggered a backend write that changed the verification status.
    if (mounted) _trustCtrl.refresh();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: _buildAppBar(),
      body: _buildBody(reduceMotion),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final appBar = DashboardAppBar(
      profileState: _profileCtrl.state,
      onAvatarTap: _goToProfile,
      onBellTap: _onBellTap,
      unreadCount: 0,
    );

    return PreferredSize(
      preferredSize: appBar.preferredSize,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg1,
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: appBar,
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(bool reduceMotion) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── 1. Welcome hero ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _animated(
                    child: const WelcomeHeroSection(),
                    delayMs: 80,
                    reduceMotion: reduceMotion,
                  ),
                ),

                // ── Profile load error (rare; shown above the score card) ──
                if (_profileCtrl.state is ProfileFailed)
                  SliverToBoxAdapter(
                    child: _ErrorRetryBanner(
                      message:
                          (_profileCtrl.state as ProfileFailed).message,
                      onRetry: _profileCtrl.refresh,
                    ),
                  ),

                // ── 2. Trust Score card ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _animated(
                    child: TrustScoreCard(
                      trustState: _trustCtrl.state,
                      onRetry: _trustCtrl.refresh,
                      reduceMotion: reduceMotion,
                    ),
                    delayMs: 160,
                    reduceMotion: reduceMotion,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.lg),
                ),

                // ── 3. Completion steps ────────────────────────────────────
                SliverToBoxAdapter(
                  child: _animated(
                    child: _buildStepsSection(reduceMotion),
                    delayMs: 240,
                    reduceMotion: reduceMotion,
                  ),
                ),

                // ── Future sections: My Device, Quick Actions,
                //    Recent Activity, Cybersecurity Awareness.

                // ── Bottom breathing room ──────────────────────────────────
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Steps section helper ──────────────────────────────────────────────────

  Widget _buildStepsSection(bool reduceMotion) {
    switch (_trustCtrl.state) {
      case TrustLoading():
        // Show skeletons while trust is loading.
        return _CompletionStepsSkeleton();

      case TrustFailed(:final message):
        // Trust error already shown inside TrustScoreCard's retry banner.
        // Show a minimal retry here as well so the steps area isn't blank.
        return _ErrorRetryBanner(
          message: message,
          onRetry: _trustCtrl.refresh,
        );

      case TrustLoaded(:final record):
        return CompletionStepsSection(
          record: record,
          onActionTap: _goToStep,
          reduceMotion: reduceMotion,
        );
    }
  }

  // ── Animation helper ──────────────────────────────────────────────────────

  Widget _animated({
    required Widget child,
    int delayMs = 0,
    bool reduceMotion = false,
  }) {
    if (reduceMotion) return child;
    return child
        .animate(delay: Duration(milliseconds: delayMs))
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 420.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CompletionStepsSkeleton
// Shown while TrustLoading so the layout doesn't jump on first load.
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionStepsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section heading skeleton
          _Bone(width: 140, height: 16),
          const SizedBox(height: AppSpacing.md),
          // Three step card skeletons
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _StepCardBone(),
          ],
        ],
      ),
    );
  }
}

class _StepCardBone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppSpacing.roundedLG,
        border: Border.all(color: AppColors.divider),
      ),
      padding: AppSpacing.cardPaddingSmall,
      child: Row(
        children: [
          // Icon chip bone
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.bg3,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Bone(width: 120, height: 13),
                const SizedBox(height: 6),
                _Bone(width: 160, height: 10),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Bone(width: 70, height: 28),
        ],
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  final double width;
  final double height;
  const _Bone({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg3,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXS),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorRetryBanner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorRetryBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRetryBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      child: Container(
        padding: AppSpacing.cardPaddingSmall,
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: AppSpacing.iconSM,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
