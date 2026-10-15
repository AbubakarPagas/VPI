// Smoke test for the VPI Secure app entry point.
//
// Verifies that the onboarding screen mounts without throwing and that the
// first page label is visible.  Firebase is not initialised here, so
// OnboardingScreen is tested directly via a minimal test harness that
// bypasses the full MaterialApp/Firebase bootstrap.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vpi_secure/features/onboarding/screens/onboarding_screen.dart';
import 'package:vpi_secure/core/theme/app_theme.dart';

void main() {
  testWidgets('OnboardingScreen renders first page without overflow', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: OnboardingScreen(
          // Use the callback variant so no Navigator.pushReplacement is needed.
          onCompleted: () {},
        ),
      ),
    );

    // Let entrance animations settle.
    await tester.pump(const Duration(milliseconds: 600));

    // The first page section label should be present.
    expect(find.text('VERIFY'), findsOneWidget);

    // The Next button should be present on the first page.
    expect(find.text('Next'), findsOneWidget);

    // Skip should be present on the first page.
    expect(find.text('Skip'), findsOneWidget);

    // No overflow errors.
    expect(tester.takeException(), isNull);
  });
}
