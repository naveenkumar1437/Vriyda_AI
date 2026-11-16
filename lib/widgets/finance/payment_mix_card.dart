import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Payment mix (How fees are paid - Donut ring with breakdown)
class PaymentMixCard extends StatelessWidget {
  final List<PaymentMixItem> paymentMix;

  const PaymentMixCard({
    super.key,
    required this.paymentMix,
  });

  @override
  Widget build(BuildContext context) {
    final double onlinePct = paymentMix.isNotEmpty ? paymentMix.first.percentage : 0.0;

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
            'Payment mix',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'How fees are paid',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Donut Ring
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(100, 100),
                      painter: _PaymentMixDonutPainter(onlinePct: onlinePct),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${onlinePct.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const Text(
                          'ONLINE',
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
              const SizedBox(width: 20),

              // Legend
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: paymentMix.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7.5,
                                height: 7.5,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${item.percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMixDonutPainter extends CustomPainter {
  final double onlinePct;

  _PaymentMixDonutPainter({required this.onlinePct});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background track (Counter / Cheque)
    final bgPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Online arc (Purple)
    final onlinePaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (onlinePct.clamp(0.0, 100.0) / 100.0) * 2 * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      onlinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PaymentMixDonutPainter oldDelegate) =>
      oldDelegate.onlinePct != onlinePct;
}
