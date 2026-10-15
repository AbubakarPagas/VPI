import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Bottom navigation controls for the onboarding flow.
///
/// Layout (bottom to top):
///   • Skip text button — always occupies its slot, fades on last page
///   • Row: [Back button] [Next / Get Started button]
///   • SmoothPageIndicator
///
/// [isTransitioning] disables all button actions while a programmatic page
/// animation is in progress, preventing double-tap queuing.
class OnboardingControls extends StatelessWidget {
  final PageController controller;
  final int currentPage;
  final int pageCount;
  final bool isTransitioning;
  final VoidCallback onSkip;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const OnboardingControls({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.pageCount,
    required this.isTransitioning,
    required this.onSkip,
    required this.onBack,
    required this.onNext,
    required this.onGetStarted,
  });

  bool get _isFirst => currentPage == 0;
  bool get _isLast => currentPage == pageCount - 1;

  @override
  Widget build(BuildContext context) {
    // Clamp the scale so Skip height never clips on large text.
    final textScale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 1.5);
    final skipHeight = (36.0 * textScale).ceilToDouble();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Page indicator ──────────────────────────────────────────
            // ExpandingDotsEffect animates the active dot into a wider pill.
            SmoothPageIndicator(
              controller: controller,
              count: pageCount,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.bg3,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 3.5,
                spacing: 6,
                strokeWidth: 0,
              ),
            ),

            const SizedBox(height: 24),

            // ── Back + Next/Get Started ─────────────────────────────────
            Row(
              children: [
                // Back — invisible on first page; IgnorePointer prevents
                // accidental taps landing on an invisible hit target.
                _isFirst
                    ? Container()
                    : IgnorePointer(
                        ignoring: _isFirst,
                        child: AnimatedOpacity(
                          opacity: _isFirst ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: _BackButton(
                            onPressed: (_isFirst || isTransitioning)
                                ? null
                                : onBack,
                          ),
                        ),
                      ),

                const SizedBox(width: 12),

                // Next / Get Started — animates between the two states.
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _isLast
                        ? _PrimaryButton(
                            key: const ValueKey('get_started'),
                            label: 'Get Started',
                            icon: Icons.rocket_launch_rounded,
                            isLast: true,
                            enabled: !isTransitioning,
                            onPressed: onGetStarted,
                          )
                        : _PrimaryButton(
                            key: const ValueKey('next'),
                            label: 'Next',
                            icon: Icons.arrow_forward_rounded,
                            isLast: false,
                            enabled: !isTransitioning,
                            onPressed: onNext,
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Skip ────────────────────────────────────────────────────
            // Fixed height slot sized for the current text scale so the
            // controls never shift between pages. IgnorePointer on last
            // page prevents invisible taps.
            IgnorePointer(
              ignoring: _isLast,
              child: AnimatedOpacity(
                opacity: _isLast ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 250),
                child: SizedBox(
                  height: skipHeight,
                  child: Semantics(
                    button: true,
                    label: 'Skip onboarding',
                    child: TextButton(
                      onPressed: (_isLast || isTransitioning) ? null : onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        minimumSize: const Size(88, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
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
// Back button — outlined square icon button with press-scale feedback
// ─────────────────────────────────────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const _BackButton({this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    if (widget.onPressed != null) {
      HapticFeedback.lightImpact();
      widget.onPressed!();
    }
  }

  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Go back',
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: SizedBox(
            width: 52,
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.onPressed != null
                    ? AppColors.bg2
                    : AppColors.bg2.withOpacity(0.4),
                border: Border.all(
                  color: widget.onPressed != null
                      ? AppColors.outline
                      : AppColors.outline.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: widget.onPressed != null
                      ? AppColors.primaryBright
                      : AppColors.primaryBright.withOpacity(0.3),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Primary action button — Next or Get Started, with press-scale feedback
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isLast;
  final bool enabled;
  final VoidCallback onPressed;

  const _PrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLast,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _pressCtrl.reverse();
    if (widget.enabled) {
      HapticFeedback.lightImpact();
      widget.onPressed();
    }
  }

  void _onTapCancel() => _pressCtrl.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: SizedBox(
            height: 56,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isLast
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF00897B), AppColors.trusted],
                      )
                    : AppColors.blueGradient,
                boxShadow: [
                  BoxShadow(
                    color: widget.isLast
                        ? AppColors.trustedGlow
                        : AppColors.blueGlow40,
                    blurRadius: widget.enabled ? 20 : 6,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Opacity(
                opacity: widget.enabled ? 1.0 : 0.55,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: widget.isLast
                              ? AppColors.bg0
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        widget.icon,
                        color: widget.isLast
                            ? AppColors.bg0
                            : AppColors.textPrimary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
