/// VPI Secure — Alerts Screen.
///
/// Stage 1 implementation: shows a polished empty state when there are no
/// alerts. The structure is intentionally ready for real alert items to be
/// added as [SliverList] children in a future stage.
///
/// Architecture:
///   • Stateless — no data source yet; the empty state is authoritative.
///   • Header displays an unread-count badge (0 in Stage 1).
///   • [CustomScrollView] body ready for future [SliverList] sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AlertsScreen
// ─────────────────────────────────────────────────────────────────────────────

class AlertsScreen extends StatelessWidget {
  /// Unread alert count passed from the dashboard.
  /// Kept as a parameter so future stages can pass real data.
  final int unreadCount;

  const AlertsScreen({super.key, this.unreadCount = 0});

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
                // ── Top bar ───────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildTopBar(context)),

                // ── Empty state ───────────────────────────────────────────
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(reduceMotion: reduceMotion),
                ),

                // Future alert items inserted here as a SliverList.
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            iconSize: 20,
            color: AppColors.primaryBright,
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('Alerts', style: AppTextStyles.h3),
          if (unreadCount > 0) ...[
            const SizedBox(width: AppSpacing.sm),
            _CountBadge(count: unreadCount),
          ],
          const Spacer(),
          // Placeholder mark-all-read — wired in a future stage.
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded),
              iconSize: 20,
              color: AppColors.primaryBright,
              tooltip: 'Mark all as read',
              onPressed: () {}, // future stage
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountBadge  — small pill showing the unread count
// ─────────────────────────────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
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
        // Bell icon with soft glow ring
        _GlowBell(),

        const SizedBox(height: AppSpacing.xl),

        Text('All Clear', style: AppTextStyles.h2, textAlign: TextAlign.center),

        const SizedBox(height: AppSpacing.sm),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Text(
            'You have no alerts right now.\n'
            'Security events and trust updates will appear here.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: AppSpacing.xl3),

        // Hint chip
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: AppColors.primaryBright,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Your account is being monitored',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryBright,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (reduceMotion) return content;

    return content
        .animate()
        .fadeIn(duration: 450.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 450.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _GlowBell  — decorative bell icon with concentric glow rings
// ─────────────────────────────────────────────────────────────────────────────

class _GlowBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blueGlow10,
            ),
          ),
          // Inner ring
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blueGlow20,
            ),
          ),
          // Icon surface
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.bg2,
              border: Border.all(
                color: AppColors.primaryBright.withValues(alpha: 0.3),
              ),
              boxShadow: AppDecorations.glowBlueSoft,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 30,
              color: AppColors.primaryBright,
            ),
          ),
        ],
      ),
    );
  }
}
