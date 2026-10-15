import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/app_spacing.dart';

/// Temporary home placeholder — replace with the real dashboard when ready.
///
/// Shows confirmation that the phone number was verified and welcomes the user.
class VpiHomePlaceholder extends StatelessWidget {
  final String phoneNumber;

  const VpiHomePlaceholder({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl3),

                // ── App wordmark
                Text(
                  'VPI SECURE',
                  style: AppTextStyles.overlineLarge,
                ).animate().fadeIn(duration: 500.ms),

                const SizedBox(height: AppSpacing.xl2),

                // ── Verified shield
                Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.trustedGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.trustedGlow,
                            blurRadius: 32,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.verified_user_rounded,
                        color: AppColors.bg0,
                        size: 48,
                      ),
                    )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.6, 0.6),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: AppSpacing.xl),

                // ── Identity Verified
                Text(
                  'Phone Verified',
                  style: AppTextStyles.h3.copyWith(color: AppColors.trusted),
                  textAlign: TextAlign.center,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: AppSpacing.sm),

                // ── Welcome
                Text(
                      'Welcome',
                      style: AppTextStyles.display2,
                      textAlign: TextAlign.center,
                    )
                    .animate(delay: 420.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: AppSpacing.xl3),

                // ── Placeholder dashboard notice
                Container(
                  width: double.infinity,
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    color: AppColors.bg2,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction_rounded,
                        color: AppColors.primaryBright,
                        size: 32,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Dashboard Coming Soon',
                        style: AppTextStyles.h4,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'The full VPI Secure dashboard is under construction. '
                        'This is a development placeholder.',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate(delay: 540.ms).fadeIn(duration: 400.ms),

                const Spacer(),

                const SizedBox(height: AppSpacing.base),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
