/// Phone-number login controller.
///
/// Owns all state and business logic for the phone login screen so that the
/// widget layer remains a pure renderer. The screen creates one instance and
/// calls [dispose] when it is removed from the tree.
///
/// Responsibilities
///   • Country model and default selection (Nigeria +234)
///   • E.164 normalisation with Nigerian-number rules
///   • Input validation (minimum digit check before hitting Firebase)
///   • [sendOtp] — calls [FirebasePhoneAuthService] and returns a typed result
///   • [onAuthSuccess] — shared handler invoked after both automatic and manual
///     sign-in; contains the guard that prevents double-navigation.
///
/// Security notes
///   • Raw phone digits are never logged.
///   • The normalized E.164 string is passed to Firebase only; it is not
///     stored beyond the lifetime of the current OTP session.

library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/firebase_phone_auth_service.dart';

// ── Country model ─────────────────────────────────────────────────────────────

/// Represents a selectable country in the phone-number login screen.
@immutable
class CountryEntry {
  final String name;
  final String dialCode; // e.g. "+234"
  final String flag; // Unicode flag emoji
  final int minDigits; // minimum subscriber-number digits (after country code)
  final int maxDigits; // maximum subscriber-number digits

  const CountryEntry({
    required this.name,
    required this.dialCode,
    required this.flag,
    required this.minDigits,
    required this.maxDigits,
  });

  @override
  String toString() => '$flag $dialCode';
}

/// Countries shown in the selector. Nigeria is listed first and is the default.
const List<CountryEntry> kSupportedCountries = [
  CountryEntry(
    name: 'Nigeria',
    dialCode: '+234',
    flag: '🇳🇬',
    minDigits: 10,
    maxDigits: 10,
  ),
  CountryEntry(
    name: 'Ghana',
    dialCode: '+233',
    flag: '🇬🇭',
    minDigits: 9,
    maxDigits: 10,
  ),
  CountryEntry(
    name: 'Kenya',
    dialCode: '+254',
    flag: '🇰🇪',
    minDigits: 9,
    maxDigits: 10,
  ),
  CountryEntry(
    name: 'South Africa',
    dialCode: '+27',
    flag: '🇿🇦',
    minDigits: 9,
    maxDigits: 9,
  ),
  CountryEntry(
    name: 'United Kingdom',
    dialCode: '+44',
    flag: '🇬🇧',
    minDigits: 10,
    maxDigits: 10,
  ),
  CountryEntry(
    name: 'United States',
    dialCode: '+1',
    flag: '🇺🇸',
    minDigits: 10,
    maxDigits: 10,
  ),
];

// ── Controller state ──────────────────────────────────────────────────────────

/// The phase the phone-login screen is currently in.
enum PhoneLoginState {
  /// Idle — form visible, user can type and tap Continue.
  idle,

  /// Waiting for Firebase to dispatch the SMS / return a result.
  sending,

  /// An error occurred (bad number, rate-limit, Firebase not configured, etc.).
  error,
}

// ── Controller ────────────────────────────────────────────────────────────────

/// Lifecycle: create in [State.initState], call [dispose] in [State.dispose].
///
/// The widget should call [addListener] to rebuild on state changes.
class PhoneLoginController extends ChangeNotifier {
  PhoneLoginController({FirebasePhoneAuthService? service})
    : _service = service ?? FirebasePhoneAuthService();

  final FirebasePhoneAuthService _service;

  // ── Mutable state ─────────────────────────────────────────────────────────

  CountryEntry _country = kSupportedCountries.first; // Nigeria +234
  String _rawInput = ''; // digits typed by the user (no prefix)
  PhoneLoginState _loginState = PhoneLoginState.idle;
  String? _errorMessage;

  /// Prevents duplicate navigation when both [verificationCompleted] (auto)
  /// and [codeSent] + manual verify fire in the same session.
  bool _authHandled = false;

  /// True after [dispose] is called — guards cross-screen callbacks.
  bool _disposed = false;

  // ── Public getters ────────────────────────────────────────────────────────

  CountryEntry get country => _country;

  /// Digits currently in the input field (user-visible, without country code).
  String get rawInput => _rawInput;

  PhoneLoginState get loginState => _loginState;
  String? get errorMessage => _errorMessage;

  /// True when the Continue button should be enabled.
  bool get canSubmit =>
      _loginState == PhoneLoginState.idle &&
      _rawInput.length >= _country.minDigits;

  // ── Input setters ─────────────────────────────────────────────────────────

  void selectCountry(CountryEntry entry) {
    if (_country == entry) return;
    _country = entry;
    _rawInput = ''; // clear input when country changes
    _loginState = PhoneLoginState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void onPhoneChanged(String value) {
    // Strip everything except digits — the UI field already limits input but
    // this guards against paste events.
    _rawInput = value.replaceAll(RegExp(r'[^\d]'), '');
    if (_loginState == PhoneLoginState.error) {
      // Clear error as soon as the user starts correcting the number.
      _loginState = PhoneLoginState.idle;
      _errorMessage = null;
    }
    notifyListeners();
  }

  // ── E.164 normalisation ───────────────────────────────────────────────────

  /// Converts the current [_rawInput] + [_country] into a valid E.164 string.
  ///
  /// Nigerian rules (dialCode == '+234'):
  ///   • Input starts with 0  → strip the leading 0, prepend +234
  ///     e.g.  "08034524290"  → "+2348034524290"
  ///   • Input starts with +234 (user pasted full number) → use as-is
  ///   • Otherwise → prepend +234 directly
  ///     e.g.  "8034524290"   → "+2348034524290"
  ///
  /// All other countries: strip a leading 0, then prepend the dial code.
  String get e164 {
    final digits = _rawInput.replaceAll(RegExp(r'[^\d]'), '');
    final dialDigits = _country.dialCode.replaceAll('+', '');

    // Guard: already a full E.164 number (user pasted "+2348034524290")
    if (_rawInput.startsWith('+')) {
      // Strip any spaces and return as-is; trust the user for pasted values.
      return _rawInput.replaceAll(RegExp(r'\s'), '');
    }

    // Nigerian local numbers start with 0
    if (_country.dialCode == '+234' && digits.startsWith('0')) {
      return '+$dialDigits${digits.substring(1)}';
    }

    // Generic: strip leading 0 for any country, then prefix
    final subscriber = digits.startsWith('0') ? digits.substring(1) : digits;
    return '+$dialDigits$subscriber';
  }

  /// Human-readable label for the current input, used for display only.
  /// Never logged; never passed to Firebase.
  String get displayHint => '${_country.dialCode} ···';

  // ── OTP send ──────────────────────────────────────────────────────────────

  /// Initiates phone verification via [FirebasePhoneAuthService.sendOtp].
  ///
  /// Returns the [OtpSendResult] so the screen can decide navigation.
  /// Sets internal state to [PhoneLoginState.sending] during the call and
  /// transitions to [PhoneLoginState.error] on failure.
  Future<OtpSendResult> sendOtp() async {
    assert(canSubmit, 'sendOtp called when canSubmit is false');

    _authHandled = false;
    _loginState = PhoneLoginState.sending;
    _errorMessage = null;
    notifyListeners();

    final number = e164;
    final result = await _service.sendOtp(number);

    switch (result) {
      case OtpSent():
        // SMS dispatched — screen will navigate to OTP screen.
        // Keep state as sending until navigation completes.
        break;

      case OtpAutoVerified():
        // Auto-verification: will be handled by onAuthSuccess.
        break;

      case OtpSendFailed(:final message):
        _loginState = PhoneLoginState.error;
        _errorMessage = message;
        notifyListeners();
    }

    return result;
  }

  // ── Auth-success handler ──────────────────────────────────────────────────

  /// Must be called by the screen exactly once per sign-in event, regardless
  /// of whether it came from auto-verification or manual OTP entry.
  ///
  /// The [_authHandled] flag prevents the double-navigation race that occurs
  /// when Android fires [verificationCompleted] *and* the user simultaneously
  /// completes the PIN on the OTP screen.
  ///
  /// Returns `true` if this call actually handled the event (i.e. navigation
  /// should proceed); `false` if a concurrent call already handled it.
  bool onAuthSuccess(User user) {
    if (_authHandled) return false;
    _authHandled = true;
    // Only notify if the controller is still alive (it may have been disposed
    // when PhoneLoginScreen was replaced by PhoneOtpScreen via pushReplacement).
    if (!_disposed) {
      _loginState = PhoneLoginState.idle;
      notifyListeners();
    }
    return true;
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  /// Resets the controller to its initial idle state.
  void reset() {
    _rawInput = '';
    _loginState = PhoneLoginState.idle;
    _errorMessage = null;
    _authHandled = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
