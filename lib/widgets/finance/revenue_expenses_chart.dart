import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Trailing 12 months Revenue vs Operating Expenses Chart
/// Matching the exact design layout: Top Y-axis markers, smooth dual curves,
/// gradient fill, Callout Tooltip box at Dec, and 7-month bottom axis.
class RevenueExpensesChart extends StatefulWidget {
  final List<MonthlyFinanceTrend> trendSeries;

  const RevenueExpensesChart({
    super.key,
    required this.trendSeries,
  });

  @override
  State<RevenueExpensesChart> createState() => _RevenueExpensesChartState();
}

class _RevenueExpensesChartState extends State<RevenueExpensesChart> {
  // Index 5 corresponds to 'Dec' (matches mockup callout)
  int _selectedIndex = 5;

  static const List<String> _kMonths = [
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  ];

  static const List<double> _kDefaultRevenueLakhs = [
    10.5, 9.2, 8.0, 7.2, 6.5, 10.0,
    4.5, 5.8, 7.0, 9.5, 14.0, 11.5,
  ];

  static const List<double> _kDefaultExpensesLakhs = [
    6.0, 6.5, 7.2, 6.2, 5.8, 6.8,
    5.0, 5.5, 6.0, 6.5, 7.8, 7.2,
  ];

  @override
  Widget build(BuildContext context) {
    // Prepare 12 monthly data points in Lakhs
    final List<double> revPoints = List<double>.from(_kDefaultRevenueLakhs);
    final List<double> expPoints = List<double>.from(_kDefaultExpensesLakhs);

    if (widget.trendSeries.isNotEmpty) {
      final Map<String, MonthlyFinanceTrend> map = {
        for (final t in widget.trendSeries) t.month.toLowerCase(): t,
      };

      for (int i = 0; i < _kMonths.length; i++) {
        final key = _kMonths[i].toLowerCase();
        final item = map[key];
        if (item != null && (item.revenue > 0 || item.expenses > 0)) {
          // Convert from raw rupees to Lakhs if >= 1000
          final r = item.revenue >= 1000 ? item.revenue / 100000.0 : item.revenue;
          final e = item.expenses >= 1000 ? item.expenses / 100000.0 : item.expenses;
          revPoints[i] = r;
          expPoints[i] = e;
        }
      }
    }

    // Dynamic max scale
    double maxVal = 16.0;
    for (final v in revPoints) {
      if (v > maxVal) maxVal = v;
    }
    for (final v in expPoints) {
      if (v > maxVal) maxVal = v;
    }
    maxVal = math.max(16.0, (maxVal * 1.12));

    final selectedMonth = _kMonths[_selectedIndex];
    final selectedRev = revPoints[_selectedIndex];
    final selectedExp = expPoints[_selectedIndex];

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
          const SizedBox(height: 14),

          // Inner Light-bordered Container matching mockup
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 8, left: 12, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Y-axis Scale Labels Row: [₹15.0 L   ₹11.3 L   ₹7.5 L   ₹3.8 L   ₹0.0 L]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '₹15.0 L',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹11.3 L',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹7.5 L',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹3.8 L',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '₹0.0 L',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Chart Canvas & Callout Tooltip
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double w = constraints.maxWidth;
                    const double h = 135.0;

                    // Position of selected pin
                    final double stepX = w / 11.0;
                    final double pinX = _selectedIndex * stepX;
                    final double pinYRev = h - (revPoints[_selectedIndex] / maxVal) * (h - 26) - 10;

                    final double tooltipLeft = (pinX - 54).clamp(4.0, w - 108);
                    final double tooltipTop = (pinYRev - 56).clamp(0.0, h - 50);

                    return GestureDetector(
                      onTapUp: (details) {
                        final localX = details.localPosition.dx;
                        final idx = ((localX / w) * 11).round().clamp(0, 11);
                        setState(() => _selectedIndex = idx);
                      },
                      child: SizedBox(
                        height: h,
                        width: w,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Custom painted curves and grid
                            CustomPaint(
                              size: Size(w, h),
                              painter: _RevenueExpensesPainter(
                                revPoints: revPoints,
                                expPoints: expPoints,
                                maxVal: maxVal,
                                selectedIndex: _selectedIndex,
                              ),
                            ),

                            // Floating Callout Bubble at selected pin
                            Positioned(
                              left: tooltipLeft,
                              top: tooltipTop,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFEDE9FE), width: 1.2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedMonth,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Revenue ₹${selectedRev.toStringAsFixed(1)} L',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                    Text(
                                      'Expenses ₹${selectedExp.toStringAsFixed(1)} L',
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                // 7-Month Bottom X-Axis: [Jul   Sep   Nov   Jan   Mar   May   Jun]
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Jul', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('Sep', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('Nov', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('Jan', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('Mar', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('May', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                    Text('Jun', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueExpensesPainter extends CustomPainter {
  final List<double> revPoints;
  final List<double> expPoints;
  final double maxVal;
  final int selectedIndex;

  _RevenueExpensesPainter({
    required this.revPoints,
    required this.expPoints,
    required this.maxVal,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = (h / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final double stepX = w / 11.0;

    final Path revenuePath = Path();
    final Path expensesPath = Path();

    for (int i = 0; i < 12; i++) {
      final x = i * stepX;
      final yRev = h - (revPoints[i] / maxVal) * (h - 26) - 10;
      final yExp = h - (expPoints[i] / maxVal) * (h - 26) - 10;

      if (i == 0) {
        revenuePath.moveTo(x, yRev);
        expensesPath.moveTo(x, yExp);
      } else {
        final prevX = (i - 1) * stepX;
        final prevYRev = h - (revPoints[i - 1] / maxVal) * (h - 26) - 10;
        final prevYExp = h - (expPoints[i - 1] / maxVal) * (h - 26) - 10;

        final cx1 = prevX + (x - prevX) / 2;

        revenuePath.cubicTo(cx1, prevYRev, cx1, yRev, x, yRev);
        expensesPath.cubicTo(cx1, prevYExp, cx1, yExp, x, yExp);
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
          const Color(0xFF7C3AED).withValues(alpha: 0.005),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Revenue Solid Purple Curve
    final revPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(revenuePath, revPaint);

    // Expenses Dashed Slate Curve
    final expPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, expensesPath, expPaint, dashLength: 4.0, gapLength: 3.0);

    // Pin circle on Revenue Curve at selectedIndex
    final pinX = selectedIndex * stepX;
    final pinYRev = h - (revPoints[selectedIndex] / maxVal) * (h - 26) - 10;

    final dotPaint = Paint()..color = const Color(0xFF7C3AED);
    final whiteDotPaint = Paint()..color = Colors.white;

    canvas.drawCircle(Offset(pinX, pinYRev), 4.5, dotPaint);
    canvas.drawCircle(Offset(pinX, pinYRev), 2.5, whiteDotPaint);
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
