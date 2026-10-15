import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Particle data model
// ─────────────────────────────────────────────────────────────────────────────
class _Particle {
  double x, y, radius, speed, opacity, angle;
  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.angle,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Background – floating particles + subtle grid + radial glow
// ─────────────────────────────────────────────────────────────────────────────
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late final AnimationController _particleController;
  late final AnimationController _pulseController;
  late final List<_Particle> _particles;
  final _rng = math.Random(42);

  @override
  void initState() {
    super.initState();

    // Spawn 60 particles
    _particles = List.generate(60, (_) => _spawnParticle(initial: true));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  _Particle _spawnParticle({bool initial = false}) {
    return _Particle(
      x: _rng.nextDouble(),
      y: initial ? _rng.nextDouble() : 1.05,
      radius: _rng.nextDouble() * 1.8 + 0.5,
      speed: _rng.nextDouble() * 0.006 + 0.002,
      opacity: _rng.nextDouble() * 0.45 + 0.1,
      angle: (_rng.nextDouble() - 0.5) * 0.004,
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
        ),

        // Animated particle layer — isolated in its own repaint boundary so
        // its constant per-frame repaints don't dirty the rest of the Stack.
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (_, __) {
              // Tick each particle upward
              for (final p in _particles) {
                p.y -= p.speed;
                p.x += p.angle;
                if (p.y < -0.05) {
                  final fresh = _spawnParticle();
                  p
                    ..x = fresh.x
                    ..y = fresh.y
                    ..radius = fresh.radius
                    ..speed = fresh.speed
                    ..opacity = fresh.opacity
                    ..angle = fresh.angle;
                }
              }
              return CustomPaint(
                painter: _ParticlePainter(particles: _particles),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),

        // Subtle dot-grid overlay
        CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),

        // Radial blue glow – bottom center, isolated repaint boundary
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) {
              final pulse = _pulseController.value;
              return Positioned(
                bottom: -120,
                left: 0,
                right: 0,
                child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        AppColors.primary.withOpacity(0.12 + pulse * 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Top-right accent glow
        Positioned(
          top: -80,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryDim.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle painter
// ─────────────────────────────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = AppColors.primaryBright.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot-grid painter – very subtle
// ─────────────────────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..style = PaintingStyle.fill;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
