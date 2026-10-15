import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingPageWrapper
//
// Wraps each onboarding page. Owns a single entrance animation that runs once
// when [isActive] first becomes true, then stays settled.
//
// Text stagger:
//   overline  → leads
//   heading   → 60 ms later
//   body      → 140 ms later
//
// Reduced-motion (MediaQuery.disableAnimations): skips animation and shows
// all text immediately at full opacity.
//
// Re-entrance: when [isActive] flips false→true (swipe-back), the animation
// replays cleanly from zero.
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingPageWrapper extends StatefulWidget {
  final String sectionLabel;
  final String title;
  final String subtitle;
  final Widget illustration;
  final List<Widget>? infoCards;

  /// True when this is the visible/active page. Drives the entrance animation.
  final bool isActive;

  const OnboardingPageWrapper({
    super.key,
    required this.sectionLabel,
    required this.title,
    required this.subtitle,
    required this.illustration,
    this.infoCards,
    this.isActive = true,
  });

  @override
  State<OnboardingPageWrapper> createState() => _OnboardingPageWrapperState();
}

class _OnboardingPageWrapperState extends State<OnboardingPageWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;

  late final Animation<double> _overlineFade;
  late final Animation<Offset> _overlineSlide;
  late final Animation<double> _headingFade;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;

  static const _duration = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: _duration);

    _overlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOut),
      ),
    );
    _overlineSlide =
        Tween<Offset>(begin: const Offset(0, -0.30), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.00, 0.55, curve: Curves.easeOutCubic),
          ),
        );

    _headingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.12, 0.70, curve: Curves.easeOut),
      ),
    );
    _headingSlide =
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.12, 0.70, curve: Curves.easeOutCubic),
          ),
        );

    _bodyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.28, 1.00, curve: Curves.easeOut),
      ),
    );
    _bodySlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceCtrl,
            curve: const Interval(0.28, 1.00, curve: Curves.easeOutCubic),
          ),
        );

    if (widget.isActive) _playEntrance();
  }

  @override
  void didUpdateWidget(OnboardingPageWrapper old) {
    super.didUpdateWidget(old);
    if (!old.isActive && widget.isActive) _playEntrance();
    if (old.isActive && !widget.isActive) _entranceCtrl.reset();
  }

  void _playEntrance() {
    // Use MediaQuery at call-site context: both _playEntrance calls happen
    // from initState / didUpdateWidget where we have no BuildContext, so we
    // rely on WidgetsBinding here.  Build() uses MediaQuery for rendering.
    final skip =
        WidgetsBinding.instance.accessibilityFeatures.disableAnimations;
    if (skip) {
      _entranceCtrl.value = 1.0;
    } else {
      _entranceCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // MediaQuery.disableAnimations is the Flutter-propagated reduced-motion
    // flag. Used here for the render path; _playEntrance uses WidgetsBinding
    // for the controller path (no BuildContext available there).
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: size.height,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 16),

            // Section overline
            _Entrance(
              fade: _overlineFade,
              slide: _overlineSlide,
              reduced: reduceMotion,
              child: Text(
                widget.sectionLabel,
                style: AppTextStyles.overlineLarge,
              ),
            ),

            const SizedBox(height: 8),

            // Illustration — parallax/opacity handled by the screen layer
            SizedBox(height: size.height * 0.40, child: widget.illustration),

            const SizedBox(height: 12),

            // Heading
            if (widget.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _Entrance(
                  fade: _headingFade,
                  slide: _headingSlide,
                  reduced: reduceMotion,
                  child: Text(
                    widget.title,
                    style: AppTextStyles.pageTitle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Body
            if (widget.subtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _Entrance(
                  fade: _bodyFade,
                  slide: _bodySlide,
                  reduced: reduceMotion,
                  child: Text(
                    widget.subtitle,
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

            if (widget.infoCards != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(children: widget.infoCards!),
              ),
            ],

            const Spacer(),

            SizedBox(height: MediaQuery.paddingOf(context).bottom + 100),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Entrance — FadeTransition + SlideTransition driven by animations.
// These are AnimatedWidget subclasses: they listen directly to their
// animations and do NOT require setState, keeping rebuilds minimal.
// When [reduced] is true the child is rendered at full opacity immediately.
// ─────────────────────────────────────────────────────────────────────────────
class _Entrance extends StatelessWidget {
  final Animation<double> fade;
  final Animation<Offset> slide;
  final bool reduced;
  final Widget child;

  const _Entrance({
    required this.fade,
    required this.slide,
    required this.reduced,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (reduced) return child;
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// InfoRow — reusable info card row
// ─────────────────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppColors.bg2.withOpacity(0.7),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySmall),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: iconColor.withOpacity(0.7),
            size: 18,
          ),
        ],
      ),
    );
  }
}
