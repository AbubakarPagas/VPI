/// ProtectionActivationScreen — Stage 2 stub.
///
/// Destination for the "Activate Protection" action.
///
/// Status rules (enforced at the data layer in [TrustRecord]):
///   • Opening this screen does NOT mark protection as activated.
///   • Granting a single permission does NOT mark protection as activated.
///   • Protection is activated only when all defined service requirements
///     are met and the backend writes protectionStatus = 'completed'.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'feature_stub_screen.dart';

class ProtectionActivationScreen extends StatelessWidget {
  const ProtectionActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeatureStubScreen(
      title: 'Protection Activation',
      icon: Icons.shield_rounded,
      accentColor: AppColors.trusted,
      description:
          'Protection Activation sets up the security services that keep '
          'your device and identity safe after verification.',
      points: [
        'Configure supported security services.',
        'Grant necessary permissions for active protection.',
        'All requirements must be met before protection is marked active.',
      ],
      disclaimer:
          'Simply opening this screen or granting one permission does not '
          'activate protection. All defined service requirements must be '
          'completed and confirmed by the backend.',
    );
  }
}
