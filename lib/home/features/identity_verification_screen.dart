/// IdentityVerificationScreen — Stage 2 stub.
///
/// Destination for the "Verify Identity" action.
///
/// Status rules (enforced at the data layer in [TrustRecord]):
///   • Phone OTP does NOT constitute identity verification.
///   • Entering a full name does NOT constitute identity verification.
///   • Identity is verified only when a backend NIN-check record writes
///     identityVerificationStatus = 'completed' to Firestore.
///
/// This screen must NOT write any verification status to Firestore.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'feature_stub_screen.dart';

class IdentityVerificationScreen extends StatelessWidget {
  const IdentityVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureStubScreen(
      title: 'Identity Verification',
      icon: Icons.badge_rounded,
      accentColor: AppColors.primaryBright,
      description:
          'Identity Verification confirms who you are by validating your '
          'National Identification Number (NIN) against government records.',
      points: [
        'Enter your NIN for verification.',
        'Records are validated against the official NIN database.',
        'Verification is confirmed by the backend — not the app.',
      ],
      disclaimer:
          'Phone sign-in and entering your name are not considered '
          'identity verification. Completion is confirmed by the backend only.',
    );
  }
}
