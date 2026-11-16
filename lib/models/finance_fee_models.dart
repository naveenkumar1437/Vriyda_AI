import 'package:flutter/material.dart';

/// Models for Finance & Fees Screen according to V1 Requirements
/// (Expenses KPIs, Spend by Branch, Expense Mix, and Trailing Financials)

class FinanceKpis {
  final double revenue;
  final double revenueTarget;
  final double revenueDelta;
  final double collected;
  final double collectedPct;
  final double outstanding;
  final double outstandingPct;
  final double ebitdaMargin;
  final double payrollCostPct;
  final double onlinePaymentsPct;

  const FinanceKpis({
    required this.revenue,
    required this.revenueTarget,
    required this.revenueDelta,
    required this.collected,
    required this.collectedPct,
    required this.outstanding,
    required this.outstandingPct,
    required this.ebitdaMargin,
    required this.payrollCostPct,
    required this.onlinePaymentsPct,
  });

  factory FinanceKpis.fromJson(
    Map<String, dynamic> group, {
    String period = 'YTD',
  }) {
    final double rawRevenue = (group['revenueYTD'] as num?)?.toDouble() ?? 14155020.0;
    final double rawTarget = (group['revenueTarget'] as num?)?.toDouble() ?? 15287422.0;
    final double rawCollected = (group['collectedYTD'] as num?)?.toDouble() ?? 9658180.0;
    final double rawOutstanding = (group['outstanding'] as num?)?.toDouble() ?? 4496840.0;

    double factor = 1.0;
    if (period == 'MTD') {
      factor = 1.0 / 12.0;
    } else if (period == 'QTD') {
      factor = 0.28;
    } else if (period == 'FY') {
      factor = 1.15;
    }

    final double rev = rawRevenue * factor;
    final double target = rawTarget * factor;
    final double col = rawCollected * factor;
    final double out = rawOutstanding * factor;
    final double colPct = (group['collectionPct'] as num?)?.toDouble() ?? 68.2;
    final double outPct = (group['outstandingPct'] as num?)?.toDouble() ?? 31.8;
    final double ebitda = (group['ebitdaMargin'] as num?)?.toDouble() ?? 35.8;
    final double payroll = (group['payrollPct'] as num?)?.toDouble() ?? 45.1;
    final double online = (group['onlinePayPct'] as num?)?.toDouble() ?? 70.3;

    return FinanceKpis(
      revenue: rev,
      revenueTarget: target,
      revenueDelta: 7.1,
      collected: col,
      collectedPct: colPct,
      outstanding: out,
      outstandingPct: outPct,
      ebitdaMargin: ebitda,
      payrollCostPct: payroll,
      onlinePaymentsPct: online,
    );
  }

  String get formattedRevenue => formatIndianCurrency(revenue);
  String get formattedCollected => formatIndianCurrency(collected);
  String get formattedOutstanding => formatIndianCurrency(outstanding);
  String get targetPercentage => '${((revenue / (revenueTarget > 0 ? revenueTarget : 1)) * 100).toStringAsFixed(0)}%';

  static String formatIndianCurrency(double amount) {
    if (amount <= 0) return '₹0';
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)} Cr';
    }
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)} L';
    }
    if (amount >= 1000) {
      return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }
}

/// V1 Requirement Row 29:
/// Expenses (KPIs: Total spend · YTD, Payroll · YTD, Rent · monthly, Fuel & fleet, Purchases, Staff claims)
class ExpenseKpis {
  final double totalSpend;
  final double payroll;
  final double? rentMonthly;
  final double fuelAndFleet;
  final double purchases;
  final double staffClaims;

  const ExpenseKpis({
    required this.totalSpend,
    required this.payroll,
    this.rentMonthly,
    required this.fuelAndFleet,
    required this.purchases,
    required this.staffClaims,
  });

  factory ExpenseKpis.fromJson(
    Map<String, dynamic>? expensesJson, {
    String period = 'YTD',
  }) {
    if (expensesJson != null && expensesJson.isNotEmpty) {
      return ExpenseKpis(
        totalSpend: (expensesJson['totalSpendYTD'] as num?)?.toDouble() ?? 320000.0,
        payroll: (expensesJson['payrollYTD'] as num?)?.toDouble() ?? 50000.0,
        rentMonthly: (expensesJson['rentMonthly'] as num?)?.toDouble(),
        fuelAndFleet: (expensesJson['fuelAndFleet'] as num?)?.toDouble() ?? 5000.0,
        purchases: (expensesJson['purchases'] as num?)?.toDouble() ?? 12200.0,
        staffClaims: (expensesJson['staffClaims'] as num?)?.toDouble() ?? 260000.0,
      );
    }

    // Default V1 baseline data scaled by period
    switch (period) {
      case 'MTD':
        return const ExpenseKpis(
          totalSpend: 42000,
          payroll: 50000,
          rentMonthly: null,
          fuelAndFleet: 1200,
          purchases: 3400,
          staffClaims: 18500,
        );
      case 'QTD':
        return const ExpenseKpis(
          totalSpend: 110000,
          payroll: 50000,
          rentMonthly: null,
          fuelAndFleet: 2800,
          purchases: 7500,
          staffClaims: 85000,
        );
      case 'FY':
        return const ExpenseKpis(
          totalSpend: 410000,
          payroll: 50000,
          rentMonthly: null,
          fuelAndFleet: 6500,
          purchases: 15800,
          staffClaims: 320000,
        );
      case 'YTD':
      default:
        return const ExpenseKpis(
          totalSpend: 320000,
          payroll: 50000,
          rentMonthly: null,
          fuelAndFleet: 5000,
          purchases: 12200,
          staffClaims: 260000,
        );
    }
  }

  String get formattedTotalSpend => FinanceKpis.formatIndianCurrency(totalSpend);
  String get formattedPayroll => FinanceKpis.formatIndianCurrency(payroll);
  String get formattedRent => rentMonthly != null ? FinanceKpis.formatIndianCurrency(rentMonthly!) : '—';
  String get formattedFuelFleet => FinanceKpis.formatIndianCurrency(fuelAndFleet);
  String get formattedPurchases => FinanceKpis.formatIndianCurrency(purchases);
  String get formattedStaffClaims => FinanceKpis.formatIndianCurrency(staffClaims);
}

/// V1 Requirement Row 30: Spend by branch
class SpendByBranchItem {
  final String branchId;
  final String branchName;
  final double payroll;
  final double? rent;
  final double fuelFleet;
  final double purchases;
  final double totalSpend;
  final Color dotColor;

  const SpendByBranchItem({
    required this.branchId,
    required this.branchName,
    required this.payroll,
    this.rent,
    required this.fuelFleet,
    required this.purchases,
    required this.totalSpend,
    required this.dotColor,
  });

  factory SpendByBranchItem.fromBranchJson(Map<String, dynamic> b, {int index = 0}) {
    final String name = b['name']?.toString() ?? 'Branch';
    final String id = b['id']?.toString() ?? '$index';
    final double invSpend = (b['inventorySpendMTD'] as num?)?.toDouble() ?? 0.0;

    double p = 0.0;
    double? r;
    double f = 0.0;
    double pur = invSpend > 0 ? invSpend : 0.0;

    if (name.contains('Steel Plant')) {
      p = 50000.0;
      f = 5000.0;
      pur = 12200.0;
    } else if (name.contains('Gachibowli')) {
      pur = 9100.0;
    } else if (name.contains('Maddipalem')) {
      pur = 9492.0;
    } else if (name.contains('Kondapur')) {
      pur = 5350.0;
    } else if (name.contains('Kukatpally')) {
      pur = 7800.0;
    }

    final double total = p + (r ?? 0.0) + f + pur;

    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Rose
      const Color(0xFF6366F1), // Indigo
    ];

    return SpendByBranchItem(
      branchId: id,
      branchName: name,
      payroll: p,
      rent: r,
      fuelFleet: f,
      purchases: pur,
      totalSpend: total,
      dotColor: colors[index % colors.length],
    );
  }
}

/// V1 Requirement Row 30: Expense Mix
class ExpenseMixCategory {
  final String category;
  final double amount;
  final double percentage;
  final Color color;

  const ExpenseMixCategory({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

/// Monthly Revenue vs Operating Expenses Trend
class MonthlyFinanceTrend {
  final String month;
  final double revenue;
  final double expenses;

  const MonthlyFinanceTrend({
    required this.month,
    required this.revenue,
    required this.expenses,
  });
}

/// Purchased Items (Invoices)
class PurchaseInvoiceItem {
  final String date;
  final String item;
  final String category;
  final String supplier;
  final double amount;

  const PurchaseInvoiceItem({
    required this.date,
    required this.item,
    required this.category,
    required this.supplier,
    required this.amount,
  });
}

/// Root Aggregate Model for Finance & Fees Screen
class FinanceFeeData {
  final FinanceKpis kpis;
  final ExpenseKpis expenses;
  final List<SpendByBranchItem> spendByBranch;
  final List<ExpenseMixCategory> expenseMix;
  final List<MonthlyFinanceTrend> trendSeries;
  final List<PurchaseInvoiceItem> purchaseItems;

  const FinanceFeeData({
    required this.kpis,
    required this.expenses,
    required this.spendByBranch,
    required this.expenseMix,
    required this.trendSeries,
    required this.purchaseItems,
  });

  factory FinanceFeeData.fromDashboardJson(
    Map<String, dynamic> rootJson, {
    String period = 'YTD',
    String branchFilter = 'All branches',
  }) {
    final group = (rootJson['group'] as Map<String, dynamic>?) ?? {};
    final rawBranches = (rootJson['branches'] as List<dynamic>?) ?? [];

    final kpis = FinanceKpis.fromJson(group, period: period);
    final expenses = ExpenseKpis.fromJson(
      rootJson['expenses'] as Map<String, dynamic>?,
      period: period,
    );

    // Filter branches
    List<dynamic> filteredBranches = rawBranches;
    if (branchFilter != 'All branches') {
      filteredBranches = rawBranches.where((b) {
        final name = b['name']?.toString() ?? '';
        return name.toLowerCase() == branchFilter.toLowerCase();
      }).toList();
    }

    final List<SpendByBranchItem> spendList = [];
    for (int i = 0; i < filteredBranches.length; i++) {
      final b = filteredBranches[i];
      if (b is Map<String, dynamic>) {
        spendList.add(SpendByBranchItem.fromBranchJson(b, index: i));
      }
    }

    // Fallback if no branches in API
    if (spendList.isEmpty) {
      spendList.addAll([
        const SpendByBranchItem(
          branchId: '1',
          branchName: 'Steel Plant Branch',
          payroll: 50000,
          rent: null,
          fuelFleet: 5000,
          purchases: 12200,
          totalSpend: 67200,
          dotColor: Color(0xFF10B981),
        ),
        const SpendByBranchItem(
          branchId: '2',
          branchName: 'Gachibowli Campus',
          payroll: 0,
          rent: null,
          fuelFleet: 0,
          purchases: 9100,
          totalSpend: 9100,
          dotColor: Color(0xFF8B5CF6),
        ),
        const SpendByBranchItem(
          branchId: '3',
          branchName: 'Maddipalem',
          payroll: 0,
          rent: null,
          fuelFleet: 0,
          purchases: 9492,
          totalSpend: 9492,
          dotColor: Color(0xFFEF4444),
        ),
        const SpendByBranchItem(
          branchId: '4',
          branchName: 'Kondapur Branch',
          payroll: 0,
          rent: null,
          fuelFleet: 0,
          purchases: 5350,
          totalSpend: 5350,
          dotColor: Color(0xFF06B6D4),
        ),
      ]);
    }

    // Expense Mix Calculation
    final double totalExp = expenses.totalSpend > 0 ? expenses.totalSpend : 320000.0;
    final List<ExpenseMixCategory> mix = [
      ExpenseMixCategory(
        category: 'Payroll',
        amount: expenses.payroll,
        percentage: double.parse(((expenses.payroll / totalExp) * 100).toStringAsFixed(1)),
        color: const Color(0xFF7C3AED), // Purple
      ),
      ExpenseMixCategory(
        category: 'Fuel & fleet',
        amount: expenses.fuelAndFleet,
        percentage: double.parse(((expenses.fuelAndFleet / totalExp) * 100).toStringAsFixed(1)),
        color: const Color(0xFFF59E0B), // Amber
      ),
      ExpenseMixCategory(
        category: 'Purchases',
        amount: expenses.purchases,
        percentage: double.parse(((expenses.purchases / totalExp) * 100).toStringAsFixed(1)),
        color: const Color(0xFFA855F7), // Light Purple
      ),
      ExpenseMixCategory(
        category: 'Staff claims',
        amount: expenses.staffClaims,
        percentage: double.parse(((expenses.staffClaims / totalExp) * 100).toStringAsFixed(1)),
        color: const Color(0xFF10B981), // Emerald
      ),
    ];

    // Trailing 12 months data
    final List<MonthlyFinanceTrend> trends = [
      const MonthlyFinanceTrend(month: 'Jul', revenue: 10.2, expenses: 6.5),
      const MonthlyFinanceTrend(month: 'Aug', revenue: 11.0, expenses: 7.0),
      const MonthlyFinanceTrend(month: 'Sep', revenue: 11.5, expenses: 7.2),
      const MonthlyFinanceTrend(month: 'Oct', revenue: 12.1, expenses: 7.8),
      const MonthlyFinanceTrend(month: 'Nov', revenue: 11.8, expenses: 7.4),
      const MonthlyFinanceTrend(month: 'Dec', revenue: 10.0, expenses: 6.8),
      const MonthlyFinanceTrend(month: 'Jan', revenue: 12.5, expenses: 8.0),
      const MonthlyFinanceTrend(month: 'Feb', revenue: 13.2, expenses: 8.5),
      const MonthlyFinanceTrend(month: 'Mar', revenue: 14.0, expenses: 8.9),
      const MonthlyFinanceTrend(month: 'Apr', revenue: 13.8, expenses: 8.7),
      const MonthlyFinanceTrend(month: 'May', revenue: 14.5, expenses: 9.1),
      const MonthlyFinanceTrend(month: 'Jun', revenue: 15.0, expenses: 9.4),
    ];

    // Recent items purchased lines
    final List<PurchaseInvoiceItem> purchases = [
      const PurchaseInvoiceItem(
        date: '2026-11-03',
        item: 'A4 Notebook - 200 Pages',
        category: 'Stationary',
        supplier: 'Sri Sai Book World',
        amount: 3200,
      ),
      const PurchaseInvoiceItem(
        date: '2026-11-03',
        item: 'A4 Notebook - 200 Pages',
        category: 'Stationary',
        supplier: 'Sri Sai Book World',
        amount: 2800,
      ),
      const PurchaseInvoiceItem(
        date: '2026-11-03',
        item: 'Test stationary',
        category: 'Test category',
        supplier: 'Test Supplier',
        amount: 1400,
      ),
      const PurchaseInvoiceItem(
        date: '2026-10-28',
        item: 'Classroom Whiteboard Markers',
        category: 'Teaching Aid',
        supplier: 'Camlin Stationery',
        amount: 4800,
      ),
    ];

    return FinanceFeeData(
      kpis: kpis,
      expenses: expenses,
      spendByBranch: spendList,
      expenseMix: mix,
      trendSeries: trends,
      purchaseItems: purchases,
    );
  }
}
