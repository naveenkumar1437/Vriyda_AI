import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/finance_fee_models.dart';
import '../../services/finance_service.dart';
import '../../widgets/finance/collection_rate_trend_chart.dart';
import '../../widgets/finance/expense_mix_chart.dart';
import '../../widgets/finance/expenses_kpi_grid.dart';
import '../../widgets/finance/fee_collection_by_branch_card.dart';
import '../../widgets/finance/fee_collection_card.dart';
import '../../widgets/finance/finance_metric_card.dart';
import '../../widgets/finance/most_profitable_branches_card.dart';
import '../../widgets/finance/payment_mix_card.dart';
import '../../widgets/finance/purchase_items_table.dart';
import '../../widgets/finance/revenue_expenses_chart.dart';
import '../../widgets/finance/spend_by_branch_table.dart';
import '../../widgets/finance/unit_economics_card.dart';

/// Complete Finance & Fees Screen matching the Figma visual design and Version 1 specifications.
/// Includes Primary Financial KPIs, Expenses, Revenue vs Operating Expenses, Fee Collection,
/// Aging, Collection Trend, Unit Economics, Payment Mix, Profitable Branches, Spend by Branch,
/// Expense Mix, and Purchase Invoices.
///
/// 100% dynamically loaded from the live API (GET /owner-dashboard) with zero hardcoded fallbacks.
class FinanceFeesView extends StatefulWidget {
  final Map<String, dynamic>? initialGroup;
  final List<dynamic>? initialBranches;
  final String activePeriod;
  final String selectedBranch;
  final ValueChanged<String>? onPeriodChanged;
  final ValueChanged<String>? onBranchChanged;

  const FinanceFeesView({
    super.key,
    this.initialGroup,
    this.initialBranches,
    this.activePeriod = 'YTD',
    this.selectedBranch = 'All branches',
    this.onPeriodChanged,
    this.onBranchChanged,
  });

  @override
  State<FinanceFeesView> createState() => _FinanceFeesViewState();
}

class _FinanceFeesViewState extends State<FinanceFeesView> {
  late String _period;
  late String _branch;
  bool _isLoading = false;
  String? _errorMessage;
  FinanceFeeData? _data;

  @override
  void initState() {
    super.initState();
    _period = widget.activePeriod;
    _branch = widget.selectedBranch;
    _loadFinanceData();
  }

  @override
  void didUpdateWidget(covariant FinanceFeesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePeriod != widget.activePeriod ||
        oldWidget.selectedBranch != widget.selectedBranch) {
      setState(() {
        _period = widget.activePeriod;
        _branch = widget.selectedBranch;
      });
      _loadFinanceData();
    }
  }

  Future<void> _loadFinanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FinanceService.fetchFinanceData(
        period: _period,
        branch: _branch,
      );
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load finance data: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _changePeriod(String p) {
    if (_period == p) return;
    HapticFeedback.selectionClick();
    setState(() => _period = p);
    widget.onPeriodChanged?.call(p);
    _loadFinanceData();
  }

  void _changeBranch(String b) {
    if (_branch == b) return;
    HapticFeedback.selectionClick();
    setState(() => _branch = b);
    widget.onBranchChanged?.call(b);
    _loadFinanceData();
  }

  @override
  Widget build(BuildContext context) {
    // If loading for the first time
    if (_isLoading && _data == null) {
      return Container(
        height: 320,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
        ),
      );
    }

    if (_errorMessage != null && _data == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 36),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              onPressed: _loadFinanceData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = _data!;
    final kpis = data.kpis;

    // Extract available branches dynamically from API initialBranches and spendByBranch
    final List<String> branchOptions = ['All branches'];
    if (widget.initialBranches != null) {
      for (final b in widget.initialBranches!) {
        final name = b['name']?.toString();
        if (name != null && name.isNotEmpty && !branchOptions.contains(name)) {
          branchOptions.add(name);
        }
      }
    }
    for (final b in data.spendByBranch) {
      if (b.branchName.isNotEmpty && !branchOptions.contains(b.branchName)) {
        branchOptions.add(b.branchName);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Title & Top Action Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Finance & Fees',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Controls Bar: [MTD | QTD | YTD | FY]  [All branches v]  [^ Export]
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Period Toggle Pill
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['MTD', 'QTD', 'YTD', 'FY'].map((p) {
                    final isSel = _period == p;
                    return GestureDetector(
                      onTap: () => _changePeriod(p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEDE9FE) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 4),

              // Branch Selector Dropdown (styled identically to Branch Tree screen)
              PopupMenuButton<String>(
                onSelected: _changeBranch,
                elevation: 6,
                color: Colors.white,
                surfaceTintColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                itemBuilder: (ctx) => branchOptions.map((b) {
                  final isSel = _branch == b;
                  Color dotColor;
                  if (b == 'All branches') {
                    dotColor = const Color(0xFF7C3AED);
                  } else {
                    final match = data.spendByBranch.where((s) => s.branchName == b).firstOrNull;
                    dotColor = match?.dotColor ?? const Color(0xFF10B981);
                  }

                  return PopupMenuItem<String>(
                    value: b,
                    height: 42,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                              color: isSel ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isSel)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF7C3AED),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _branch,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Subtitle
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            children: [
              const TextSpan(
                text: 'Finance & fees ',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              TextSpan(
                text: '• $_period Group P&L, unit economics, collection & receivables',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Primary 6 Financial KPI Cards (3 columns x 2 rows)
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'REVENUE · $_period',
                value: kpis.formattedRevenue,
                bottomWidget: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3.5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_drop_up_rounded, size: 12, color: Color(0xFF16A34A)),
                          Text(
                            '+${kpis.revenueDelta}%',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'vs target ${kpis.targetPercentage}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'COLLECTED',
                value: kpis.formattedCollected,
                bottomWidget: Row(
                  children: [
                    const Icon(Icons.arrow_drop_up_rounded, size: 13, color: Color(0xFF16A34A)),
                    Text(
                      '${kpis.collectedPct}%',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Flexible(
                      child: Text(
                        'of billed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'OUTSTANDING',
                value: kpis.formattedOutstanding,
                bottomWidget: Row(
                  children: [
                    const Icon(Icons.arrow_drop_down_rounded, size: 13, color: Color(0xFFDC2626)),
                    Text(
                      '${kpis.outstandingPct}%',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Flexible(
                      child: Text(
                        'receivables',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'EBITDA MARGIN',
                value: '${kpis.ebitdaMargin}%',
                subtext: 'group blended',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'PAYROLL COST',
                value: '${kpis.payrollCostPct}%',
                subtext: 'of revenue',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'ONLINE PAYMENTS',
                value: '${kpis.onlinePaymentsPct}%',
                subtext: 'Razorpay share',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. V1 Requirement Row 29: Expenses KPIs
        ExpensesKpiGrid(
          expenses: data.expenses,
          period: _period,
        ),
        const SizedBox(height: 18),

        // 4. Trailing 12 Months Revenue vs Operating Expenses Chart
        RevenueExpensesChart(
          trendSeries: data.trendSeries,
        ),
        const SizedBox(height: 18),

        // 5. Fee Collection (Billed vs collected & Receivables Aging)
        FeeCollectionCard(
          feeCollection: data.feeCollection,
          agingItems: data.receivablesAging,
        ),
        const SizedBox(height: 18),

        // 6. Collection Rate Trend Chart
        CollectionRateTrendChart(
          trendSeries: data.trendSeries,
          currentCollectionPct: data.feeCollection.collectionPct,
        ),
        const SizedBox(height: 18),

        // 7. Unit Economics
        UnitEconomicsCard(
          unitEconomics: data.unitEconomics,
        ),
        const SizedBox(height: 18),

        // 8. Payment Mix
        PaymentMixCard(
          paymentMix: data.paymentMix,
        ),
        const SizedBox(height: 18),

        // 9. Most Profitable Branches
        MostProfitableBranchesCard(
          profitableBranches: data.profitableBranches,
        ),
        const SizedBox(height: 18),

        // 10. Fee Collection by Branch
        FeeCollectionByBranchCard(
          branchCollections: data.branchFeeCollections,
        ),
        const SizedBox(height: 24),

        // 11. Expense Detail Section Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Expense detail',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Spend per branch, the mix, and every purchased line — academic year to date',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 12. V1 Requirement Row 30: Spend by Branch Table
        SpendByBranchTable(
          branchSpends: data.spendByBranch,
          onBranchTap: (b) {
            _changeBranch(b.branchName);
          },
        ),
        const SizedBox(height: 18),

        // 13. V1 Requirement Row 30: Expense Mix Donut Chart
        ExpenseMixChart(
          categories: data.expenseMix,
          totalSpend: data.expenses.totalSpend,
        ),
        const SizedBox(height: 18),

        // 14. Purchase Invoices List
        PurchaseItemsTable(
          purchases: data.purchaseItems,
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
