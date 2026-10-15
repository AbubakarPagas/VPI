import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../widgets/onboarding_illustrations.dart';

/// Immutable data for a single onboarding page.
class OnboardingPageData {
  final String sectionLabel;
  final String title;
  final String description;
  final Widget illustration;
  final Color glowColor;

  const OnboardingPageData({
    required this.sectionLabel,
    required this.title,
    required this.description,
    required this.illustration,
    required this.glowColor,
  });
}

/// The four VPI Secure onboarding pages — VERIFY, PROTECT, IDENTIFY, TRUST SCORE.
final List<OnboardingPageData> kOnboardingPages = [
  OnboardingPageData(
    sectionLabel: 'VERIFY',
    title: 'Check Before You Trust',
    description:
        'Check device details and available records, and verify your '
        "identity when you're ready.",
    illustration: const FingerprintIllustration(),
    glowColor: AppColors.primary,
  ),
  OnboardingPageData(
    sectionLabel: 'PROTECT',
    title: 'Protect What Matters',
    description:
        'Set up supported protection services, receive security alerts, '
        'and report a lost or stolen device.',
    illustration: const RadarIllustration(),
    glowColor: AppColors.trusted,
  ),
  OnboardingPageData(
    sectionLabel: 'IDENTIFY',
    title: 'Recognize Risks Early',
    description:
        'Understand your Trust Score and learn safer ways to respond to '
        'scams and digital threats.',
    illustration: const TrustNetworkIllustration(),
    glowColor: AppColors.warning,
  ),
  OnboardingPageData(
    sectionLabel: 'TRUST SCORE',
    title: '',
    // description: 'Your Digital Trust at a Glance',
    description:
        'Your dashboard shows your Trust Score, with clear steps to complete '
        'device verification, identity verification, and protection activation.',
    illustration: const TrustScoreIllustration(),
    glowColor: AppColors.primary,
  ),
];
