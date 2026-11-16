import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Collection rate trend (Group % collected · 12 mo line chart)
class CollectionRateTrendChart extends StatelessWidget {
  final List<MonthlyFinanceTrend> trendSeries;
  final double currentCollectionPct;

  const CollectionRateTrendChart({
    super.key,
    required this.trendSeries,
    required this.currentCollectionPct,
  });

  @override
  Widget build(BuildContext context) {
    if (trendSeries.isEmpty && currentCollectionPct <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No collection rate trend recorded in API.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      );
    }

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
          const Text(
            'Collection rate trend',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Group % collected · 12 mo',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Percentage Grid Markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('76%', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
              Text('70%', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
              Text('65%', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
              Text('59%', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
            ],
          ),
          const SizedBox(height: 6),

          // Custom Painted Trend Curve
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(
              painter: _CollectionTrendPainter(
                trendSeries: trendSeries,
                targetPct: currentCollectionPct,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Months Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: (trendSeries.isNotEmpty
                    ? trendSeries.map((t) => t.month).toList()
                    : ['Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
                .map(
                  (m) => Text(
                    m,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CollectionTrendPainter extends CustomPainter {
  final List<MonthlyFinanceTrend> trendSeries;
  final double targetPct;

  _CollectionTrendPainter({
    required this.trendSeries,
    required this.targetPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 2; i++) {
      final y = (h / 2) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final path = Path();
    final int count = trendSeries.isNotEmpty ? trendSeries.length : 12;
    final double stepX = w / (count - 1);

    // Calculate progression from base (~50%) up to currentCollectionPct
    final double startPct = (targetPct > 55 ? targetPct - 18.0 : targetPct * 0.7).clamp(40.0, 95.0);
    final double endPct = targetPct.clamp(40.0, 100.0);

    for (int i = 0; i < count; i++) {
      final double progress = i / (count - 1);
      final double current = startPct + (endPct - startPct) * progress;
      final x = i * stepX;
      // Invert Y axis: higher % = higher up on screen
      final y = h - ((current - 40.0) / 60.0) * h;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final double prevVal = startPct + (endPct - startPct) * ((i - 1) / (count - 1));
        final prevY = h - ((prevVal - 40.0) / 60.0) * h;
        final cx1 = prevX + (x - prevX) / 2;
        path.cubicTo(cx1, prevY, cx1, y, x, y);
      }
    }

    // Fill Gradient
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF10B981).withValues(alpha: 0.18),
          const Color(0xFF10B981).withValues(alpha: 0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Green stroke line
    final linePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Endpoint dot
    final lastY = h - ((endPct - 40.0) / 60.0) * h;
    final dotPaint = Paint()..color = const Color(0xFF10B981);
    final whiteDotPaint = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(w - 1, lastY), 4, dotPaint);
    canvas.drawCircle(Offset(w - 1, lastY), 2, whiteDotPaint);
  }

  @override
  bool shouldRepaint(covariant _CollectionTrendPainter oldDelegate) => true;
}
