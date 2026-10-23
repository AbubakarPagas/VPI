// VPI Secure — Phone OTP Verification Screen
//
// ── Responsibilities ──────────────────────────────────────────────────────────
//   • Display "Verify Your Phone" heading with masked destination number.
//   • Accept a 6-digit SMS code via an accessible Pinput field that supports
//     paste, autofill, and one-time-code keyboard suggestions.
//   • On completion call FirebasePhoneAuthService.verifyOtp, which builds a
//     PhoneAuthCredential and calls FirebaseAuth.signInWithCredential.
//   • Reuse a single _handleAuthSuccess path for both automatic (Android
//     verificationCompleted) and manual verification.
//   • After sign-in, call UserProfileService.resolveProfile and route based on
//     the ProfileResolution — never solely on isNewUser.
//   • Resend via verifyPhoneNumber using the resend token (rate-limit guard).
//   • "Change number" action navigates back to PhoneLoginScreen.
//   • Expose a visible cooldown timer that disables resend while active.
//
// ── Two entry modes ───────────────────────────────────────────────────────────
//   PhoneOtpScreen.fromLogin(...)   — Phone-login flow; OTP already sent.
//
// ── Security ──────────────────────────────────────────────────────────────────
//   • OTP codes, credentials, and verification IDs are NEVER logged or stored.
//   • codeAutoRetrievalTimeout is treated as informational only; it does NOT
//     invalidate the active verification session.
//   • Resend is gated by a 60-second cooldown and a single-request-in-flight
//     guard so the user cannot hammer the SMS gateway.
//   • No fake / simulated authentication paths.

library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pinput/pinput.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/phone_mask.dart';
import '../controllers/phone_login_controller.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/user_profile_service.dart';
import '../../home/shell/main_shell.dart';
import 'phone_login_screen.dart';
import 'profile_completion_screen.dart';

// ── Screen state ──────────────────────────────────────────────────────────────

enum _OtpPhase {
  /// Waiting for Firebase to dispatch the initial SMS.
  sending,

  /// Code has been sent; user is typing the 6-digit PIN.
  awaitingCode,

  /// User submitted the PIN; Firebase is validating.
  verifying,

  /// Validation succeeded; profile is being fetched from Firestore.
  resolvingProfile,

  /// Any error state — wrong code, expired session, network, quota, etc.
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

/// Phone OTP verification screen.
///
/// Construct via [PhoneOtpScreen.fromLogin] from [PhoneLoginScreen].
class PhoneOtpScreen extends StatefulWidget {
  /// E.164 phone number.  Passed to Firebase; never displayed raw.
  final String phoneNumber;

  /// Verification ID from a prior sendOtp call.
  final String? initialVerificationId;

  /// Resend token forwarded from the prior send.
  final int? initialResendToken;

  /// Shared controller from [PhoneLoginScreen].
  /// Its [PhoneLoginController.onAuthSuccess] guard prevents double-navigation.
  final PhoneLoginController? loginController;

  /// Injectable services — default to real instances.
  final FirebasePhoneAuthService authService;
  final UserProfileService profileService;

  /// Used by [PhoneLoginScreen].  The OTP was already dispatched upstream.
  PhoneOtpScreen.fromLogin({
    super.key,
    required this.phoneNumber,
    required String verificationId,
    int? resendToken,
    required PhoneLoginController this.loginController,
    FirebasePhoneAuthService? authService,
    UserProfileService? profileService,
  }) : authService = authService ?? FirebasePhoneAuthService(),
       profileService = profileService ?? UserProfileService(),
       initialVerificationId = verificationId,
       initialResendToken = resendToken;

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneOtpScreenState extends State<PhoneOtpScreen>
    with SingleTickerProviderStateMixin {
  // ── Services ──────────────────────────────────────────────────────────────
  late final FirebasePhoneAuthService _authService;
  late final UserProfileService _profileService;

  // ── OTP session ───────────────────────────────────────────────────────────
  String? _verificationId;
  int? _resendToken;

  // ── Phase & error ─────────────────────────────────────────────────────────
  _OtpPhase _phase = _OtpPhase.sending;
  String? _errorMessage;

  // ── In-flight guard (prevents concurrent resend / verify calls) ───────────
  bool _requestInFlight = false;

  // ── PIN field ─────────────────────────────────────────────────────────────
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  // ── Resend countdown ──────────────────────────────────────────────────────
  static const _cooldownSeconds = 60;
  int _cooldownLeft = _cooldownSeconds;
  Timer? _cooldownTimer;

  // ── Pulsing icon animation ────────────────────────────────────────────────
  late final AnimationController _pulseCtrl;

  // ── Display-only masked phone ─────────────────────────────────────────────
  late final String _maskedPhone;

  // ─────────────────────────────────────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _authService = widget.authService;
    _profileService = widget.profileService;
    _maskedPhone = maskPhoneNumber(widget.phoneNumber);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    if (widget.initialVerificationId != null) {
      // Phone-login flow: OTP already dispatched — jump straight to entry.
      _verificationId = widget.initialVerificationId;
      _resendToken = widget.initialResendToken;
      _phase = _OtpPhase.awaitingCode;
      _startCooldown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pinFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pulseCtrl.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OTP send / resend
  // ─────────────────────────────────────────────────────────────────────────

  /// Dispatches (or re-dispatches) an OTP via [FirebasePhoneAuthService].
  ///
  /// [isResend] — true when triggered by the "Resend" button.
  /// Gated by [_requestInFlight] to prevent concurrent submissions.
  Future<void> _dispatchOtp({bool isResend = false}) async {
    if (_requestInFlight || !mounted) return;

    _requestInFlight = true;

    if (isResend) {
      _pinController.clear();
      _stopCooldown();
    }

    setState(() {
      _phase = _OtpPhase.sending;
      _errorMessage = null;
    });

    final result = await _authService.sendOtp(
      widget.phoneNumber,
      resendToken: _resendToken,
    );

    _requestInFlight = false;
    if (!mounted) return;

    switch (result) {
      // ── SMS dispatched ────────────────────────────────────────────────────
      case OtpSent(:final verificationId, :final resendToken):
        _verificationId = verificationId;
        _resendToken = resendToken;
        setState(() => _phase = _OtpPhase.awaitingCode);
        _startCooldown();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _pinFocusNode.requestFocus();
        });

      // ── Android auto-verified ─────────────────────────────────────────────
      case OtpAutoVerified(:final user):
        await _handleAuthSuccess(user);

      // ── Send failed ───────────────────────────────────────────────────────
      case OtpSendFailed(:final message):
        setState(() {
          _phase = _OtpPhase.error;
          _errorMessage = message;
        });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PIN completed — manual verification
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onPinCompleted(String code) async {
    if (_verificationId == null || _requestInFlight || !mounted) return;

    _requestInFlight = true;
    _pinFocusNode.unfocus();

    setState(() {
      _phase = _OtpPhase.verifying;
      _errorMessage = null;
    });

    final result = await _authService.verifyOtp(
      verificationId: _verificationId!,
      smsCode: code,
    );

    _requestInFlight = false;
    if (!mounted) return;

    switch (result) {
      case OtpVerifySuccess(:final user):
        await _handleAuthSuccess(user);

      case OtpVerifyFailure(:final message):
        _pinController.clear();
        setState(() {
          _phase = _OtpPhase.error;
          _errorMessage = message;
        });
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _pinFocusNode.requestFocus();
        });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared auth-success handler
  //
  // Called from BOTH auto-verification and manual PIN paths.
  // The PhoneLoginController guard (when present) prevents double-navigation
  // if both fire concurrently on Android.
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _handleAuthSuccess(User user) async {
    // Cross-screen double-navigation guard.
    if (widget.loginController != null) {
      if (!widget.loginController!.onAuthSuccess(user)) return;
    }
    if (!mounted) return;

    setState(() => _phase = _OtpPhase.resolvingProfile);

    // ── 1. Check Firestore ──────────────────────────────────────────────────
    ProfileResolution resolution = await _profileService.resolveProfile(user);
    if (!mounted) return;

    // ── 2. New user: write the initial document, then treat as incomplete ───
    if (resolution is ProfileMissing) {
      final writeError = await _profileService.writeProfile(user);
      if (!mounted) return;

      if (writeError != null) {
        setState(() {
          _phase = _OtpPhase.error;
          _errorMessage = writeError;
        });
        return;
      }
      // Document created — fullName is still absent, so go to completion.
      resolution = const ProfileIncomplete(['fullName']);
    }

    // ── 3. Route based on resolution ────────────────────────────────────────
    switch (resolution) {
      case ProfileComplete():
        _navigateToDashboard(user);

      case ProfileIncomplete():
        // fullName is missing (new user or incomplete prior session).
        _navigateToProfileCompletion(user);

      case ProfileMissing():
        // Unreachable — handled above, but keeps the switch exhaustive.
        _navigateToProfileCompletion(user);

      case ProfileError(:final message):
        setState(() {
          _phase = _OtpPhase.error;
          _errorMessage = message;
        });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────────────

  void _navigateToDashboard(User user) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secAnim) => MainShell(user: user),
        transitionsBuilder: (ctx, animation, secAnim, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToProfileCompletion(User user) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secAnim) => ProfileCompletionScreen(
          user: user,
          profileService: _profileService,
        ),
        transitionsBuilder: (ctx, animation, secAnim, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  /// Navigates back to [PhoneLoginScreen] so the user can change their number.
  void _changePhoneNumber() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (ctx, animation, secAnim) => const PhoneLoginScreen(),
        transitionsBuilder: (ctx, animation, secAnim, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Cooldown helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _startCooldown() {
    _stopCooldown();
    _cooldownLeft = _cooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_cooldownLeft <= 1) {
        t.cancel();
        setState(() => _cooldownLeft = 0);
      } else {
        setState(() => _cooldownLeft--);
      }
    });
  }

  void _stopCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _cooldownLeft = 0;
  }

  /// Resend is allowed only when:
  ///   - cooldown has expired
  ///   - no request is currently in-flight
  ///   - we're not in the middle of verifying or resolving
  bool get _canResend =>
      _cooldownLeft == 0 &&
      !_requestInFlight &&
      _phase != _OtpPhase.verifying &&
      _phase != _OtpPhase.resolvingProfile &&
      _phase != _OtpPhase.sending;

  // ─────────────────────────────────────────────────────────────────────────
  // Derived helpers
  // ─────────────────────────────────────────────────────────────────────────

  bool get _isBusy =>
      _phase == _OtpPhase.verifying ||
      _phase == _OtpPhase.resolvingProfile ||
      _phase == _OtpPhase.sending;

  bool get _showPinField =>
      _phase == _OtpPhase.awaitingCode ||
      _phase == _OtpPhase.verifying ||
      _phase == _OtpPhase.error;

  bool get _showResendRow =>
      _phase == _OtpPhase.awaitingCode || _phase == _OtpPhase.error;

  // ─────────────────────────────────────────────────────────────────────────
  // PIN themes
  // ─────────────────────────────────────────────────────────────────────────

  PinTheme get _baseTheme => PinTheme(
    width: 52,
    height: 60,
    textStyle: AppTextStyles.monoLarge.copyWith(
      color: AppColors.textPrimary,
      fontSize: 22,
    ),
    decoration: BoxDecoration(
      color: AppColors.bg2,
      border: Border.all(color: AppColors.outline, width: 1.5),
      borderRadius: AppSpacing.roundedMD,
    ),
  );

  PinTheme get _focusedTheme => _baseTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.bg3,
      border: Border.all(color: AppColors.primaryBright, width: 2),
      borderRadius: AppSpacing.roundedMD,
      boxShadow: [
        BoxShadow(color: AppColors.blueGlow40, blurRadius: 12, spreadRadius: 1),
      ],
    ),
  );

  PinTheme get _submittedTheme => _baseTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.bg2,
      border: Border.all(color: AppColors.primary, width: 1.5),
      borderRadius: AppSpacing.roundedMD,
    ),
  );

  PinTheme get _errorTheme => _baseTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.redGlow20,
      border: Border.all(color: AppColors.danger, width: 1.5),
      borderRadius: AppSpacing.roundedMD,
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      // Pop keyboard when tapping outside the PIN field
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // Full-screen gradient
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
              child: SizedBox.expand(),
            ),

            // Ambient top-right glow
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blueGlow10,
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.base,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.xl2),

                    // ── Pulsing phone+lock icon ───────────────────────────
                    _PulsingIcon(controller: _pulseCtrl)
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 700.ms,
                          curve: Curves.easeOutBack,
                        ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Wordmark ──────────────────────────────────────────
                    Text(
                      'VPI SECURE',
                      style: AppTextStyles.overlineLarge,
                    ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                    const SizedBox(height: AppSpacing.md),

                    // ── Screen heading ────────────────────────────────────
                    Text(
                          'Verify Your Phone',
                          style: AppTextStyles.display3,
                          textAlign: TextAlign.center,
                        )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: AppSpacing.sm),

                    // ── State-aware subtitle ──────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _subtitleWidget(),
                    ),

                    const SizedBox(height: AppSpacing.xl3),

                    // ── Main content area ─────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _mainContent(),
                    ),

                    const SizedBox(height: AppSpacing.xl2),

                    // ── Resend row ────────────────────────────────────────
                    if (_showResendRow)
                      _ResendRow(
                        cooldownLeft: _cooldownLeft,
                        canResend: _canResend,
                        onResend: () => _dispatchOtp(isResend: true),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Change number ─────────────────────────────────────
                    if (!_isBusy)
                      _ChangeNumberButton(onTap: _changePhoneNumber)
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms),

                    const SizedBox(height: AppSpacing.xl3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // State-driven sub-widgets
  // ─────────────────────────────────────────────────────────────────────────

  Widget _subtitleWidget() {
    switch (_phase) {
      case _OtpPhase.sending:
        return Text(
          'Sending a verification code…',
          key: const ValueKey('sub-sending'),
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        );

      case _OtpPhase.resolvingProfile:
        return Text(
          'Signed in — loading your profile…',
          key: const ValueKey('sub-profile'),
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        );

      case _OtpPhase.awaitingCode:
      case _OtpPhase.verifying:
      case _OtpPhase.error:
        return RichText(
          key: const ValueKey('sub-awaiting'),
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.bodyMedium,
            children: [
              const TextSpan(text: 'Enter the 6-digit code sent to\n'),
              TextSpan(
                text: _maskedPhone,
                style: AppTextStyles.monoSmall.copyWith(
                  color: AppColors.primaryBright,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _mainContent() {
    switch (_phase) {
      // ── Spinner: sending / profile resolving ─────────────────────────────
      case _OtpPhase.sending:
        return _SpinnerCard(
          key: const ValueKey('content-sending'),
          label: 'DISPATCHING OTP',
        );

      case _OtpPhase.resolvingProfile:
        return _SpinnerCard(
          key: const ValueKey('content-profile'),
          label: 'LOADING PROFILE',
        );

      // ── PIN input ─────────────────────────────────────────────────────────
      case _OtpPhase.awaitingCode:
        return _pinInputSection(
          key: const ValueKey('content-pin'),
          hasError: false,
          enabled: true,
        );

      // ── Verifying ─────────────────────────────────────────────────────────
      case _OtpPhase.verifying:
        return Column(
          key: const ValueKey('content-verifying'),
          children: [
            _pinInputSection(hasError: false, enabled: false),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryBright),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text('VERIFYING CODE…', style: AppTextStyles.overline),
              ],
            ),
          ],
        );

      // ── Error ─────────────────────────────────────────────────────────────
      case _OtpPhase.error:
        return Column(
          key: const ValueKey('content-error'),
          children: [
            _pinInputSection(hasError: true, enabled: true),
            const SizedBox(height: AppSpacing.base),
            _ErrorCard(message: _errorMessage ?? 'Verification failed.')
                .animate()
                .fadeIn(duration: 300.ms)
                .shakeX(hz: 3, amount: 4),
          ],
        );
    }
  }

  /// Builds the full PIN-input section: accessible label + Pinput + button.
  Widget _pinInputSection({
    Key? key,
    required bool hasError,
    required bool enabled,
  }) {
    final bool hasPin = _pinController.text.length == 6;

    return Column(
      key: key,
      children: [
        // Accessibility label (screen-reader / keyboard nav)
        Semantics(
          label: 'Enter 6-digit verification code',
          child: Pinput(
            length: 6,
            controller: _pinController,
            focusNode: _pinFocusNode,
            enabled: enabled,

            // Numeric phone keyboard with autofill / one-time-code hints
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],

            // Paste and autofill support
            enableSuggestions: true,
            obscureText: false,

            autofocus: false,
            hapticFeedbackType: HapticFeedbackType.lightImpact,

            defaultPinTheme: hasError ? _errorTheme : _baseTheme,
            focusedPinTheme: hasError ? _errorTheme : _focusedTheme,
            submittedPinTheme: hasError ? _errorTheme : _submittedTheme,

            onCompleted: enabled ? _onPinCompleted : null,

            onChanged: (val) {
              // Clear error as soon as the user starts re-typing.
              if (_phase == _OtpPhase.error && mounted) {
                setState(() {
                  _phase = _OtpPhase.awaitingCode;
                  _errorMessage = null;
                });
              }
            },
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Verify and Continue button ────────────────────────────────────
        _VerifyButton(
          isEnabled: enabled && hasPin,
          isLoading: _phase == _OtpPhase.verifying,
          onPressed: () {
            if (_pinController.text.length == 6) {
              _onPinCompleted(_pinController.text);
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PulsingIcon
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingIcon extends StatelessWidget {
  final AnimationController controller;
  const _PulsingIcon({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final glow = 0.4 + 0.6 * controller.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer breathing ring
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueGlow10.withValues(alpha: glow * 0.15),
              ),
            ),
            // Inner ring
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.blueGlow40.withValues(alpha: glow * 0.5),
                    AppColors.bg2,
                  ],
                ),
                border: Border.all(
                  color: AppColors.primaryBright.withValues(alpha: glow * 0.8),
                  width: 1.5,
                ),
              ),
            ),
            // Phone + lock badge
            Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.smartphone_rounded,
                  color: AppColors.primaryBright.withValues(alpha: 0.85),
                  size: 36,
                ),
                Positioned(
                  bottom: 4,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.bg0,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBright,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: AppColors.primaryBright,
                      size: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpinnerCard
// ─────────────────────────────────────────────────────────────────────────────

class _SpinnerCard extends StatelessWidget {
  final String label;
  const _SpinnerCard({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppColors.primaryBright),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(label, style: AppTextStyles.overline),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VerifyButton
// ─────────────────────────────────────────────────────────────────────────────

class _VerifyButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _VerifyButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: 'Verify and continue',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        height: AppSpacing.buttonHeightLG,
        width: double.infinity,
        decoration: isEnabled
            ? AppDecorations.buttonPrimary
            : BoxDecoration(
                color: AppColors.bg3,
                borderRadius: AppSpacing.roundedMD,
                border: Border.all(color: AppColors.outline, width: 1),
              ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isEnabled && !isLoading) ? onPressed : null,
            borderRadius: AppSpacing.roundedMD,
            splashColor: AppColors.blueGlow20,
            highlightColor: Colors.transparent,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: isEnabled
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'VERIFY AND CONTINUE',
                          style: AppTextStyles.buttonLarge.copyWith(
                            color: isEnabled
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ResendRow
// ─────────────────────────────────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  final int cooldownLeft;
  final bool canResend;
  final VoidCallback onResend;

  const _ResendRow({
    required this.cooldownLeft,
    required this.canResend,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't receive the code?  ", style: AppTextStyles.bodySmall),
        if (canResend)
          Semantics(
            button: true,
            label: 'Resend verification code',
            child: GestureDetector(
              onTap: onResend,
              child: Text('Resend', style: AppTextStyles.linkButton),
            ),
          )
        else
          Text(
            cooldownLeft > 0 ? 'Resend in ${cooldownLeft}s' : 'Resend',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBright,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChangeNumberButton
// ─────────────────────────────────────────────────────────────────────────────

class _ChangeNumberButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ChangeNumberButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change phone number',
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit_rounded,
              size: AppSpacing.iconSM,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Change phone number',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorCard
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.redGlow20,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.5),
          width: 1,
        ),
        borderRadius: AppSpacing.roundedMD,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.danger,
            size: AppSpacing.iconMD,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
