import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../auth/presentation/phone_login_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../models/onboarding_page_data.dart';
import '../widgets/animated_background.dart';
import '../widgets/onboarding_controls.dart';
import '../widgets/onboarding_page_wrapper.dart';

/// Three-page VPI Secure onboarding: VERIFY → PROTECT → IDENTIFY.
///
/// [onCompleted] is called when the user taps Skip or Get Started.
/// If null, navigates to [PhoneLoginScreen] (the default app flow).
class OnboardingScreen extends StatefulWidget {
  /// Optional callback invoked when onboarding is dismissed.
  /// When null, the screen pushes [PhoneLoginScreen] as replacement.
  final VoidCallback? onCompleted;

  const OnboardingScreen({super.key, this.onCompleted});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pageController = PageController();

  /// Integer index of the currently settled page.
  int _currentPage = 0;

  /// Fractional page position (e.g. 1.65 while swiping page 1 → 2).
  double _pageOffset = 0.0;

  /// True while a programmatic transition is running. Prevents repeated taps
  /// from queuing up multiple animations.
  bool _isTransitioning = false;

  // ── Glow colour animation ─────────────────────────────────────────────────
  // _glowCtrl drives a single AnimatedBuilder that wraps the entire body so
  // the glow circle AND the controls both update in sync each frame —
  // with no unnecessary rebuilds of the wider widget tree.
  late final AnimationController _glowCtrl;
  late Animation<Color?> _glowAnim;

  static const _navDuration = Duration(milliseconds: 420);
  static const _navCurve = Curves.easeInOutCubic;

  static const _parallaxShift = 18.0;
  static const _neighborOpacityMin = 0.35;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: _navDuration);
    _glowAnim = AlwaysStoppedAnimation<Color?>(kOnboardingPages[0].glowColor);
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Scroll listener ───────────────────────────────────────────────────────

  void _onPageScroll() {
    if (!mounted) return;
    final offset = _pageController.page ?? _currentPage.toDouble();
    if (offset == _pageOffset) return; // equality guard — no spurious rebuilds
    setState(() => _pageOffset = offset);
  }

  // ── Completion ────────────────────────────────────────────────────────────

  void _complete() {
    /*  if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }
    if (!mounted) return; */
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const PhoneLoginScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ── Page navigation ───────────────────────────────────────────────────────

  Future<void> _goToPage(int index) async {
    if (_isTransitioning) return;
    if (index < 0 || index >= kOnboardingPages.length) return;

    setState(() => _isTransitioning = true);

    final fromColor =
        _glowAnim.value ?? kOnboardingPages[_currentPage].glowColor;
    final toColor = kOnboardingPages[index].glowColor;
    _glowAnim = ColorTween(
      begin: fromColor,
      end: toColor,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
    _glowCtrl.forward(from: 0.0);

    // try/finally guarantees _isTransitioning is always cleared — even if
    // animateToPage throws because the PageController was disposed mid-flight
    // (e.g. the user triggers Skip while a scroll is in progress).
    try {
      await _pageController.animateToPage(
        index,
        duration: _navDuration,
        curve: _navCurve,
      );
    } finally {
      if (mounted) {
        setState(() {
          _currentPage = index;
          _isTransitioning = false;
        });
      }
    }
  }

  void _onNext() {
    if (_currentPage < kOnboardingPages.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _complete();
    }
  }

  void _onBack() {
    if (_currentPage > 0) _goToPage(_currentPage - 1);
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _isTransitioning = false;
    });
  }

  // ── Per-page helpers ──────────────────────────────────────────────────────

  double _delta(int pageIndex) => _pageOffset - pageIndex;

  double _pageOpacity(double delta) {
    final t = delta.abs().clamp(0.0, 1.0);
    return lerpDouble(_neighborOpacityMin, 1.0, 1.0 - t)!;
  }

  double _illustrationParallax(double delta) => -delta * _parallaxShift;

  Color _glowColor() {
    // Programmatic transition: use the animated tween value.
    if (_isTransitioning) {
      return _glowAnim.value ?? kOnboardingPages[_currentPage].glowColor;
    }
    // Manual swipe: interpolate between adjacent page colours.
    final lo = _pageOffset.floor().clamp(0, kOnboardingPages.length - 1);
    final hi = _pageOffset.ceil().clamp(0, kOnboardingPages.length - 1);
    if (lo == hi) return kOnboardingPages[lo].glowColor;
    final t = _pageOffset - lo;
    return Color.lerp(
          kOnboardingPages[lo].glowColor,
          kOnboardingPages[hi].glowColor,
          t,
        ) ??
        kOnboardingPages[lo].glowColor;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: AnimatedBackground(
        // AnimatedBuilder wraps the whole body so the glow circle and the
        // controls both update each _glowCtrl tick without rebuilding
        // everything outside this subtree.
        child: AnimatedBuilder(
          animation: _glowCtrl,
          builder: (context, _) {
            final glow = _glowColor();
            return Stack(
              children: [
                // ── Ambient glow circle behind illustration area ──────────
                Positioned(
                  top: -80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: glow.withOpacity(0.06),
                        boxShadow: [
                          BoxShadow(
                            color: glow.withOpacity(0.10),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── PageView with parallax + neighbour opacity ────────────
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  itemCount: kOnboardingPages.length,
                  itemBuilder: (context, index) {
                    final p = kOnboardingPages[index];
                    final delta = _delta(index);
                    return Opacity(
                      opacity: _pageOpacity(delta),
                      child: Transform.translate(
                        offset: Offset(_illustrationParallax(delta), 0),
                        transformHitTests: false,
                        child: OnboardingPageWrapper(
                          key: ValueKey(index),
                          sectionLabel: p.sectionLabel,
                          title: p.title,
                          subtitle: p.description,
                          illustration: p.illustration,
                          isActive: _currentPage == index,
                        ),
                      ),
                    );
                  },
                ),

                // ── Bottom controls ───────────────────────────────────────
                Align(
                  alignment: Alignment.bottomCenter,
                  child: OnboardingControls(
                    controller: _pageController,
                    currentPage: _currentPage,
                    pageCount: kOnboardingPages.length,
                    isTransitioning: _isTransitioning,
                    onSkip: _complete,
                    onBack: _onBack,
                    onNext: _onNext,
                    onGetStarted: _complete,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
