import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper — pauses all controllers when the app goes to background
// and resumes when it returns to the foreground.
//
// Uses a thin _LifecycleObserver instead of implementing the full
// WidgetsBindingObserver interface, avoiding deprecated-stub warnings.
//
// On resume, only controllers that were originally repeating are restarted
// with repeat(). One-shot controllers (forward() only, like entrance
// animations) are left alone — they stay at their completed value.
// ─────────────────────────────────────────────────────────────────────────────
mixin _LifecycleMixin<T extends StatefulWidget> on State<T> {
  /// All controllers managed by this illustration. Disposed automatically.
  List<AnimationController> get _controllers;

  /// Subset of [_controllers] that should be resumed with repeat() when the
  /// app returns to foreground. One-shot controllers (entrance animations)
  /// must NOT be included here.
  List<AnimationController> get _repeatableControllers => _controllers;

  final _LifecycleObserver _observer = _LifecycleObserver();

  @override
  void initState() {
    super.initState();
    _observer._onStateChange = _onLifecycle;
    WidgetsBinding.instance.addObserver(_observer);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observer);
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onLifecycle(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      for (final c in _controllers) {
        c.stop();
      }
    } else if (state == AppLifecycleState.resumed) {
      // Only restart controllers that were meant to loop.
      // One-shot entrance animations stay completed.
      for (final c in _repeatableControllers) {
        if (!c.isAnimating) c.repeat();
      }
    }
  }
}

/// Minimal WidgetsBindingObserver that forwards only lifecycle events.
class _LifecycleObserver extends WidgetsBindingObserver {
  void Function(AppLifecycleState)? _onStateChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onStateChange?.call(state);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 1 — VERIFY  "Check Before You Trust"
//
// • Smartphone outline with floating motion
// • Blue scanning line moving vertically inside the phone
// • Shield appearing with scale-and-fade entrance
// • Green checkmark drawn after scan completes
// • Softly glowing data points around the phone
// ─────────────────────────────────────────────────────────────────────────────
class FingerprintIllustration extends StatefulWidget {
  const FingerprintIllustration({super.key});

  @override
  State<FingerprintIllustration> createState() =>
      _FingerprintIllustrationState();
}

class _FingerprintIllustrationState extends State<FingerprintIllustration>
    with TickerProviderStateMixin, _LifecycleMixin {
  // Float bob
  late final AnimationController _floatCtrl;
  // Scan cycle: line travels top→bottom, checkmark appears, resets
  late final AnimationController _scanCtrl;
  // Shield entrance (plays once on mount)
  late final AnimationController _shieldCtrl;
  // Ambient data-point orbit
  late final AnimationController _dotCtrl;

  late final Animation<double> _floatY;
  late final Animation<double> _scanPos; // 0 = top, 1 = bottom
  late final Animation<double> _checkOpacity; // fades in after scan
  late final Animation<double> _shieldScale;
  late final Animation<double> _shieldOpacity;

  // 1 s scan + 0.8 s hold + 0.4 s reset = 2.2 s cycle
  static const _scanDuration = Duration(milliseconds: 2200);

  // All four controllers — disposed by the mixin.
  @override
  List<AnimationController> get _controllers => [
    _floatCtrl,
    _scanCtrl,
    _shieldCtrl,
    _dotCtrl,
  ];

  // _shieldCtrl is a one-shot entrance animation; do not repeat() it on resume.
  @override
  List<AnimationController> get _repeatableControllers => [
    _floatCtrl,
    _scanCtrl,
    _dotCtrl,
  ];

  @override
  void initState() {
    super.initState();

    // ── Float ──────────────────────────────────────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatY = Tween<double>(
      begin: -7.0,
      end: 7.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    // ── Scan cycle ─────────────────────────────────────────────────────────
    _scanCtrl = AnimationController(vsync: this, duration: _scanDuration)
      ..repeat();

    // scanPos: 0→1 over first 45 % of the cycle, then holds at 1
    _scanPos = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
    ]).animate(_scanCtrl);

    // checkOpacity fades in between 48 %–65 % of the cycle, fades out 90 %–100 %
    _checkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 17,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
    ]).animate(_scanCtrl);

    // ── Shield entrance ────────────────────────────────────────────────────
    _shieldCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _shieldScale = Tween<double>(
      begin: 0.55,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shieldCtrl, curve: Curves.easeOutBack));
    _shieldOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shieldCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // ── Data-point orbit ───────────────────────────────────────────────────
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Semantics: one descriptive label for the whole illustration.
    // ExcludeSemantics wraps the visual subtree so screen readers never
    // traverse individual decorative particles or painters.
    return Semantics(
      label: 'Illustration: smartphone being scanned and verified',
      excludeSemantics: true,
      child: reduceMotion
          ? _buildStatic()
          : RepaintBoundary(child: _buildAnimated()),
    );
  }

  // ── Static fallback ───────────────────────────────────────────────────────
  Widget _buildStatic() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(180, 180),
              painter: _ShieldPainter(
                fillColor: AppColors.bg2,
                strokeColor: AppColors.primary,
                glowColor: AppColors.blueGlow40,
              ),
            ),
            _VerifyPhoneWidget(scanProgress: 1.0, showCheck: true),
            _DataPointsPainter.widget(progress: 0.3),
          ],
        ),
      ),
    );
  }

  // ── Animated scene ────────────────────────────────────────────────────────
  Widget _buildAnimated() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Shield (entrance + static after)
            AnimatedBuilder(
              animation: _shieldCtrl,
              builder: (_, __) => Opacity(
                opacity: _shieldOpacity.value,
                child: Transform.scale(
                  scale: _shieldScale.value,
                  child: CustomPaint(
                    size: const Size(178, 178),
                    painter: _ShieldPainter(
                      fillColor: AppColors.bg2,
                      strokeColor: AppColors.primary,
                      glowColor: AppColors.blueGlow40,
                    ),
                  ),
                ),
              ),
            ),

            // ── Floating phone body
            AnimatedBuilder(
              animation: _floatY,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatY.value),
                child: AnimatedBuilder(
                  animation: _scanCtrl,
                  builder: (_, __) => _VerifyPhoneWidget(
                    scanProgress: _scanPos.value,
                    showCheck: _checkOpacity.value > 0.05,
                    checkOpacity: _checkOpacity.value,
                  ),
                ),
              ),
            ),

            // ── Orbiting data points
            AnimatedBuilder(
              animation: _dotCtrl,
              builder: (_, __) =>
                  _DataPointsPainter.widget(progress: _dotCtrl.value),
            ),
          ],
        ),
      ),
    );
  }
}

// ── VERIFY — Phone widget ─────────────────────────────────────────────────────
class _VerifyPhoneWidget extends StatelessWidget {
  final double scanProgress; // 0 = top, 1 = bottom
  final bool showCheck;
  final double checkOpacity;

  const _VerifyPhoneWidget({
    required this.scanProgress,
    this.showCheck = false,
    this.checkOpacity = 0.0,
  });

  static const _phoneW = 72.0;
  static const _phoneH = 124.0;
  static const _cornerR = 16.0;
  // Usable scan zone inside the phone
  static const _topPad = 18.0;
  static const _botPad = 14.0;

  @override
  Widget build(BuildContext context) {
    final scanTravel = _phoneH - _topPad - _botPad;

    return SizedBox(
      width: _phoneW + 40,
      height: _phoneH + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Phone body
          Container(
            width: _phoneW,
            height: _phoneH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_cornerR),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.bg3, Color(0xFF0A1E38)],
              ),
              border: Border.all(
                color: AppColors.primaryBright.withOpacity(0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.22),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Speaker pill
                Container(
                  width: 24,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: AppColors.primaryBright.withOpacity(0.25),
                  ),
                ),
                const SizedBox(height: 8),
                // Screen lines (data rows)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        4,
                        (i) => Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppColors.primaryBright.withOpacity(
                              0.08 + i * 0.03,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Home indicator
                Container(
                  width: 22,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1.5),
                    color: AppColors.primaryBright.withOpacity(0.2),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── Scan line
          if (scanProgress > 0 && scanProgress < 0.98)
            Positioned(
              top: 20 + _topPad + scanProgress * scanTravel - 1.5,
              left: 20,
              right: 20,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.9),
                      AppColors.primaryBright,
                      AppColors.primary.withOpacity(0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                ),
              ),
            ),

          // ── Scan sweep glow (soft band)
          if (scanProgress > 0 && scanProgress < 0.98)
            Positioned(
              top: 20 + _topPad + scanProgress * scanTravel - 12,
              left: 20,
              right: 20,
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.primary.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // ── Green checkmark after scan
          if (showCheck)
            Positioned(
              bottom: 12,
              child: Opacity(
                opacity: checkOpacity,
                child: Transform.scale(
                  scale: 0.7 + 0.3 * checkOpacity,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.trusted,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.trustedGlow,
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.bg0,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── VERIFY — Orbiting data points ─────────────────────────────────────────────
class _DataPointsPainter extends CustomPainter {
  final double progress;

  const _DataPointsPainter({required this.progress});

  // (angle offset, orbit radius, dot radius)
  static const _seeds = [
    (0.5, 108.0, 3.0),
    (1.4, 96.0, 2.2),
    (2.3, 114.0, 2.5),
    (3.2, 100.0, 3.2),
    (4.1, 106.0, 2.0),
    (5.2, 98.0, 2.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final (baseAngle, orbit, r) in _seeds) {
      final angle = baseAngle + progress * math.pi * 2 * 0.18;
      final opacity =
          0.55 + 0.35 * math.sin(progress * math.pi * 2 + baseAngle);
      final pos = Offset(
        center.dx + orbit * math.cos(angle),
        center.dy + orbit * math.sin(angle),
      );
      if (pos.dx < 0 ||
          pos.dx > size.width ||
          pos.dy < 0 ||
          pos.dy > size.height) {
        continue;
      }

      // Soft glow dot
      canvas.drawCircle(
        pos,
        r + 3,
        Paint()
          ..color = AppColors.primaryBright.withOpacity(
            (opacity * 0.25).clamp(0.0, 1.0),
          )
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = AppColors.primaryBright.withOpacity(opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_DataPointsPainter old) => old.progress != progress;

  static Widget widget({required double progress}) => CustomPaint(
    size: const Size(260, 260),
    painter: _DataPointsPainter(progress: progress),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 2 — PROTECT  "Protect What Matters"
//
// • Smartphone surrounded by a shield
// • Two expanding blue pulse rings
// • Small decorative particles moving around the shield
// • A lock symbol entering with a gentle scale animation
// ─────────────────────────────────────────────────────────────────────────────
class RadarIllustration extends StatefulWidget {
  const RadarIllustration({super.key});

  @override
  State<RadarIllustration> createState() => _RadarIllustrationState();
}

class _RadarIllustrationState extends State<RadarIllustration>
    with TickerProviderStateMixin, _LifecycleMixin {
  // Two staggered pulse rings
  late final AnimationController _pulseCtrl;
  // Particle orbit
  late final AnimationController _particleCtrl;
  // Float bob for the phone
  late final AnimationController _floatCtrl;
  // Lock entrance (plays once)
  late final AnimationController _lockCtrl;

  late final Animation<double> _floatY;
  late final Animation<double> _lockScale;
  late final Animation<double> _lockOpacity;

  // All four controllers — disposed by the mixin.
  @override
  List<AnimationController> get _controllers => [
    _pulseCtrl,
    _particleCtrl,
    _floatCtrl,
    _lockCtrl,
  ];

  // _lockCtrl is a one-shot entrance animation; do not repeat() it on resume.
  @override
  List<AnimationController> get _repeatableControllers => [
    _pulseCtrl,
    _particleCtrl,
    _floatCtrl,
  ];

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatY = Tween<double>(
      begin: -6.0,
      end: 6.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    // Lock entrance at 400 ms delay
    _lockCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _lockCtrl.forward();
    });

    _lockScale = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _lockCtrl, curve: Curves.easeOutBack));
    _lockOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _lockCtrl,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Illustration: smartphone inside a protective shield with a lock',
      excludeSemantics: true,
      child: reduceMotion
          ? _buildStatic()
          : RepaintBoundary(child: _buildAnimated()),
    );
  }

  Widget _buildStatic() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(200, 200),
              painter: _ShieldPainter(
                fillColor: AppColors.bg2,
                strokeColor: AppColors.primary,
                glowColor: AppColors.blueGlow40,
              ),
            ),
            const _ProtectPhoneWidget(),
            // Static lock badge
            Positioned(bottom: 52, child: _LockBadge(scale: 1.0, opacity: 1.0)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimated() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulse rings
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(260, 260),
                painter: _PulseRingsPainter(
                  progress: _pulseCtrl.value,
                  color: AppColors.primary,
                  ringCount: 2,
                  minRadius: 82.0,
                  maxRadius: 128.0,
                ),
              ),
            ),

            // ── Shield
            CustomPaint(
              size: const Size(196, 196),
              painter: _ShieldPainter(
                fillColor: AppColors.bg2,
                strokeColor: AppColors.primary,
                glowColor: AppColors.blueGlow40,
              ),
            ),

            // ── Floating phone
            AnimatedBuilder(
              animation: _floatY,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _floatY.value),
                child: const _ProtectPhoneWidget(),
              ),
            ),

            // ── Orbiting particles
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(260, 260),
                painter: _ProtectParticlesPainter(
                  progress: _particleCtrl.value,
                ),
              ),
            ),

            // ── Lock badge entrance
            AnimatedBuilder(
              animation: _lockCtrl,
              builder: (_, __) => Positioned(
                bottom: 48,
                child: _LockBadge(
                  scale: _lockScale.value,
                  opacity: _lockOpacity.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PROTECT — Phone widget ────────────────────────────────────────────────────
class _ProtectPhoneWidget extends StatelessWidget {
  const _ProtectPhoneWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 114,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bg3, Color(0xFF0A1E38)],
        ),
        border: Border.all(
          color: AppColors.primaryBright.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 4,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: AppColors.primaryBright.withOpacity(0.25),
            ),
          ),
          Container(
            width: 40,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppColors.bg1,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: AppColors.primaryBright.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PROTECT — Lock badge ──────────────────────────────────────────────────────
class _LockBadge extends StatelessWidget {
  final double scale;
  final double opacity;

  const _LockBadge({required this.scale, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.blueGradient,
            border: Border.all(color: AppColors.bg0, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.blueGlow40,
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ── PROTECT — Orbiting particle painter ──────────────────────────────────────
class _ProtectParticlesPainter extends CustomPainter {
  final double progress;

  const _ProtectParticlesPainter({required this.progress});

  static const _seeds = [
    (0.4, 112.0, 3.5),
    (1.2, 104.0, 2.5),
    (2.0, 118.0, 2.0),
    (2.9, 108.0, 3.0),
    (3.8, 115.0, 2.5),
    (4.7, 100.0, 2.0),
    (5.5, 110.0, 3.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final (baseAngle, orbit, r) in _seeds) {
      final angle = baseAngle + progress * math.pi * 2 * 0.14;
      final opacity =
          0.45 + 0.35 * math.sin(progress * math.pi * 2 + baseAngle);
      final pos = Offset(
        center.dx + orbit * math.cos(angle),
        center.dy + orbit * math.sin(angle),
      );
      if (pos.dx < 0 ||
          pos.dx > size.width ||
          pos.dy < 0 ||
          pos.dy > size.height) {
        continue;
      }

      // Halo
      canvas.drawCircle(
        pos,
        r + 2.5,
        Paint()
          ..color = AppColors.primary.withOpacity(
            (opacity * 0.2).clamp(0.0, 1.0),
          ),
      );
      // Core
      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = AppColors.primaryBright.withOpacity(
            opacity.clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_ProtectParticlesPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 3 — IDENTIFY  "Recognize Risks Early"
//
// • Radar with slowly rotating sweep
// • A few softly pulsing signal points
// • Amber warning symbol entering briefly
// • A guidance check symbol appearing afterward
// ─────────────────────────────────────────────────────────────────────────────
class TrustNetworkIllustration extends StatefulWidget {
  const TrustNetworkIllustration({super.key});

  @override
  State<TrustNetworkIllustration> createState() =>
      _TrustNetworkIllustrationState();
}

class _TrustNetworkIllustrationState extends State<TrustNetworkIllustration>
    with TickerProviderStateMixin, _LifecycleMixin {
  // Radar sweep rotation
  late final AnimationController _sweepCtrl;
  // Pulsing signal points
  late final AnimationController _signalCtrl;
  // Warning → check cycle (warning fades in, holds, fades out; check fades in)
  late final AnimationController _symbolCtrl;

  late final Animation<double> _warnOpacity;
  late final Animation<double> _checkOpacity;

  // Warning 0–35 %, hold 35–60 %, fade 60–75 %, check 75–100 %
  static const _symbolDuration = Duration(milliseconds: 3600);

  @override
  List<AnimationController> get _controllers => [
    _sweepCtrl,
    _signalCtrl,
    _symbolCtrl,
  ];

  @override
  void initState() {
    super.initState();

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _signalCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _symbolCtrl = AnimationController(vsync: this, duration: _symbolDuration)
      ..repeat();

    // Warning: fade in 0–12 %, hold 12–60 %, fade out 60–75 %
    _warnOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 48),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
    ]).animate(_symbolCtrl);

    // Check: fade in 78–92 %, hold 92–100 %
    _checkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 78),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 14,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 8),
    ]).animate(_symbolCtrl);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Illustration: radar screen showing signal detection',
      excludeSemantics: true,
      child: reduceMotion
          ? _buildStatic()
          : RepaintBoundary(child: _buildAnimated()),
    );
  }

  Widget _buildStatic() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(260, 260),
              painter: _RadarFacePainter(sweepAngle: 1.2),
            ),
            _RadarSignalDots(pulseValue: 0.5),
            // Static check symbol
            Positioned(
              top: 70,
              right: 64,
              child: _SymbolBadge(
                icon: Icons.check_circle_rounded,
                color: AppColors.trusted,
                opacity: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimated() {
    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Radar face with rotating sweep
            AnimatedBuilder(
              animation: _sweepCtrl,
              builder: (_, __) => CustomPaint(
                size: const Size(260, 260),
                painter: _RadarFacePainter(
                  sweepAngle: _sweepCtrl.value * math.pi * 2,
                ),
              ),
            ),

            // ── Pulsing signal dots
            AnimatedBuilder(
              animation: _signalCtrl,
              builder: (_, __) =>
                  _RadarSignalDots(pulseValue: _signalCtrl.value),
            ),

            // ── Warning badge (top-right quadrant)
            AnimatedBuilder(
              animation: _warnOpacity,
              builder: (_, __) => Positioned(
                top: 66,
                right: 58,
                child: _SymbolBadge(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  opacity: _warnOpacity.value,
                ),
              ),
            ),

            // ── Check / guidance symbol
            AnimatedBuilder(
              animation: _checkOpacity,
              builder: (_, __) => Positioned(
                top: 66,
                right: 58,
                child: _SymbolBadge(
                  icon: Icons.check_circle_rounded,
                  color: AppColors.trusted,
                  opacity: _checkOpacity.value,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── IDENTIFY — Radar face painter ────────────────────────────────────────────
class _RadarFacePainter extends CustomPainter {
  final double sweepAngle; // current rotation in radians

  const _RadarFacePainter({required this.sweepAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 - 4;

    // ── Concentric range rings (3 rings)
    final ringPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, maxR * i / 3, ringPaint);
    }

    // ── Cross-hair lines
    final crossPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.12)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - maxR, center.dy),
      Offset(center.dx + maxR, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxR),
      Offset(center.dx, center.dy + maxR),
      crossPaint,
    );

    // ── Sweep trail (60° fading arc)
    const trailSweep = math.pi / 3; // 60 degrees
    final trailRect = Rect.fromCircle(center: center, radius: maxR);
    final trailPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - trailSweep,
        endAngle: sweepAngle,
        colors: [
          AppColors.primary.withOpacity(0.0),
          AppColors.primary.withOpacity(0.28),
        ],
        transform: const GradientRotation(0),
      ).createShader(trailRect)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      trailRect,
      sweepAngle - trailSweep,
      trailSweep,
      true,
      trailPaint,
    );

    // ── Sweep leading line
    final linePaint = Paint()
      ..color = AppColors.primary.withOpacity(0.65)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center,
      Offset(
        center.dx + maxR * math.cos(sweepAngle),
        center.dy + maxR * math.sin(sweepAngle),
      ),
      linePaint,
    );

    // ── Outer border ring
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..color = AppColors.primary.withOpacity(0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // ── Center dot
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      9,
      Paint()
        ..color = AppColors.primary.withOpacity(0.25)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_RadarFacePainter old) => old.sweepAngle != sweepAngle;
}

// ── IDENTIFY — Signal dots on the radar ──────────────────────────────────────
class _RadarSignalDots extends StatelessWidget {
  final double pulseValue; // 0–1, drives size/opacity pulse

  const _RadarSignalDots({required this.pulseValue});

  // (x offset fraction, y offset fraction, base radius, phase offset)
  static const _dots = [
    (-0.22, -0.18, 4.5, 0.0),
    (0.15, -0.28, 3.5, 0.33),
    (0.30, 0.12, 3.0, 0.66),
    (-0.30, 0.20, 3.5, 0.5),
    (0.05, 0.32, 3.0, 0.2),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: _dots.map((d) {
          final (xF, yF, r, phase) = d;
          final pulse = (pulseValue + phase) % 1.0;
          final radius = r + 2.0 * math.sin(pulse * math.pi);
          final opacity = 0.45 + 0.45 * math.sin(pulse * math.pi);
          final x = 130 + xF * 200;
          final y = 130 + yF * 200;

          return Positioned(
            left: x - radius - 4,
            top: y - radius - 4,
            child: Container(
              width: (radius + 4) * 2,
              height: (radius + 4) * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(
                  (opacity * 0.25).clamp(0.0, 1.0),
                ),
              ),
              child: Center(
                child: Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryBright.withOpacity(
                      opacity.clamp(0.0, 1.0),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── IDENTIFY — Warning / Check symbol badge ───────────────────────────────────
class _SymbolBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double opacity;

  const _SymbolBadge({
    required this.icon,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: 0.75 + 0.25 * opacity,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.7), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Custom Painters
// ─────────────────────────────────────────────────────────────────────────────

// ── Shield painter (reused by VERIFY and PROTECT) ────────────────────────────
class _ShieldPainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;
  final Color glowColor;

  const _ShieldPainter({
    required this.fillColor,
    required this.strokeColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const halfW = 58.0;
    const topY = 76.0;
    const midY = 52.0;

    final path = Path()
      ..moveTo(cx, cy - topY)
      ..lineTo(cx + halfW, cy - midY)
      ..lineTo(cx + halfW, cy + 10)
      ..quadraticBezierTo(cx + halfW, cy + 50, cx, cy + 80)
      ..quadraticBezierTo(cx - halfW, cy + 50, cx - halfW, cy + 10)
      ..lineTo(cx - halfW, cy - midY)
      ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    // Fill
    canvas.drawPath(path, Paint()..color = fillColor);
    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    // Top-edge highlight
    canvas.drawPath(
      Path()
        ..moveTo(cx, cy - topY)
        ..lineTo(cx + halfW, cy - midY)
        ..lineTo(cx + halfW, cy - 10)
        ..moveTo(cx, cy - topY)
        ..lineTo(cx - halfW, cy - midY)
        ..lineTo(cx - halfW, cy - 10),
      Paint()
        ..color = strokeColor.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.fillColor != fillColor || old.strokeColor != strokeColor;
}

// ── Expanding pulse rings (used by PROTECT) ───────────────────────────────────
class _PulseRingsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;
  final double minRadius;
  final double maxRadius;

  const _PulseRingsPainter({
    required this.progress,
    required this.color,
    this.ringCount = 2,
    this.minRadius = 60.0,
    this.maxRadius = 130.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final range = maxRadius - minRadius;

    for (int i = 0; i < ringCount; i++) {
      final t = (progress + i / ringCount) % 1.0;
      final radius = minRadius + t * range;
      final opacity = (1.0 - t) * 0.28;
      if (opacity <= 0) continue;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = color.withOpacity(opacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_PulseRingsPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Kept for backward compatibility — original pages not used by onboarding
// ─────────────────────────────────────────────────────────────────────────────

/// Original page-1 illustration (kept; not used in the current 3-page flow).
class ShieldIllustration extends StatefulWidget {
  const ShieldIllustration({super.key});

  @override
  State<ShieldIllustration> createState() => _ShieldIllustrationState();
}

class _ShieldIllustrationState extends State<ShieldIllustration>
    with TickerProviderStateMixin, _LifecycleMixin {
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _ringCtrl;
  late final AnimationController _particleCtrl;
  late final Animation<double> _floatY;

  @override
  List<AnimationController> get _controllers => [
    _floatCtrl,
    _pulseCtrl,
    _ringCtrl,
    _particleCtrl,
  ];

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatY = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, _) => CustomPaint(
                size: const Size(280, 280),
                painter: _PulseRingsPainter(
                  progress: _pulseCtrl.value,
                  color: AppColors.primary,
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, _) => Transform.rotate(
                angle: _ringCtrl.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(250, 250),
                  painter: _DashedRingPainter(
                    color: AppColors.primary.withOpacity(0.4),
                    strokeWidth: 1.5,
                    dashCount: 28,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, _) => Transform.rotate(
                angle: -_ringCtrl.value * 2 * math.pi * 0.5,
                child: CustomPaint(
                  size: const Size(210, 210),
                  painter: _DashedRingPainter(
                    color: AppColors.primaryBright.withOpacity(0.2),
                    strokeWidth: 1,
                    dashCount: 18,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, _floatY.value * 0.4),
                child: Container(
                  width: 120,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    color: AppColors.blueGlow40.withOpacity(0.45),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.35),
                        blurRadius: 50,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(180, 180),
              painter: _ShieldPainter(
                fillColor: AppColors.bg2.withOpacity(0.85),
                strokeColor: AppColors.primary,
                glowColor: AppColors.blueGlow40,
              ),
            ),
            AnimatedBuilder(
              animation: _floatY,
              builder: (_, _) => Transform.translate(
                offset: Offset(0, _floatY.value),
                child: Container(
                  width: 72,
                  height: 122,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.bg3, Color(0xFF0D2540)],
                    ),
                    border: Border.all(
                      color: AppColors.primaryBright.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: AppColors.primaryBright.withOpacity(0.3),
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.bg1,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(1.5),
                          color: AppColors.primaryBright.withOpacity(0.25),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _floatCtrl,
              builder: (_, _) => Transform.translate(
                offset: const Offset(0, 72),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.blueGradient,
                    border: Border.all(color: AppColors.bg0, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blueGlow40,
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _particleCtrl,
              builder: (_, _) => CustomPaint(
                size: const Size(280, 280),
                painter: _OldSecurityParticlesPainter(
                  progress: _particleCtrl.value,
                  color: AppColors.primaryBright,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed ring painter (used by ShieldIllustration) ─────────────────────────
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashCount;

  const _DashedRingPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;
    final dashAngle = 2 * math.pi / dashCount;
    final gapAngle = dashAngle * 0.35;
    final drawAngle = dashAngle - gapAngle;

    for (int i = 0; i < dashCount; i++) {
      final start = i * dashAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        drawAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ── Legacy particles painter (used only by ShieldIllustration) ───────────────
class _OldSecurityParticlesPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _OldSecurityParticlesPainter({
    required this.progress,
    required this.color,
  });

  static const _seeds = [
    (0.3, 105.0, 3.0),
    (1.1, 95.0, 2.0),
    (1.9, 115.0, 2.5),
    (2.8, 100.0, 3.5),
    (3.7, 108.0, 2.0),
    (4.5, 98.0, 2.5),
    (5.4, 112.0, 3.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final (angle0, orbit0, r) in _seeds) {
      final drift = orbit0 + progress * 18;
      final angle = angle0 + progress * 0.8;
      final opacity = 1.0 - progress * 0.7;
      final pos = Offset(
        center.dx + drift * math.cos(angle),
        center.dy + drift * math.sin(angle),
      );
      if (pos.dx < 0 ||
          pos.dx > size.width ||
          pos.dy < 0 ||
          pos.dy > size.height) {
        continue;
      }

      canvas.drawCircle(
        pos,
        r,
        Paint()
          ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
          ..style = PaintingStyle.fill,
      );
      if (r > 2.5) {
        final lp = Paint()
          ..color = color.withOpacity((opacity * 0.6).clamp(0.0, 1.0))
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        canvas.drawLine(pos.translate(-4, -4), pos.translate(4, 4), lp);
        canvas.drawLine(pos.translate(4, -4), pos.translate(-4, 4), lp);
      }
    }
  }

  @override
  bool shouldRepaint(_OldSecurityParticlesPainter old) =>
      old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Page 4 — TRUST SCORE  "Your Digital Trust at a Glance"
//
// Redesigned for zero overflow: LayoutBuilder drives all sizing so ring
// and step rows proportionally fill whatever height the wrapper allocates.
// ─────────────────────────────────────────────────────────────────────────────
class TrustScoreIllustration extends StatefulWidget {
  const TrustScoreIllustration({super.key});

  @override
  State<TrustScoreIllustration> createState() => _TrustScoreIllustrationState();
}

class _TrustScoreIllustrationState extends State<TrustScoreIllustration>
    with TickerProviderStateMixin, _LifecycleMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _rowsCtrl;
  late final AnimationController _glowCtrl;

  late final Animation<double> _ringFraction;
  late final Animation<double> _scoreValue;

  static const _targetScore = 75.0;
  static const _maxScore = 100.0;

  @override
  List<AnimationController> get _controllers => [
    _ringCtrl,
    _rowsCtrl,
    _glowCtrl,
  ];

  @override
  List<AnimationController> get _repeatableControllers => [_glowCtrl];

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _rowsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _ringFraction = Tween<double>(
      begin: 0.0,
      end: _targetScore / _maxScore,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _scoreValue = Tween<double>(
      begin: 0,
      end: _targetScore,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    Future.microtask(() {
      if (!mounted) return;
      _ringCtrl.forward().then((_) {
        if (mounted) _rowsCtrl.forward();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label:
          'Illustrative Trust Score preview showing three verification steps',
      excludeSemantics: true,
      child: reduceMotion
          ? _TrustScoreLayout(
              ringFraction: _targetScore / _maxScore,
              scoreValue: _targetScore,
              rowProgress: 1.0,
              glowPulse: 0.5,
            )
          : RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_ringCtrl, _rowsCtrl, _glowCtrl]),
                builder: (context, _) => _TrustScoreLayout(
                  ringFraction: _ringFraction.value,
                  scoreValue: _scoreValue.value,
                  rowProgress: _rowsCtrl.value,
                  glowPulse: _glowCtrl.value,
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TrustScoreLayout
//
// Uses LayoutBuilder to measure available space, then derives all sizes from
// that — no fixed px values, no overflow possible.
// ─────────────────────────────────────────────────────────────────────────────
class _TrustScoreLayout extends StatelessWidget {
  final double ringFraction;
  final double scoreValue;
  final double rowProgress;
  final double glowPulse;

  const _TrustScoreLayout({
    required this.ringFraction,
    required this.scoreValue,
    required this.rowProgress,
    required this.glowPulse,
  });

  static const _steps = [
    (Icons.smartphone_rounded, 'Device Verification'),
    (Icons.verified_user_rounded, 'Identity Verification'),
    (Icons.shield_rounded, 'Protection Activation'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Available space — fall back to sensible defaults if unbounded.
        final h = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 300.0;
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;

        // Ring: 44 % of height, clamped so it stays proportional.
        final ringD = (h * 0.44).clamp(96.0, 156.0);
        final strokeW = (ringD * 0.08).clamp(7.0, 12.0);

        // Row heights: evenly fill what remains after ring + gaps.
        const gaps = 36.0; // chip (20) + spacer (6) + spacer (10)
        final rowsH = h - ringD - gaps;
        final rowH = (rowsH / 3).clamp(36.0, 54.0);
        final iconSz = (rowH * 0.44).clamp(13.0, 20.0);
        final labelSz = (rowH * 0.30).clamp(10.5, 13.5);
        final chipSz = (rowH * 0.21).clamp(8.0, 10.5);
        final hPad = (w * 0.04).clamp(8.0, 20.0);

        return Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Score ring ────────────────────────────────────────────────
            SizedBox(
              width: ringD,
              height: ringD,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Breathing glow
                  Container(
                    width: ringD * (0.86 + 0.08 * glowPulse),
                    height: ringD * (0.86 + 0.08 * glowPulse),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(
                        0.05 + 0.04 * glowPulse,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(
                            0.11 + 0.07 * glowPulse,
                          ),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  // Track
                  CustomPaint(
                    size: Size(ringD, ringD),
                    painter: _RingTrackPainter(
                      trackColor: AppColors.bg3,
                      strokeWidth: strokeW,
                    ),
                  ),
                  // Arc
                  CustomPaint(
                    size: Size(ringD, ringD),
                    painter: _RingArcPainter(
                      fraction: ringFraction,
                      strokeWidth: strokeW,
                      colorStart: AppColors.blue700,
                      colorEnd: AppColors.primaryBright,
                      glowColor: AppColors.blueGlow40,
                    ),
                  ),
                  // Score label
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scoreValue.round().toString(),
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: ringD * 0.27,
                          fontWeight: FontWeight.w800,
                          color: ringFraction > 0.4
                              ? AppColors.primaryBright
                              : AppColors.textPrimary,
                          letterSpacing: 0.8,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: TextStyle(
                          fontFamily: 'Rajdhani',
                          fontSize: (ringD * 0.085).clamp(8.0, 11.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── "Illustrative preview" chip ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.bg2,
                border: Border.all(color: AppColors.divider, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 9,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Illustrative preview',
                    style: TextStyle(
                      fontFamily: 'Rajdhani',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Step rows ─────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_steps.length, (i) {
                    const window = 0.55;
                    final start = i * (1.0 - window) / (_steps.length - 1);
                    final t = ((rowProgress - start) / window).clamp(0.0, 1.0);
                    final eased = Curves.easeOut.transform(t);

                    return Opacity(
                      opacity: eased,
                      child: Transform.translate(
                        offset: Offset(0, 8 * (1.0 - eased)),
                        child: _StepRow(
                          icon: _steps[i].$1,
                          label: _steps[i].$2,
                          rowHeight: rowH,
                          iconSize: iconSz,
                          labelFontSize: labelSz,
                          chipFontSize: chipSz,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StepRow — all sizes driven by the parent LayoutBuilder, no overflow
// ─────────────────────────────────────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double rowHeight;
  final double iconSize;
  final double labelFontSize;
  final double chipFontSize;

  const _StepRow({
    required this.icon,
    required this.label,
    required this.rowHeight,
    required this.iconSize,
    required this.labelFontSize,
    required this.chipFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final badgeD = iconSize * 2.0;
    final radius = rowHeight * 0.30;
    final hPad = rowHeight * 0.26;

    return Container(
      height: rowHeight,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: AppColors.bg2,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: badgeD,
            height: badgeD,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: Icon(icon, color: AppColors.primaryBright, size: iconSize),
          ),
          SizedBox(width: rowHeight * 0.20),
          // Label
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: labelFontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(width: rowHeight * 0.12),
          // Status chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: rowHeight * 0.20,
              vertical: rowHeight * 0.08,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.bg3,
              border: Border.all(color: AppColors.outline, width: 1),
            ),
            child: Text(
              'To complete',
              style: TextStyle(
                fontFamily: 'Rajdhani',
                fontSize: chipFontSize,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring track painter — static grey background circle
// ─────────────────────────────────────────────────────────────────────────────
class _RingTrackPainter extends CustomPainter {
  final Color trackColor;
  final double strokeWidth;

  const _RingTrackPainter({
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingTrackPainter old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Ring arc painter — animated fill with gradient + glow tip
// ─────────────────────────────────────────────────────────────────────────────
class _RingArcPainter extends CustomPainter {
  final double fraction;
  final double strokeWidth;
  final Color colorStart;
  final Color colorEnd;
  final Color glowColor;

  const _RingArcPainter({
    required this.fraction,
    required this.strokeWidth,
    required this.colorStart,
    required this.colorEnd,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fraction <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * fraction;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Soft glow layer
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = glowColor.withOpacity(0.40)
        ..strokeWidth = strokeWidth + 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Gradient arc
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [colorStart, colorEnd],
        ).createShader(rect)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Bright tip dot at arc end
    if (fraction > 0.02) {
      final tipAngle = startAngle + sweepAngle;
      canvas.drawCircle(
        Offset(
          center.dx + radius * math.cos(tipAngle),
          center.dy + radius * math.sin(tipAngle),
        ),
        strokeWidth / 2,
        Paint()..color = colorEnd,
      );
    }
  }

  @override
  bool shouldRepaint(_RingArcPainter old) => old.fraction != fraction;
}
