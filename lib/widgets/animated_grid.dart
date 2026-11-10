import 'package:flutter/material.dart';

/// Renders a subtle square geometric grid with moving light sweeps
/// and soft pulse across lines.
class VriydaAnimatedGrid extends StatefulWidget {
  final double opacity;
  const VriydaAnimatedGrid({super.key, this.opacity = 1.0});

  @override
  State<VriydaAnimatedGrid> createState() => _VriydaAnimatedGridState();
}

class _VriydaAnimatedGridState extends State<VriydaAnimatedGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweepController,
      builder: (context, _) {
        return Opacity(
          opacity: widget.opacity,
          child: CustomPaint(
            painter: _GridPainter(
              sweepProgress: _sweepController.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final double sweepProgress;

  _GridPainter({required this.sweepProgress});

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 32.0; // Clean geometric square size
    final basePaint = Paint()
      ..color = const Color(0xFF818CF8).withValues(alpha: 0.055)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw base vertical lines
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), basePaint);
    }

    // Draw base horizontal lines
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), basePaint);
    }

    // Moving horizontal light sweep
    final sweepY = size.height * sweepProgress;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          const Color(0xFFA5B4FC).withValues(alpha: 0.12),
          const Color(0xFFC7D2FE).withValues(alpha: 0.18),
          const Color(0xFFA5B4FC).withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, sweepY - 80, size.width, 160));

    final sweepRect = Rect.fromLTWH(0, sweepY - 80, size.width, 160);
    canvas.save();
    canvas.clipRect(sweepRect);

    // Accentuated lines inside the light sweep
    final accentPaint = Paint()
      ..color = const Color(0xFFE0E7FF).withValues(alpha: 0.10)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (double y = ((sweepY - 80) ~/ step) * step; y <= sweepY + 80; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), accentPaint);
    }
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, sweepY - 80), Offset(x, sweepY + 80), accentPaint);
    }

    canvas.restore();

    // Subtle soft glow rect overlay over the sweep area
    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 50, size.width, 100),
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.sweepProgress != sweepProgress;
  }
}
