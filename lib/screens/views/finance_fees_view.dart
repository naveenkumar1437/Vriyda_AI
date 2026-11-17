import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/finance_fee_models.dart';
import '../../services/finance_service.dart';
import '../../widgets/finance/expense_mix_chart.dart';
import '../../widgets/finance/expenses_kpi_grid.dart';
import '../../widgets/finance/purchase_items_table.dart';
import '../../widgets/finance/spend_by_branch_table.dart';

/// Finance & Fees Screen strictly displaying V1 Feature Matrix Page-6:
/// - Row 29: Expenses (KPIs: Total spend · YTD, Payroll · YTD, Rent · monthly, Fuel & fleet, Purchases, Staff claims)
/// - Row 30: Spend by branch, Expense mix (plus submitted purchase invoice lines)
///
/// 100% dynamic API data from GET /owner-dashboard — zero static or hardcoded fallback data.
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

  void _exportReport() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exporting $_period Expenses & Spend report for $_branch...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF7C3AED),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              const SizedBox(width: 8),

              // Branch Selector Dropdown
              PopupMenuButton<String>(
                onSelected: _changeBranch,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (ctx) => branchOptions
                    .map(
                      (b) => PopupMenuItem(
                        value: b,
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _branch == b ? FontWeight.bold : FontWeight.w500,
                            color: _branch == b ? const Color(0xFF7C3AED) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _branch,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Export Button
              InkWell(
                onTap: _exportReport,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.file_upload_outlined, size: 14, color: Color(0xFF334155)),
                      SizedBox(width: 4),
                      Text(
                        'Export',
                        style: TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
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
                text: 'Expenses ',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              TextSpan(
                text: '• $_period Total spend, payroll, rent, fuel, purchases & staff claims',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. V1 Requirement Row 29: Expenses KPIs
        // Total spend · YTD, Payroll · YTD, Rent · monthly, Fuel & fleet, Purchases, Staff claims
        ExpensesKpiGrid(
          expenses: data.expenses,
          period: _period,
        ),
        const SizedBox(height: 18),

        // 3. V1 Requirement Row 30: Spend by Branch Table
        // Academic year to date breakdown per branch with summary
        SpendByBranchTable(
          branchSpends: data.spendByBranch,
          onBranchTap: (b) {
            _changeBranch(b.branchName);
          },
        ),
        const SizedBox(height: 18),

        // 4. V1 Requirement Row 30: Expense Mix Donut Chart
        // Share of total spend donut chart with detailed legend breakdown
        ExpenseMixChart(
          categories: data.expenseMix,
          totalSpend: data.expenses.totalSpend,
        ),
        const SizedBox(height: 18),

        // 5. Items Purchased (Submitted purchase invoices lines)
        PurchaseItemsTable(
          purchases: data.purchaseItems,
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
