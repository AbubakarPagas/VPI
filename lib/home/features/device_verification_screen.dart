/// DeviceVerificationScreen — Stage 2 stub.
///
/// Destination for the "Verify Device" action on the dashboard's completion
/// steps.  Stage 2 does not implement the verification flow — it provides a
/// polished, honest landing page.
///
/// Replace this file with the real implementation when the flow is built.
/// The navigation call in [VpiDashboardScreen] does not need to change.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'feature_stub_screen.dart';

class DeviceVerificationScreen extends StatelessWidget {
  const DeviceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureStubScreen(
      title: 'Device Verification',
      icon: Icons.security_rounded,
      accentColor: AppColors.primary,
      description:
          'Device Verification checks your device details against '
          'available records to confirm it has not been flagged or reported.',
      points: [
        'Scan your device for known security indicators.',
        'Cross-reference against available device records.',
        'Identify any flags or caution items on file.',
      ],
      disclaimer:
          'Device verification results are read-only. '
          'No data is modified on your device.',
    );
  }
}
