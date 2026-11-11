import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Premium animated brand header with:
/// - Rounded-square icon container with subtle rotating light reflection
/// - Animated stroke-drawn campus home icon
/// - Smooth slide and fade brand name reveal
class AnimatedBrandHeader extends StatefulWidget {
  final double animationProgress; // 0.0 to 1.0 driving the entrance

  const AnimatedBrandHeader({
    super.key,
    required this.animationProgress,
  });

  @override
  State<AnimatedBrandHeader> createState() => _AnimatedBrandHeaderState();
}

class _AnimatedBrandHeaderState extends State<AnimatedBrandHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.animationProgress.clamp(0.0, 1.0);

    // Staggered curves
    final iconScale = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ).value;

    final iconFade = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ).value;

    final strokeDraw = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: const Interval(0.2, 0.85, curve: Curves.easeInOutCubic),
    ).value;

    final textSlide = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ).value;

    final textFade = CurvedAnimation(
      parent: AlwaysStoppedAnimation(t),
      curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
    ).value;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo Container
        Opacity(
          opacity: iconFade,
          child: Transform.scale(
            scale: iconScale,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, _) {
                final shimmerAngle = _shimmerController.value * 2 * math.pi;

                return Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1), // Bright indigo
                        Color(0xFF4F46E5), // Core brand
                        Color(0xFF4338CA), // Deep royal
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, -1),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 1.4,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating subtle light reflection ring
                      CustomPaint(
                        size: const Size(52, 52),
                        painter: _LightReflectionPainter(angle: shimmerAngle),
                      ),
                      // Stroke-animated Home Campus Icon
                      CustomPaint(
                        size: const Size(26, 26),
                        painter: _HomeIconPainter(progress: strokeDraw),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Brand Title
        Opacity(
          opacity: textFade,
          child: Transform.translate(
            offset: Offset((1.0 - textSlide) * 24.0, 0),
            child: const Text(
              'Vriyda Portal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontFamily: '-apple-system',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LightReflectionPainter extends CustomPainter {
  final double angle;

  _LightReflectionPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    final paint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: angle,
        endAngle: angle + math.pi * 2,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.4),
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.3],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _LightReflectionPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

class _HomeIconPainter extends CustomPainter {
  final double progress;

  _HomeIconPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    // Continuous stroke: Roof left -> Roof apex -> Roof right -> Right wall -> Floor right -> Inner door right -> Door top -> Inner door left -> Floor left -> Left wall -> Roof left
    path.moveTo(size.width * 0.15, size.height * 0.46);
    path.lineTo(size.width * 0.50, size.height * 0.18);
    path.lineTo(size.width * 0.85, size.height * 0.46);
    path.lineTo(size.width * 0.80, size.height * 0.46);
    path.lineTo(size.width * 0.80, size.height * 0.82);
    path.lineTo(size.width * 0.58, size.height * 0.82);
    path.lineTo(size.width * 0.58, size.height * 0.58);
    path.lineTo(size.width * 0.42, size.height * 0.58);
    path.lineTo(size.width * 0.42, size.height * 0.82);
    path.lineTo(size.width * 0.20, size.height * 0.82);
    path.lineTo(size.width * 0.20, size.height * 0.46);
    path.close();

    if (progress >= 0.98) {
      canvas.drawPath(path, paint);
      return;
    }

    // Extract path metrics according to progress
    final pathMetrics = path.computeMetrics().toList();
    final drawPath = Path();

    double totalLength = 0;
    for (final metric in pathMetrics) {
      totalLength += metric.length;
    }

    double currentTarget = totalLength * progress;
    for (final metric in pathMetrics) {
      if (currentTarget <= 0) break;
      final extractLength = math.min(metric.length, currentTarget);
      drawPath.addPath(metric.extractPath(0, extractLength), Offset.zero);
      currentTarget -= extractLength;
    }

    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant _HomeIconPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
