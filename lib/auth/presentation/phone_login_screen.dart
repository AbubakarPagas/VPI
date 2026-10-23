/// Phone-number login screen.
///
/// Entry point for the phone-OTP sign-in flow. The user selects their country,
/// types their number, and taps Continue. On [codeSent] the app navigates to
/// [PhoneOtpScreen]; on Android [verificationCompleted] it resolves the
/// Firestore profile and routes accordingly — identical to the path taken by
/// [PhoneOtpScreen._handleAuthSuccess].

library;

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_decorations.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../controllers/phone_login_controller.dart';
import '../services/firebase_phone_auth_service.dart';
import '../services/user_profile_service.dart';
import '../../home/shell/main_shell.dart';
import 'phone_otp_screen.dart';
import 'profile_completion_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class PhoneLoginScreen extends StatefulWidget {
  final FirebasePhoneAuthService? service;
  final UserProfileService? profileService;

  const PhoneLoginScreen({super.key, this.service, this.profileService});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen>
    with SingleTickerProviderStateMixin {
  late final PhoneLoginController _ctrl;
  late final UserProfileService _profileService;
  late final AnimationController _shieldCtrl;
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();

  bool _resolvingProfile = false;

  @override
  void initState() {
    super.initState();
    _ctrl = PhoneLoginController(service: widget.service);
    _ctrl.addListener(_onControllerUpdate);
    _profileService = widget.profileService ?? UserProfileService();

    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onControllerUpdate)
      ..dispose();
    _shieldCtrl.dispose();
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  // ── Continue ──────────────────────────────────────────────────────────────

  Future<void> _onContinue() async {
    if (!_ctrl.canSubmit) return;
    _phoneFocus.unfocus();

    final result = await _ctrl.sendOtp();
    if (!mounted) return;

    switch (result) {
      case OtpSent(:final verificationId, :final resendToken):
        _navigateToOtp(
          verificationId: verificationId,
          resendToken: resendToken,
        );

      case OtpAutoVerified(:final user):
        if (_ctrl.onAuthSuccess(user)) {
          await _resolveAndRoute(user);
        }

      case OtpSendFailed():
        break;
    }
  }

  // ── Profile resolution ────────────────────────────────────────────────────

  Future<void> _resolveAndRoute(User user) async {
    if (!mounted) return;
    setState(() => _resolvingProfile = true);

    ProfileResolution resolution = await _profileService.resolveProfile(user);
    if (!mounted) return;

    if (resolution is ProfileMissing) {
      final error = await _profileService.initProfile(user);
      if (!mounted) return;
      if (error != null) {
        setState(() => _resolvingProfile = false);
        _showProfileError(error);
        return;
      }
      resolution = const ProfileIncomplete(['fullName']);
    }

    switch (resolution) {
      case ProfileComplete():
        _navigateToDashboard(user);
      case ProfileIncomplete():
      case ProfileMissing():
        _navigateToProfileCompletion(user);
      case ProfileError(:final message):
        setState(() => _resolvingProfile = false);
        _showProfileError(message);
    }
  }

  void _showProfileError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _navigateToOtp({required String verificationId, int? resendToken}) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, _) => PhoneOtpScreen.fromLogin(
          phoneNumber: _ctrl.e164,
          verificationId: verificationId,
          resendToken: resendToken,
          loginController: _ctrl,
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _navigateToDashboard(User user) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, _) => MainShell(user: user),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (_) => false,
    );
  }

  void _navigateToProfileCompletion(User user) {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, a, _) => ProfileCompletionScreen(
          user: user,
          profileService: _profileService,
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _ctrl.loginState == PhoneLoginState.sending || _resolvingProfile;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      // Scaffold lifts content above the keyboard automatically.
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen gradient
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SizedBox.expand(),
          ),

          // Decorative glow orb (positioned, does not affect layout)
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blueGlow10,
                ),
              ),
            ),
          ),

          // Scrollable content
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  // Horizontal padding scales between 20 px (narrow) and 32 px
                  final hPad = (w * 0.07).clamp(20.0, 32.0);

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: AppSpacing.base,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl2),

                        // Shield animation — centred
                        Center(
                          child: _AnimatedShield(controller: _shieldCtrl)
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.7, 0.7),
                                duration: 700.ms,
                                curve: Curves.easeOutBack,
                              ),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        Center(
                          child: Text(
                            'VPI SECURE',
                            style: AppTextStyles.overlineLarge,
                          ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        Center(
                          child:
                              Text(
                                    'Welcome to VPI Secure',
                                    style: AppTextStyles.display3,
                                    textAlign: TextAlign.center,
                                  )
                                  .animate(delay: 200.ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.15, end: 0),
                        ),

                        const SizedBox(height: AppSpacing.sm),

                        Center(
                          child: Text(
                            'Enter your phone number to sign in\nor create an account.',
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                        ),

                        const SizedBox(height: AppSpacing.xl3),

                        // Phone input — stretches full available width
                        _PhoneInputCard(
                              country: _ctrl.country,
                              phoneController: _phoneCtrl,
                              focusNode: _phoneFocus,
                              enabled: !isBusy,
                              maxDigits: _ctrl.country.maxDigits,
                              onCountryTap: () => _showCountryPicker(context),
                              onChanged: _ctrl.onPhoneChanged,
                            )
                            .animate(delay: 400.ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0),

                        // Error banner
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: _ctrl.errorMessage != null
                              ? Padding(
                                      padding: const EdgeInsets.only(
                                        top: AppSpacing.md,
                                      ),
                                      child: _ErrorBanner(
                                        message: _ctrl.errorMessage!,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 300.ms)
                                    .shakeX(hz: 4, amount: 4)
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: AppSpacing.xl),

                        // Continue button — SizedBox gives it a proper
                        // bounded width so InkWell/DecoratedBox work correctly
                        SizedBox(
                          width: double.infinity,
                          child:
                              _ContinueButton(
                                    isEnabled: _ctrl.canSubmit,
                                    isLoading: isBusy,
                                    onPressed: _onContinue,
                                  )
                                  .animate(delay: 500.ms)
                                  .fadeIn(duration: 400.ms)
                                  .slideY(begin: 0.1, end: 0),
                        ),

                        const SizedBox(height: AppSpacing.xl3),

                        Center(
                          child: _TermsFooter()
                              .animate(delay: 600.ms)
                              .fadeIn(duration: 400.ms),
                        ),

                        const SizedBox(height: AppSpacing.xl2),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context) {
    _phoneFocus.unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      // Let the sheet size itself to its content, but cap at 80 % screen height
      // so it never clips on short devices.
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        builder: (_, scrollCtrl) => _CountryPickerSheet(
          selected: _ctrl.country,
          countries: kSupportedCountries,
          scrollController: scrollCtrl,
          onSelect: (entry) {
            _ctrl.selectCountry(entry);
            _phoneCtrl.clear();
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated shield header
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedShield extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedShield({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          // Breathing outer glow
          Container(
            width: 90 + 10 * controller.value,
            height: 90 + 10 * controller.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.blueGlow20.withValues(
                alpha: 0.3 + 0.2 * controller.value,
              ),
            ),
          ),
          // Slowly rotating dashed ring
          Transform.rotate(
            angle: controller.value * 2 * math.pi * 0.5,
            child: CustomPaint(
              size: const Size(86, 86),
              painter: _DashedRingPainter(),
            ),
          ),
          // Blue shield circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.blueGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blueGlow40,
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.textPrimary,
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const dashCount = 18;
    const dashAngle = 2 * math.pi / dashCount;

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * dashAngle,
        dashAngle * 0.55,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Phone input card
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneInputCard extends StatefulWidget {
  final CountryEntry country;
  final TextEditingController phoneController;
  final FocusNode focusNode;
  final bool enabled;
  final int maxDigits;
  final VoidCallback onCountryTap;
  final ValueChanged<String> onChanged;

  const _PhoneInputCard({
    required this.country,
    required this.phoneController,
    required this.focusNode,
    required this.enabled,
    required this.maxDigits,
    required this.onCountryTap,
    required this.onChanged,
  });

  @override
  State<_PhoneInputCard> createState() => _PhoneInputCardState();
}

class _PhoneInputCardState extends State<_PhoneInputCard> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: _focused ? AppColors.primary : AppColors.outline,
          width: _focused ? 1.5 : 1.0,
        ),
        boxShadow: _focused ? AppDecorations.glowBlueSoft : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Country selector — intrinsic width
            _CountrySelectorButton(
              country: widget.country,
              onTap: widget.enabled ? widget.onCountryTap : null,
            ),
            // Divider
            Container(
              width: 1,
              color: _focused ? AppColors.outlineLight : AppColors.divider,
            ),
            // Phone field — fills remaining width
            Expanded(
              child: _PhoneInputField(
                controller: widget.phoneController,
                focusNode: widget.focusNode,
                enabled: widget.enabled,
                maxDigits: widget.maxDigits,
                onChanged: widget.onChanged,
                dialCode: widget.country.dialCode,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountrySelectorButton
// ─────────────────────────────────────────────────────────────────────────────

class _CountrySelectorButton extends StatelessWidget {
  final CountryEntry country;
  final VoidCallback? onTap;

  const _CountrySelectorButton({required this.country, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              country.dialCode,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.primaryBright,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: onTap != null
                  ? AppColors.textMuted
                  : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PhoneInputField
// ─────────────────────────────────────────────────────────────────────────────

class _PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final int maxDigits;
  final ValueChanged<String> onChanged;
  final String dialCode;

  const _PhoneInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.maxDigits,
    required this.onChanged,
    required this.dialCode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxDigits + 1),
      ],
      style: AppTextStyles.bodyStrong.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        letterSpacing: 1.2,
      ),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Phone number',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Continue button
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.isEnabled,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // DecoratedBox + Material + InkWell avoids the AnimatedContainer
    // ParentDataWidget conflict. Height is fixed; width comes from the
    // parent SizedBox(width: double.infinity).
    return DecoratedBox(
      decoration: isEnabled
          ? AppDecorations.buttonPrimary
          : BoxDecoration(
              color: AppColors.bg3,
              borderRadius: AppSpacing.roundedMD,
              border: Border.all(color: AppColors.outline, width: 1),
            ),
      child: SizedBox(
        height: AppSpacing.buttonHeightLG,
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
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: isEnabled
                              ? AppColors.textPrimary
                              : AppColors.textDisabled,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'CONTINUE',
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
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppSpacing.roundedMD,
        color: AppColors.redGlow20,
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 18,
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Terms footer
// ─────────────────────────────────────────────────────────────────────────────

class _TermsFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('By continuing you agree to our ', style: AppTextStyles.caption),
        GestureDetector(
          onTap: () {
            // TODO: open Terms of Service URL
          },
          child: Text(
            'Terms of Service',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBright,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryBright,
            ),
          ),
        ),
        Text(' and ', style: AppTextStyles.caption),
        GestureDetector(
          onTap: () {
            // TODO: open Privacy Policy URL
          },
          child: Text(
            'Privacy Policy',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primaryBright,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryBright,
            ),
          ),
        ),
        Text('.', style: AppTextStyles.caption),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country picker bottom sheet
//
// Uses DraggableScrollableSheet so it never overflows on short screens and the
// user can swipe it taller if needed.
// ─────────────────────────────────────────────────────────────────────────────

class _CountryPickerSheet extends StatelessWidget {
  final CountryEntry selected;
  final List<CountryEntry> countries;
  final ValueChanged<CountryEntry> onSelect;
  final ScrollController scrollController;

  const _CountryPickerSheet({
    required this.selected,
    required this.countries,
    required this.onSelect,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXL),
          ),
          border: const Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: AppSpacing.pill,
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              child: Text('SELECT COUNTRY', style: AppTextStyles.overline),
            ),
            const Divider(color: AppColors.divider, height: 1),
            // Country list — scrollable, fills remaining sheet space
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: countries.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AppColors.divider, height: 1),
                itemBuilder: (_, index) {
                  final entry = countries[index];
                  final isSelected = entry.dialCode == selected.dialCode;
                  return InkWell(
                    onTap: () => onSelect(entry),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.base,
                      ),
                      child: Row(
                        children: [
                          Text(
                            entry.flag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              entry.name,
                              style: AppTextStyles.bodyStrong.copyWith(
                                color: isSelected
                                    ? AppColors.primaryBright
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            entry.dialCode,
                            style: AppTextStyles.mono.copyWith(
                              color: isSelected
                                  ? AppColors.primaryBright
                                  : AppColors.textMuted,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.primaryBright,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom safe-area padding
            SizedBox(
              height: MediaQuery.paddingOf(context).bottom + AppSpacing.base,
            ),
          ],
        ),
      ),
    );
  }
}
