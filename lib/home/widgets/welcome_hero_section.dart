/// Dashboard welcome hero section.
///
/// Displays the brand headline and supporting tagline below the app bar.
/// Deliberately NOT inside a card — the text has generous breathing room
/// and its own visual weight.
///
/// Typography hierarchy:
///   • Heading  — Rajdhani h1 / h2 (large, bold, white)
///   • Subtext  — Inter body medium (muted secondary)
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class WelcomeHeroSection extends StatelessWidget {
  const WelcomeHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Honour system accessibility text-scale without clipping.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Overline label ──────────────────────────────────────────────
          Text(
            'VPI SECURE',
            style: AppTextStyles.overlineLarge.copyWith(
              fontSize: 11,
              letterSpacing: 3.0,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Primary heading ─────────────────────────────────────────────
          Text(
            'Your Digital Trust\nMatters',
            style: AppTextStyles.h1.copyWith(
              fontSize: 26,
              letterSpacing: 0.8,
              height: 1.2,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Supporting text ─────────────────────────────────────────────
          Text(
            'Verify your device, confirm your identity,\n'
            'and activate protection.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
