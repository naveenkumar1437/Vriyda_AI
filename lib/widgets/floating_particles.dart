import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Floating glowing micro-particles drifting slowly with breathing opacities.
class FloatingParticles extends StatefulWidget {
  final int count;
  const FloatingParticles({super.key, this.count = 28});

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.count; i++) {
      _particles.add(
        _Particle(
          xRel: _random.nextDouble(),
          yRel: _random.nextDouble(),
          radius: 1.2 + _random.nextDouble() * 2.2,
          speed: 0.15 + _random.nextDouble() * 0.35,
          phase: _random.nextDouble() * 2 * math.pi,
          baseAlpha: 0.25 + _random.nextDouble() * 0.45,
          isViolet: _random.nextBool(),
        ),
      );
    }

    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _driftController,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            particles: _particles,
            progress: _driftController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final double xRel;
  final double yRel;
  final double radius;
  final double speed;
  final double phase;
  final double baseAlpha;
  final bool isViolet;

  _Particle({
    required this.xRel,
    required this.yRel,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.baseAlpha,
    required this.isViolet,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // Slow vertical drift with periodic wrap-around
      final currentY = ((p.yRel - (progress * p.speed)) % 1.0) * size.height;
      // Gentle horizontal sway
      final currentX =
          ((p.xRel + (math.sin(progress * 2 * math.pi + p.phase) * 0.03)) % 1.0) *
              size.width;

      final breath = (math.sin(progress * 4 * math.pi + p.phase) + 1.0) / 2.0;
      final alpha = (p.baseAlpha * (0.6 + 0.4 * breath)).clamp(0.0, 1.0);

      final color = p.isViolet
          ? const Color(0xFFC084FC).withValues(alpha: alpha)
          : const Color(0xFF93C5FD).withValues(alpha: alpha);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Soft glow around particle
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

      canvas.drawCircle(Offset(currentX, currentY), p.radius * 2.2, glowPaint);
      canvas.drawCircle(Offset(currentX, currentY), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
