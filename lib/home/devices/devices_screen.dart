/// VPI Secure — Devices Screen.
///
/// Tab-mode placeholder shown in the bottom-navigation Devices tab.
/// Styled to match the app's deep-navy cybersecurity aesthetic.
///
/// Architecture:
///   • Stateless — Stage 1 shows a polished empty / coming-soon state.
///   • No back button — this is a root tab destination.
///   • [CustomScrollView] body ready for future device list items.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DevicesScreen
// ─────────────────────────────────────────────────────────────────────────────

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          // Background gradient
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SizedBox.expand(),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Top bar ────────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildTopBar()),

                // ── Empty / coming-soon state ──────────────────────────────
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(reduceMotion: reduceMotion),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        0,
      ),
      child: Row(
        children: [
          // Section icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryGlass,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
              border: Border.all(color: AppColors.blueGlow20, width: 1),
            ),
            child: const Icon(
              Icons.devices_rounded,
              color: AppColors.primaryBright,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('My Devices', style: AppTextStyles.h3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool reduceMotion;
  const _EmptyState({required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Glow ring + icon
        _GlowIcon(reduceMotion: reduceMotion),
        const SizedBox(height: AppSpacing.xl),

        Text(
          'No Devices Yet',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Text(
            'Your registered and monitored devices will appear here. '
            'Complete device verification to get started.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),

        // Status chips row
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          alignment: WrapAlignment.center,
          children: const [
            _StatusChip(
              icon: Icons.security_rounded,
              label: 'Device Scan',
              color: AppColors.primary,
            ),
            _StatusChip(
              icon: Icons.verified_rounded,
              label: 'Verified',
              color: AppColors.trusted,
            ),
            _StatusChip(
              icon: Icons.shield_outlined,
              label: 'Protected',
              color: AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl3),
      ],
    );

    if (reduceMotion) return content;
    return content
        .animate()
        .fadeIn(duration: 480.ms, curve: Curves.easeOut)
        .slideY(begin: 0.08, end: 0, duration: 480.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlowIcon
// ─────────────────────────────────────────────────────────────────────────────

class _GlowIcon extends StatelessWidget {
  final bool reduceMotion;
  const _GlowIcon({required this.reduceMotion});

  @override
  Widget build(BuildContext context) {
    Widget icon = Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg2,
        border: Border.all(color: AppColors.blueGlow40, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.blueGlow40,
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(
        Icons.devices_rounded,
        color: AppColors.primaryBright,
        size: 40,
      ),
    );

    if (reduceMotion) return icon;
    return icon
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .custom(
          duration: 2400.ms,
          curve: Curves.easeInOut,
          builder: (_, value, child) => AnimatedContainer(
            duration: Duration.zero,
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg2,
              border: Border.all(color: AppColors.blueGlow40, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueGlow40.withOpacity(0.3 + 0.3 * value),
                  blurRadius: 28 + 12 * value,
                  spreadRadius: 4 + 4 * value,
                ),
              ],
            ),
            child: child,
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatusChip
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
