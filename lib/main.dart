import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/presentation/session_gate.dart';
import 'core/theme/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Disable app-verification in debug so phone OTP works on emulators.
  // await FirebaseAuth.instance.setSettings(
  //   appVerificationDisabledForTesting: kDebugMode,
  // );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg0,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const VpiSecureApp());
}

class VpiSecureApp extends StatelessWidget {
  const VpiSecureApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VPI Secure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      // SessionGate is the single routing authority.
      // It listens to FirebaseAuth.authStateChanges() and routes to:
      //   • OnboardingScreen   — signed out
      //   • VpiHomePlaceholder — signed in with a complete profile
      //   • ProfileCompletionScreen — signed in, fullName missing
      //   • SessionErrorScreen — Firestore read failed
      home: const SessionGate(),
    );
  }
}
