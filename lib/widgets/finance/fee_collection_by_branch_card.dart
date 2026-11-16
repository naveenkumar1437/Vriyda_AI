import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Fee collection by branch (Billed, collected & due per branch · YTD)
class FeeCollectionByBranchCard extends StatelessWidget {
  final List<BranchFeeCollectionItem> branchCollections;

  const FeeCollectionByBranchCard({
    super.key,
    required this.branchCollections,
  });

  @override
  Widget build(BuildContext context) {
    if (branchCollections.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No branch fee collection recorded in API.',
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
            'Fee collection by branch',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Billed, collected & due per branch · YTD',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          ...branchCollections.map((b) {
            final double billed = b.billed > 0 ? b.billed : 1.0;
            final double colFactor = (b.collected / billed).clamp(0.0, 1.0);
            final double dueFactor = (b.due / billed).clamp(0.0, 1.0 - colFactor);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Dot + Branch Name + Metrics
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7.5,
                            height: 7.5,
                            decoration: BoxDecoration(
                              color: b.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 130,
                            child: Text(
                              b.branchName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            FinanceKpis.formatIndianCurrency(b.billed),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            FinanceKpis.formatIndianCurrency(b.collected),
                            style: const TextStyle(
                              color: Color(0xFF0D9488), // Teal
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            FinanceKpis.formatIndianCurrency(b.due),
                            style: const TextStyle(
                              color: Color(0xFFDC2626), // Red
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${b.collectionPct.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Stacked Bar (Collected in Teal, Due in Red/Orange)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 5,
                      color: const Color(0xFFF1F5F9),
                      child: Row(
                        children: [
                          if (colFactor > 0)
                            Expanded(
                              flex: (colFactor * 1000).round(),
                              child: Container(color: const Color(0xFF0D9488)),
                            ),
                          if (dueFactor > 0)
                            Expanded(
                              flex: (dueFactor * 1000).round(),
                              child: Container(color: const Color(0xFFF97316)), // Orange
                            ),
                          if (1.0 - colFactor - dueFactor > 0)
                            Expanded(
                              flex: (((1.0 - colFactor - dueFactor) * 1000).round()),
                              child: const SizedBox.shrink(),
                            ),
                        ],
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

