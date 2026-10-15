/// Shared stub layout used by Device Verification, Identity Verification,
/// and Protection Activation screens while their flows are not yet built.
///
/// Provides a polished, honest landing page rather than a blank screen or
/// a misleading "coming soon" splash.
///
/// [FeatureStubScreen] is intentionally public so the three stub screens
/// in this directory can use it directly — they are all within the same
/// `home/features/` package boundary.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// A polished "not yet available" screen used as a placeholder for feature
/// destinations that have been routed but not yet implemented.
class FeatureStubScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final String description;
  final List<String> points;
  final String disclaimer;

  const FeatureStubScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.description,
    required this.points,
    required this.disclaimer,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        iconSize: 20,
                        color: AppColors.primaryBright,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.pagePadding.copyWith(top: AppSpacing.xl),
                    child: _buildContent(reduceMotion),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool reduceMotion) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Icon ─────────────────────────────────────────────────────────
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: AppSpacing.iconXL, color: accentColor),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── "Not yet available" badge ─────────────────────────────────────
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              borderRadius: AppSpacing.pill,
              color: AppColors.warning.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 12,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Not yet available',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.warning,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Description ───────────────────────────────────────────────────
        Text(
          description,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.65,
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── What this feature will do ─────────────────────────────────────
        Text(
          'WHAT THIS FEATURE DOES',
          style: AppTextStyles.overline.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        for (final point in points) ...[
          _BulletPoint(text: point, accentColor: accentColor),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.xl),

        // ── Disclaimer card ───────────────────────────────────────────────
        Container(
          padding: AppSpacing.cardPadding,
          decoration: AppDecorations.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: AppSpacing.iconSM,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  disclaimer,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.xl3),
      ],
    );

    if (reduceMotion) return content;

    return content
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BulletPoint
// ─────────────────────────────────────────────────────────────────────────────

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _BulletPoint({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
