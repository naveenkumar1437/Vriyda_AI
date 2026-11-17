import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';

/// Implements V1 Requirements (Row 30):
/// Spend by branch (academic year to date breakdown per branch with summary)
class SpendByBranchTable extends StatelessWidget {
  final List<SpendByBranchItem> branchSpends;
  final ValueChanged<SpendByBranchItem>? onBranchTap;

  const SpendByBranchTable({
    super.key,
    required this.branchSpends,
    this.onBranchTap,
  });

  @override
  Widget build(BuildContext context) {
    double totalPayroll = 0;
    double totalRent = 0;
    double totalFuel = 0;

    for (final b in branchSpends) {
      totalPayroll += b.payroll;
      totalRent += b.rent ?? 0;
      totalFuel += b.fuelFleet;
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
            'Spend by branch',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Academic year to date · click a row for that branch\'s purchases',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),

          if (branchSpends.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No branch spend recorded in API.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                ),
              ),
            )
          else
            // Horizontal scrollable table container
            SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: 440,
              child: Column(
                children: [
                  // Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                      ),
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 170,
                          child: Text(
                            'BRANCH',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            'PAYROLL',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            'RENT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'FUEL & FLEET',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Branch Rows
                  ...branchSpends.map((b) {
                    return InkWell(
                      onTap: () => onBranchTap?.call(b),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 170,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: b.dotColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      b.branchName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 85,
                              child: Text(
                                b.payroll > 0 ? FinanceKpis.formatIndianCurrency(b.payroll) : '—',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 85,
                              child: Text(
                                b.rent != null && b.rent! > 0 ? FinanceKpis.formatIndianCurrency(b.rent!) : '—',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                b.fuelFleet > 0 ? FinanceKpis.formatIndianCurrency(b.fuelFleet) : '—',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  color: Color(0xFF334155),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  // All Branches Total Summary Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 170,
                          child: Text(
                            'All branches',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            FinanceKpis.formatIndianCurrency(totalPayroll),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 85,
                          child: Text(
                            totalRent > 0 ? FinanceKpis.formatIndianCurrency(totalRent) : '—',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            totalFuel > 0 ? FinanceKpis.formatIndianCurrency(totalFuel) : '—',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
