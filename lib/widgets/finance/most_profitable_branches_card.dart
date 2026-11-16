import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Most profitable branches (Ranked by EBITDA margin)
class MostProfitableBranchesCard extends StatelessWidget {
  final List<ProfitableBranchItem> profitableBranches;

  const MostProfitableBranchesCard({
    super.key,
    required this.profitableBranches,
  });

  @override
  Widget build(BuildContext context) {
    if (profitableBranches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No branch profitability data recorded in API.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
      );
    }

    final double maxMargin = profitableBranches.fold(
      0.0,
      (max, b) => b.ebitdaMargin > max ? b.ebitdaMargin : max,
    );
    final double safeMax = maxMargin > 0 ? maxMargin : 100.0;

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
            'Most profitable branches',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ranked by EBITDA margin',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          ...profitableBranches.map((b) {
            final double fraction = (b.ebitdaMargin / safeMax).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.5),
              child: Row(
                children: [
                  // Branch Name
                  SizedBox(
                    width: 120,
                    child: Text(
                      b.branchName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Horizontal Bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Container(
                        height: 6,
                        color: const Color(0xFFF1F5F9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: fraction,
                            child: Container(color: b.color),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Percentage Text
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${b.ebitdaMargin.toStringAsFixed(0)}%',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

