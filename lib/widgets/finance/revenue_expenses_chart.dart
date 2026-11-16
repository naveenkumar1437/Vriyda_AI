import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Trailing 12 months Revenue vs Operating Expenses Chart
class RevenueExpensesChart extends StatelessWidget {
  final List<MonthlyFinanceTrend> trendSeries;

  const RevenueExpensesChart({
    super.key,
    required this.trendSeries,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Revenue vs operating expenses',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Trailing 12 months · ₹ crore',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7C3AED),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Revenue',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF94A3B8),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Custom Painted Chart
          SizedBox(
            height: 130,
            width: double.infinity,
            child: CustomPaint(
              painter: _RevenueExpensesPainter(trendSeries),
            ),
          ),
          const SizedBox(height: 6),

          // Monthly X-Axis labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: (trendSeries.isNotEmpty
                      ? trendSeries.map((t) => t.month).toList()
                      : ['Jul', 'Sep', 'Nov', 'Jan', 'Mar', 'May', 'Jun'])
                  .map(
                    (m) => Text(
                      m,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueExpensesPainter extends CustomPainter {
  final List<MonthlyFinanceTrend> data;

  _RevenueExpensesPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double w = size.width;
    final double h = size.height;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = (h / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final double maxVal = 18.0; // scale up to 18 Cr
    final double stepX = w / (data.length - 1);

    final Path revenuePath = Path();
    final Path expensesPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final yRev = h - (data[i].revenue / maxVal) * h;
      final yExp = h - (data[i].expenses / maxVal) * h;

      if (i == 0) {
        revenuePath.moveTo(x, yRev);
        expensesPath.moveTo(x, yExp);
      } else {
        final prevX = (i - 1) * stepX;
        final prevYRev = h - (data[i - 1].revenue / maxVal) * h;
        final prevYExp = h - (data[i - 1].expenses / maxVal) * h;

        final cx1 = prevX + (x - prevX) / 2;
        final cx2 = cx1;

        revenuePath.cubicTo(cx1, prevYRev, cx2, yRev, x, yRev);
        expensesPath.cubicTo(cx1, prevYExp, cx2, yExp, x, yExp);
      }
    }

    // Revenue Gradient Fill
    final Path fillPath = Path.from(revenuePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.18),
          const Color(0xFF7C3AED).withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Revenue Line
    final revPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(revenuePath, revPaint);

    // Expenses Dashed Line
    final expPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, expensesPath, expPaint, dashLength: 4.0, gapLength: 3.0);

    // Mid-point Callout Pin at index 5 (Dec)
    if (data.length > 5) {
      final pinX = 5 * stepX;
      final pinYRev = h - (data[5].revenue / maxVal) * h;

      final dotPaint = Paint()..color = const Color(0xFF7C3AED);
      final whiteDotPaint = Paint()..color = Colors.white;

      canvas.drawCircle(Offset(pinX, pinYRev), 4.5, dotPaint);
      canvas.drawCircle(Offset(pinX, pinYRev), 2.5, whiteDotPaint);
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double gapLength,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashLength < metric.length) ? dashLength : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueExpensesPainter oldDelegate) => true;
}
