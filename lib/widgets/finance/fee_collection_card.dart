import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Fee Collection (Billed vs collected donut ring) + Receivables Aging stacked bar
class FeeCollectionCard extends StatelessWidget {
  final FeeCollectionData feeCollection;
  final List<ReceivablesAgingItem> agingItems;

  const FeeCollectionCard({
    super.key,
    required this.feeCollection,
    required this.agingItems,
  });

  @override
  Widget build(BuildContext context) {
    final double totalAging = agingItems.fold(0.0, (acc, item) => acc + item.amount);

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
            'Fee collection',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Billed vs collected',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Donut Ring + Legend
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _FeeCollectionDonutPainter(
                        collectedPct: feeCollection.collectionPct,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${feeCollection.collectionPct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'COLLECTED',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendRow(
                      const Color(0xFF10B981),
                      'Collected',
                      FinanceKpis.formatIndianCurrency(feeCollection.collected),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                      const Color(0xFF8B5CF6),
                      'Due (current)',
                      FinanceKpis.formatIndianCurrency(feeCollection.due),
                    ),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                      const Color(0xFFEF4444),
                      'Overdue',
                      FinanceKpis.formatIndianCurrency(feeCollection.overdue),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // RECEIVABLES AGING
          const Text(
            'RECEIVABLES AGING',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Stacked horizontal bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: totalAging > 0
                  ? Row(
                      children: agingItems.map((item) {
                        final flex = ((item.amount / totalAging) * 1000).round();
                        if (flex <= 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: flex,
                          child: Container(color: item.color),
                        );
                      }).toList(),
                    )
                  : Container(color: const Color(0xFFF1F5F9)),
            ),
          ),
          const SizedBox(height: 8),

          // Aging Legend
          if (agingItems.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: agingItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${item.bucket} ${FinanceKpis.formatIndianCurrency(item.amount)}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Text(
              'No receivables aging recorded in API.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color dotColor, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7.5,
              height: 7.5,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FeeCollectionDonutPainter extends CustomPainter {
  final double collectedPct;

  _FeeCollectionDonutPainter({required this.collectedPct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background track (Due / remaining)
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Collected arc (Emerald)
    final colPaint = Paint()
      ..color = const Color(0xFF10B981)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (collectedPct.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      colPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FeeCollectionDonutPainter oldDelegate) =>
      oldDelegate.collectedPct != collectedPct;
}
