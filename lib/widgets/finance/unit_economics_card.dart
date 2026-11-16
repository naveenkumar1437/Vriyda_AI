import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Unit economics (Per student · annual breakdown)
class UnitEconomicsCard extends StatelessWidget {
  final UnitEconomicsData unitEconomics;

  const UnitEconomicsCard({
    super.key,
    required this.unitEconomics,
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal = unitEconomics.revPerStudent > 0 ? unitEconomics.revPerStudent : 1.0;
    final double revPct = 1.0;
    final double costPct = (unitEconomics.costPerStudent / maxVal).clamp(0.0, 1.0);

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
            'Unit economics',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Per student · annual',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          // Revenue / student
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue / student',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                FinanceKpis.formatIndianCurrency(unitEconomics.revPerStudent),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: revPct,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            ),
          ),
          const SizedBox(height: 12),

          // Cost / student
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cost / student',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                FinanceKpis.formatIndianCurrency(unitEconomics.costPerStudent),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: costPct,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 14),

          // Contribution & Margin Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Contribution / student',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                FinanceKpis.formatIndianCurrency(unitEconomics.contributionPerStudent),
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'EBITDA margin',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${unitEconomics.ebitdaMargin.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
