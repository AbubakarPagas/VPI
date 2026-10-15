import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

// ── OTP send result ───────────────────────────────────────────────────────────

/// Returned by [FirebasePhoneAuthService.sendOtp] to communicate the outcome
/// of the `verifyPhoneNumber` call back to the UI without exposing Firebase
/// types beyond the service boundary.
sealed class OtpSendResult {
  const OtpSendResult();
}

/// SMS was dispatched successfully — UI should show the PIN input field.
final class OtpSent extends OtpSendResult {
  /// Opaque token used when verifying the code via [FirebasePhoneAuthService.verifyOtp].
  final String verificationId;

  /// Token to pass back on resend requests.
  final int? resendToken;

  const OtpSent({required this.verificationId, this.resendToken});
}

/// Android auto-retrieved the code and sign-in completed without user input.
final class OtpAutoVerified extends OtpSendResult {
  /// The signed-in Firebase user.
  final User user;
  const OtpAutoVerified(this.user);
}

/// The send request failed before an SMS was dispatched.
final class OtpSendFailed extends OtpSendResult {
  final String message;
  final String? code;
  const OtpSendFailed({required this.message, this.code});
}

// ── OTP verify result ─────────────────────────────────────────────────────────

/// Returned by [FirebasePhoneAuthService.verifyOtp].
sealed class OtpVerifyResult {
  const OtpVerifyResult();
}

/// Code was correct — sign-in succeeded.
final class OtpVerifySuccess extends OtpVerifyResult {
  final User user;
  const OtpVerifySuccess(this.user);
}

/// Code was wrong, expired, or another error occurred.
final class OtpVerifyFailure extends OtpVerifyResult {
  final String message;
  final String? code;
  const OtpVerifyFailure({required this.message, this.code});
}

// ── Service ───────────────────────────────────────────────────────────────────

/// Encapsulates all Firebase Phone Authentication logic.
///
/// The UI layer (PhoneOtpScreen) depends only on this service —
/// it never imports firebase_auth directly.
///
/// Responsibilities:
///   • [sendOtp]           — calls verifyPhoneNumber and returns a typed result
///   • [verifyOtp]         — builds a PhoneAuthCredential and signs in
///   • [signOut]           — signs the current user out
///   • [authStateChanges]  — stream of Firebase auth-state events
///   • [currentUser]       — the currently signed-in user, or null
class FirebasePhoneAuthService {
  FirebasePhoneAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Stream of [User?] that emits whenever sign-in state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently signed-in [User], or `null` if no user is signed in.
  User? get currentUser => _auth.currentUser;

  /// Initiates Firebase Phone OTP for [phoneNumber] (E.164 format).
  ///
  /// [resendToken] — pass the token from a previous [OtpSent] result to
  /// force-resend without triggering the same SMS throttle window.
  ///
  /// Returns one of:
  ///   [OtpSent]          — SMS dispatched; hold [verificationId] for [verifyOtp]
  ///   [OtpAutoVerified]  — Android auto-retrieved and signed in (no PIN needed)
  ///   [OtpSendFailed]    — could not send (bad number, quota, network, etc.)
  Future<OtpSendResult> sendOtp(String phoneNumber, {int? resendToken}) async {
    final completer = Completer<OtpSendResult>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: resendToken,
      timeout: const Duration(seconds: 60),

      // Android only: SMS code was auto-read — sign in immediately.
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (completer.isCompleted) return;
        try {
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) {
            completer.complete(OtpAutoVerified(result.user!));
          } else {
            completer.complete(
              const OtpSendFailed(
                message: 'Auto-verification produced no user.',
              ),
            );
          }
        } on FirebaseAuthException catch (e) {
          completer.complete(
            OtpSendFailed(message: _friendlyMessage(e), code: e.code),
          );
        }
      },

      // SMS dispatched — hand verificationId back to the UI.
      codeSent: (String verificationId, int? token) {
        if (completer.isCompleted) return;
        completer.complete(
          OtpSent(verificationId: verificationId, resendToken: token),
        );
      },

      // Could not send the OTP at all.
      verificationFailed: (FirebaseAuthException e) {
        if (completer.isCompleted) return;
        completer.complete(
          OtpSendFailed(message: _friendlyMessage(e), code: e.code),
        );
      },

      // Auto-retrieval window expired; store verificationId if not yet set.
      codeAutoRetrievalTimeout: (String verificationId) {
        // Only complete if codeSent never fired (edge case on some devices).
        if (!completer.isCompleted) {
          completer.complete(
            OtpSent(verificationId: verificationId, resendToken: resendToken),
          );
        }
      },
    );

    return completer.future;
  }

  /// Verifies the 6-digit [smsCode] against [verificationId] and signs in.
  ///
  /// Returns [OtpVerifySuccess] on correct code, [OtpVerifyFailure] otherwise.
  Future<OtpVerifyResult> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        return OtpVerifySuccess(result.user!);
      }
      return const OtpVerifyFailure(message: 'Sign-in produced no user.');
    } on FirebaseAuthException catch (e) {
      return OtpVerifyFailure(message: _friendlyMessage(e), code: e.code);
    }
  }

  /// Signs the current user out of Firebase.
  Future<void> signOut() => _auth.signOut();

  // ── Internal helpers ────────────────────────────────────────────────────

  /// Maps Firebase error codes to user-facing messages.
  static String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
        return 'The code has expired. Tap "Resend" to get a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment before retrying.';
      case 'invalid-phone-number':
        return 'The phone number is invalid. Please check and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and retry.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Contact support.';
      case 'missing-verification-code':
        return 'Please enter the 6-digit code sent to your phone.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
