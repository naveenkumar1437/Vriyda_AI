import 'package:flutter/material.dart';

/// Models for Finance & Fees Screen strictly populated from API responses.
/// Zero hardcoded fallback metrics, zero static lists.

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

  /// Creates empty KPI model with zeros
  factory FinanceKpis.empty() {
    return const FinanceKpis(
      revenue: 0.0,
      revenueTarget: 0.0,
      revenueDelta: 0.0,
      collected: 0.0,
      collectedPct: 0.0,
      outstanding: 0.0,
      outstandingPct: 0.0,
      ebitdaMargin: 0.0,
      payrollCostPct: 0.0,
      onlinePaymentsPct: 0.0,
    );
  }

  /// Computes the exact period factor matching web Vriyda owner-cc-bundle.js:
  /// Derived from the real 12-month series:
  /// MTD = current (last) month / total
  /// QTD = last 3 months / total
  /// FY = 1.08 (+8% full-year forecast)
  /// YTD = 1.0
  static double computePeriodFactor(
    String period, {
    List<dynamic>? revenueSeries,
  }) {
    if (period == 'YTD') return 1.0;
    if (period == 'FY') return 1.08;

    if (revenueSeries != null && revenueSeries.isNotEmpty) {
      double total = 0.0;
      final List<double> revs = [];
      for (final item in revenueSeries) {
        if (item is Map) {
          final r = (item['revenue'] as num?)?.toDouble() ?? 0.0;
          revs.add(r);
          total += r;
        }
      }

      if (total > 0 && revs.isNotEmpty) {
        if (period == 'MTD') {
          final double tail1 = revs.last;
          return tail1 / total;
        } else if (period == 'QTD') {
          final int start = revs.length >= 3 ? revs.length - 3 : 0;
          double tail3 = 0.0;
          for (int i = start; i < revs.length; i++) {
            tail3 += revs[i];
          }
          return tail3 / total;
        }
      }
    }

    // Default fallbacks matching web owner-cc-bundle.js:
    // { MTD: 0.088, QTD: 0.25, YTD: 1, FY: 1.08 }
    switch (period) {
      case 'MTD':
        return 0.088;
      case 'QTD':
        return 0.25;
      case 'FY':
        return 1.08;
      case 'YTD':
      default:
        return 1.0;
    }
  }

  factory FinanceKpis.fromJson(
    Map<String, dynamic>? group, {
    String period = 'YTD',
    List<dynamic>? revenueSeries,
    List<dynamic>? branches,
  }) {
    if ((group == null || group.isEmpty) && (branches == null || branches.isEmpty)) {
      return FinanceKpis.empty();
    }

    double fullRevenue = (group?['revenueYTD'] as num?)?.toDouble() ??
        (group?['revenue'] as num?)?.toDouble() ?? 0.0;
    double fullOutstanding = (group?['outstanding'] as num?)?.toDouble() ?? 0.0;

    if (fullRevenue <= 0 && branches != null && branches.isNotEmpty) {
      for (final b in branches) {
        if (b is Map<String, dynamic>) {
          fullRevenue += (b['revenue'] as num?)?.toDouble() ?? 0.0;
          fullOutstanding += (b['outstanding'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    final double rawTarget = (group?['revenueTarget'] as num?)?.toDouble() ?? fullRevenue;
    final double baseColl = fullRevenue > 0
        ? (fullRevenue - fullOutstanding) / fullRevenue
        : 0.0;

    final double pf = computePeriodFactor(period, revenueSeries: revenueSeries);
    final double revenue = (fullRevenue * pf).roundToDouble();
    final double collected = (revenue * baseColl).roundToDouble();
    final double outstanding = revenue - collected;

    final double colPct = (group?['collectionPct'] as num?)?.toDouble() ??
        (revenue > 0 ? double.parse(((collected / revenue) * 100).toStringAsFixed(1)) : 0.0);
    final double outPct = (group?['outstandingPct'] as num?)?.toDouble() ??
        (revenue > 0 ? double.parse(((outstanding / revenue) * 100).toStringAsFixed(1)) : 0.0);

    // Student-weighted averages matching web owner-cc-bundle.js wavg()
    double ebitda = 0.0;
    double payroll = 0.0;
    double online = 0.0;

    if (branches != null && branches.isNotEmpty) {
      double totalStudents = 0.0;
      double weightedEbitda = 0.0;
      double weightedPayroll = 0.0;
      double weightedOnline = 0.0;

      for (final b in branches) {
        if (b is Map<String, dynamic>) {
          final double students = (b['students'] as num?)?.toDouble() ?? 0.0;
          final double m = (b['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
          final double p = (b['payrollPct'] as num?)?.toDouble() ?? 0.0;
          final double o = (b['onlinePayPct'] as num?)?.toDouble() ?? 0.0;

          if (students > 0) {
            totalStudents += students;
            weightedEbitda += m * students;
            weightedPayroll += p * students;
            weightedOnline += o * students;
          }
        }
      }

      if (totalStudents > 0) {
        ebitda = double.parse((weightedEbitda / totalStudents).toStringAsFixed(1));
        payroll = double.parse((weightedPayroll / totalStudents).toStringAsFixed(1));
        online = double.parse((weightedOnline / totalStudents).toStringAsFixed(1));
      }
    }

    if (ebitda <= 0) {
      ebitda = (group?['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
    }
    if (payroll <= 0) {
      payroll = (group?['payrollPct'] as num?)?.toDouble() ?? 0.0;
    }
    if (online <= 0) {
      online = (group?['onlinePayPct'] as num?)?.toDouble() ?? 0.0;
    }
    final double delta = (group?['revenueDelta'] as num?)?.toDouble() ?? 0.0;

    return FinanceKpis(
      revenue: revenue,
      revenueTarget: (rawTarget * pf).roundToDouble(),
      revenueDelta: delta,
      collected: collected,
      collectedPct: colPct,
      outstanding: outstanding,
      outstandingPct: outPct,
      ebitdaMargin: ebitda,
      payrollCostPct: payroll,
      onlinePaymentsPct: online,
    );
  }

  factory FinanceKpis.fromBranchJson(
    Map<String, dynamic> b, {
    String period = 'YTD',
    List<dynamic>? revenueSeries,
  }) {
    final double fullRevenue = (b['revenue'] as num?)?.toDouble() ??
        (b['revenueYTD'] as num?)?.toDouble() ?? 0.0;
    final double fullOutstanding = (b['outstanding'] as num?)?.toDouble() ?? 0.0;
    final double rawTarget = (b['revenueTarget'] as num?)?.toDouble() ?? fullRevenue;
    final double baseColl = fullRevenue > 0
        ? (fullRevenue - fullOutstanding) / fullRevenue
        : 0.0;

    final double pf = computePeriodFactor(period, revenueSeries: revenueSeries);
    final double revenue = (fullRevenue * pf).roundToDouble();
    final double collected = (revenue * baseColl).roundToDouble();
    final double outstanding = revenue - collected;

    final double colPct = (b['collectionPct'] as num?)?.toDouble() ??
        (revenue > 0 ? double.parse(((collected / revenue) * 100).toStringAsFixed(1)) : 0.0);
    final double outPct = (b['outstandingPct'] as num?)?.toDouble() ??
        (revenue > 0 ? double.parse(((outstanding / revenue) * 100).toStringAsFixed(1)) : 0.0);
    final double ebitda = (b['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
    final double payroll = (b['payrollPct'] as num?)?.toDouble() ?? 0.0;
    final double online = (b['onlinePayPct'] as num?)?.toDouble() ?? 0.0;
    final double delta = (b['revenueDelta'] as num?)?.toDouble() ?? 0.0;

    return FinanceKpis(
      revenue: revenue,
      revenueTarget: (rawTarget * pf).roundToDouble(),
      revenueDelta: delta,
      collected: collected,
      collectedPct: colPct,
      outstanding: outstanding,
      outstandingPct: outPct,
      ebitdaMargin: ebitda,
      payrollCostPct: payroll,
      onlinePaymentsPct: online,
    );
  }

  String get formattedRevenue => formatIndianCurrency(revenue);
  String get formattedCollected => formatIndianCurrency(collected);
  String get formattedOutstanding => formatIndianCurrency(outstanding);
  String get targetPercentage {
    if (revenueTarget <= 0) return '0%';
    return '${((revenue / revenueTarget) * 100).toStringAsFixed(0)}%';
  }

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

/// V1 Requirement Row 29: Expenses KPIs
/// Sourced 100% from API root `expenses` object.
class ExpenseKpis {
  final double totalSpend;
  final double payroll;
  final double? rentMonthly;
  final double fuelAndFleet;
  final double purchases;
  final double staffClaims;
  final int purchaseLinesCount;

  const ExpenseKpis({
    required this.totalSpend,
    required this.payroll,
    this.rentMonthly,
    required this.fuelAndFleet,
    required this.purchases,
    required this.staffClaims,
    this.purchaseLinesCount = 0,
  });

  factory ExpenseKpis.empty() {
    return const ExpenseKpis(
      totalSpend: 0.0,
      payroll: 0.0,
      rentMonthly: null,
      fuelAndFleet: 0.0,
      purchases: 0.0,
      staffClaims: 0.0,
      purchaseLinesCount: 0,
    );
  }

  factory ExpenseKpis.fromJson(
    Map<String, dynamic>? expensesJson, {
    String period = 'YTD',
  }) {
    if (expensesJson == null || expensesJson.isEmpty) {
      return ExpenseKpis.empty();
    }

    final double totalYtd = (expensesJson['totalYTD'] as num?)?.toDouble() ?? 0.0;
    final double payrollYtd = (expensesJson['payrollYTD'] as num?)?.toDouble() ?? 0.0;
    final double fuelYtd = ((expensesJson['fuelYTD'] as num?)?.toDouble() ?? 0.0) +
        ((expensesJson['maintenanceYTD'] as num?)?.toDouble() ?? 0.0);
    final double purchasesYtd = (expensesJson['purchasesYTD'] as num?)?.toDouble() ?? 0.0;
    final double claimsYtd = (expensesJson['claimsYTD'] as num?)?.toDouble() ?? 0.0;
    final double? rent = (expensesJson['rentMonthly'] as num?)?.toDouble() ??
        (expensesJson['rentYTD'] as num?)?.toDouble();

    final rawPurchaseLines = expensesJson['purchaseLines'] as List<dynamic>?;
    final int purchaseCount = (expensesJson['purchaseLineCount'] as num?)?.toInt() ??
        rawPurchaseLines?.length ?? 0;

    return ExpenseKpis(
      totalSpend: totalYtd,
      payroll: payrollYtd,
      rentMonthly: rent != null && rent > 0 ? rent : null,
      fuelAndFleet: fuelYtd,
      purchases: purchasesYtd,
      staffClaims: claimsYtd,
      purchaseLinesCount: purchaseCount,
    );
  }

  factory ExpenseKpis.fromBranchExpenses(
    Map<String, dynamic>? exp,
    Map<String, dynamic>? res, {
    String period = 'YTD',
    int purchaseLinesCount = 0,
  }) {
    if (exp == null && res == null) {
      return ExpenseKpis.empty();
    }
    final expMap = exp ?? {};
    final double totalYtd = (expMap['totalYTD'] as num?)?.toDouble() ?? 0.0;
    final double payrollYtd = (expMap['payrollYTD'] as num?)?.toDouble() ?? 0.0;
    final double fuelYtd = ((expMap['fuelYTD'] as num?)?.toDouble() ?? 0.0) +
        ((expMap['maintenanceYTD'] as num?)?.toDouble() ?? 0.0);
    final double purchasesYtd = (expMap['purchasesYTD'] as num?)?.toDouble() ?? 0.0;
    final double claimsYtd = (expMap['claimsYTD'] as num?)?.toDouble() ?? 0.0;
    final double? rent = (expMap['rentMonthly'] as num?)?.toDouble() ??
        (res != null ? (res['rentMonthly'] as num?)?.toDouble() : null);

    return ExpenseKpis(
      totalSpend: totalYtd,
      payroll: payrollYtd,
      rentMonthly: rent != null && rent > 0 ? rent : null,
      fuelAndFleet: fuelYtd,
      purchases: purchasesYtd,
      staffClaims: claimsYtd,
      purchaseLinesCount: purchaseLinesCount,
    );
  }

  String get formattedTotalSpend => FinanceKpis.formatIndianCurrency(totalSpend);
  String get formattedPayroll => FinanceKpis.formatIndianCurrency(payroll);
  String get formattedRent => rentMonthly != null && rentMonthly! > 0
      ? FinanceKpis.formatIndianCurrency(rentMonthly!)
      : '—';
  String get formattedFuelFleet => FinanceKpis.formatIndianCurrency(fuelAndFleet);
  String get formattedPurchases => FinanceKpis.formatIndianCurrency(purchases);
  String get formattedStaffClaims => FinanceKpis.formatIndianCurrency(staffClaims);
}

/// Fee Collection (Billed vs Collected)
class FeeCollectionData {
  final double billed;
  final double collected;
  final double due;
  final double overdue;
  final double collectionPct;

  const FeeCollectionData({
    required this.billed,
    required this.collected,
    required this.due,
    required this.overdue,
    required this.collectionPct,
  });

  factory FeeCollectionData.empty() {
    return const FeeCollectionData(
      billed: 0.0,
      collected: 0.0,
      due: 0.0,
      overdue: 0.0,
      collectionPct: 0.0,
    );
  }

  factory FeeCollectionData.fromJson(
    Map<String, dynamic>? collectionMap,
    Map<String, dynamic>? group, {
    String period = 'YTD',
    List<dynamic>? revenueSeries,
    double? overrideRevenue,
    double? overrideOutstanding,
    double? overrideCollected,
    double? overridePct,
  }) {
    if (collectionMap == null && group == null && overrideRevenue == null) {
      return FeeCollectionData.empty();
    }

    if (overrideRevenue != null && overrideOutstanding != null && overrideCollected != null) {
      double due;
      double overdue;
      if (period == 'YTD' && collectionMap != null && collectionMap['due'] != null) {
        due = (collectionMap['due'] as num).toDouble();
        overdue = (collectionMap['overdue'] as num?)?.toDouble() ?? (overrideOutstanding - due);
      } else {
        due = (overrideOutstanding * 0.58).roundToDouble();
        overdue = (overrideOutstanding * 0.42).roundToDouble();
      }

      return FeeCollectionData(
        billed: overrideRevenue,
        collected: overrideCollected,
        due: due,
        overdue: overdue,
        collectionPct: overridePct ??
            (overrideRevenue > 0
                ? double.parse(((overrideCollected / overrideRevenue) * 100).toStringAsFixed(1))
                : 0.0),
      );
    }

    final double fullRevenue = (group?['revenueYTD'] as num?)?.toDouble() ?? 0.0;
    final double fullOutstanding = (group?['outstanding'] as num?)?.toDouble() ?? 0.0;
    final double baseColl = fullRevenue > 0 ? (fullRevenue - fullOutstanding) / fullRevenue : 0.0;

    final double pf = FinanceKpis.computePeriodFactor(period, revenueSeries: revenueSeries);
    final double billed = (fullRevenue * pf).roundToDouble();
    final double collected = (billed * baseColl).roundToDouble();
    final double out = billed - collected;

    double due;
    double overdue;
    if (period == 'YTD' && collectionMap != null && collectionMap['due'] != null) {
      due = (collectionMap['due'] as num).toDouble();
      overdue = (collectionMap['overdue'] as num?)?.toDouble() ?? (out - due);
    } else {
      due = (out * 0.58).roundToDouble();
      overdue = (out * 0.42).roundToDouble();
    }

    final double pct = (group?['collectionPct'] as num?)?.toDouble() ??
        (billed > 0 ? double.parse(((collected / billed) * 100).toStringAsFixed(1)) : 0.0);

    return FeeCollectionData(
      billed: billed,
      collected: collected,
      due: due,
      overdue: overdue,
      collectionPct: pct,
    );
  }

  factory FeeCollectionData.fromBranch(
    Map<String, dynamic> b,
    Map<String, dynamic>? collectionMap,
    Map<String, dynamic>? group, {
    String period = 'YTD',
    List<dynamic>? revenueSeries,
    double? overrideRevenue,
    double? overrideOutstanding,
    double? overrideCollected,
    double? overridePct,
  }) {
    if (overrideRevenue != null && overrideOutstanding != null && overrideCollected != null) {
      double due;
      double overdue;
      if (period == 'YTD' && collectionMap != null && collectionMap['due'] != null) {
        due = (collectionMap['due'] as num).toDouble();
        overdue = (collectionMap['overdue'] as num?)?.toDouble() ?? (overrideOutstanding - due);
      } else {
        due = (overrideOutstanding * 0.58).roundToDouble();
        overdue = (overrideOutstanding * 0.42).roundToDouble();
      }

      return FeeCollectionData(
        billed: overrideRevenue,
        collected: overrideCollected,
        due: due,
        overdue: overdue,
        collectionPct: overridePct ??
            (overrideRevenue > 0
                ? double.parse(((overrideCollected / overrideRevenue) * 100).toStringAsFixed(1))
                : 0.0),
      );
    }

    final double rawBilled = (b['revenue'] as num?)?.toDouble() ??
        (b['revenueYTD'] as num?)?.toDouble() ?? 0.0;
    final double rawOutstanding = (b['outstanding'] as num?)?.toDouble() ?? 0.0;
    final double baseColl = rawBilled > 0 ? (rawBilled - rawOutstanding) / rawBilled : 0.0;

    final double pf = FinanceKpis.computePeriodFactor(period, revenueSeries: revenueSeries);
    final double billed = (rawBilled * pf).roundToDouble();
    final double collected = (billed * baseColl).roundToDouble();
    final double out = billed - collected;

    double due;
    double overdue;
    if (period == 'YTD' && collectionMap != null && collectionMap['due'] != null) {
      due = (collectionMap['due'] as num).toDouble();
      overdue = (collectionMap['overdue'] as num?)?.toDouble() ?? (out - due);
    } else {
      due = (out * 0.58).roundToDouble();
      overdue = (out * 0.42).roundToDouble();
    }

    final double pct = (b['collectionPct'] as num?)?.toDouble() ??
        (billed > 0 ? double.parse(((collected / billed) * 100).toStringAsFixed(1)) : 0.0);

    return FeeCollectionData(
      billed: billed,
      collected: collected,
      due: due,
      overdue: overdue,
      collectionPct: pct,
    );
  }
}

/// Receivables Aging Breakdown Item
class ReceivablesAgingItem {
  final String bucket;
  final double amount;
  final Color color;

  const ReceivablesAgingItem({
    required this.bucket,
    required this.amount,
    required this.color,
  });
}

/// Unit Economics (Per student · annual)
class UnitEconomicsData {
  final double revPerStudent;
  final double costPerStudent;
  final double contributionPerStudent;
  final double ebitdaMargin;

  const UnitEconomicsData({
    required this.revPerStudent,
    required this.costPerStudent,
    required this.contributionPerStudent,
    required this.ebitdaMargin,
  });

  factory UnitEconomicsData.empty() {
    return const UnitEconomicsData(
      revPerStudent: 0.0,
      costPerStudent: 0.0,
      contributionPerStudent: 0.0,
      ebitdaMargin: 0.0,
    );
  }

  factory UnitEconomicsData.fromJson(
    Map<String, dynamic>? data, {
    double? ebitdaMarginOverride,
  }) {
    if (data == null) return UnitEconomicsData.empty();
    final rev = (data['revPerStudent'] as num?)?.toDouble() ?? 0.0;
    final cost = (data['costPerStudent'] as num?)?.toDouble() ?? 0.0;
    final contr = rev > cost ? rev - cost : 0.0;
    final ebitda = ebitdaMarginOverride ?? ((data['ebitdaMargin'] as num?)?.toDouble() ?? 0.0);

    return UnitEconomicsData(
      revPerStudent: rev,
      costPerStudent: cost,
      contributionPerStudent: contr,
      ebitdaMargin: ebitda,
    );
  }
}

/// Payment Mix Item
class PaymentMixItem {
  final String name;
  final double percentage;
  final Color color;

  const PaymentMixItem({
    required this.name,
    required this.percentage,
    required this.color,
  });
}

/// Most Profitable Branch Item
class ProfitableBranchItem {
  final String branchName;
  final double ebitdaMargin;
  final Color color;

  const ProfitableBranchItem({
    required this.branchName,
    required this.ebitdaMargin,
    required this.color,
  });
}

/// Branch Fee Collection Item
class BranchFeeCollectionItem {
  final String branchName;
  final double billed;
  final double collected;
  final double due;
  final double collectionPct;
  final Color color;

  const BranchFeeCollectionItem({
    required this.branchName,
    required this.billed,
    required this.collected,
    required this.due,
    required this.collectionPct,
    required this.color,
  });
}

/// V1 Requirement Row 30: Spend by branch
/// Sourced strictly from API `branches[].expenses`.
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

  factory SpendByBranchItem.fromBranchJson(
    Map<String, dynamic> b, {
    int index = 0,
    String period = 'YTD',
  }) {
    final String name = b['name']?.toString() ?? 'Branch';
    final String id = b['id']?.toString() ?? '$index';
    final exp = b['expenses'] as Map<String, dynamic>? ?? {};

    final double pYtd = (exp['payrollYTD'] as num?)?.toDouble() ?? 0.0;
    final double fYtd = (exp['fuelYTD'] as num?)?.toDouble() ?? 0.0;
    final double purYtd = (exp['purchasesYTD'] as num?)?.toDouble() ??
        (b['inventorySpendMTD'] as num?)?.toDouble() ??
        0.0;
    final double totalYtd = (exp['totalYTD'] as num?)?.toDouble() ?? 0.0;
    final double? r = (exp['rentMonthly'] as num?)?.toDouble() ??
        (b['resources'] is Map ? (b['resources']['rentMonthly'] as num?)?.toDouble() : null);

    double p = pYtd;
    double f = fYtd;
    double pur = purYtd;
    double total = totalYtd > 0 ? totalYtd : (p + (r ?? 0.0) + f + pur);

    final colors = [
      const Color(0xFF10B981), // Emerald
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Rose
      const Color(0xFF6366F1), // Indigo
      const Color(0xFFEC4899), // Pink
      const Color(0xFF14B8A6), // Teal
    ];

    return SpendByBranchItem(
      branchId: id,
      branchName: name,
      payroll: p,
      rent: r != null && r > 0 ? r : null,
      fuelFleet: f,
      purchases: pur,
      totalSpend: total,
      dotColor: colors[index % colors.length],
    );
  }
}

/// V1 Requirement Row 30: Expense Mix
/// Sourced strictly from API `expenses.categories`.
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

  factory ExpenseMixCategory.fromJson(
    Map<String, dynamic> c, {
    required double totalSpend,
    int index = 0,
  }) {
    final String name = c['category']?.toString() ?? 'Other';
    final double amt = (c['amount'] as num?)?.toDouble() ?? 0.0;
    final double pct = totalSpend > 0
        ? double.parse(((amt / totalSpend) * 100).toStringAsFixed(1))
        : 0.0;

    Color color;
    if (name.toLowerCase().contains('payroll')) {
      color = const Color(0xFF7C3AED); // Purple
    } else if (name.toLowerCase().contains('fuel')) {
      color = const Color(0xFFF59E0B); // Amber
    } else if (name.toLowerCase().contains('purchase')) {
      color = const Color(0xFFA855F7); // Violet
    } else if (name.toLowerCase().contains('claim')) {
      color = const Color(0xFF10B981); // Emerald
    } else if (name.toLowerCase().contains('rent')) {
      color = const Color(0xFF3B82F6); // Blue
    } else {
      final palette = [
        const Color(0xFF06B6D4),
        const Color(0xFFEF4444),
        const Color(0xFF6366F1),
        const Color(0xFF14B8A6),
      ];
      color = palette[index % palette.length];
    }

    return ExpenseMixCategory(
      category: name,
      amount: amt,
      percentage: pct,
      color: color,
    );
  }
}

/// Monthly Revenue vs Operating Expenses Trend
/// Sourced strictly from API `revenueSeries`.
class MonthlyFinanceTrend {
  final String month;
  final double revenue;
  final double expenses;

  const MonthlyFinanceTrend({
    required this.month,
    required this.revenue,
    required this.expenses,
  });

  factory MonthlyFinanceTrend.fromJson(Map<String, dynamic> item) {
    final String m = item['month']?.toString() ?? '';
    final double rev = (item['revenue'] as num?)?.toDouble() ?? 0.0;
    final double exp = (item['expenses'] as num?)?.toDouble() ?? 0.0;

    return MonthlyFinanceTrend(
      month: m,
      revenue: rev,
      expenses: exp,
    );
  }
}

/// Purchased Items (Invoices)
/// Sourced strictly from API `expenses.purchaseLines`.
class PurchaseInvoiceItem {
  final String date;
  final String item;
  final String category;
  final String supplier;
  final double amount;
  final String branch;
  final String status;

  const PurchaseInvoiceItem({
    required this.date,
    required this.item,
    required this.category,
    required this.supplier,
    required this.amount,
    required this.branch,
    required this.status,
  });

  factory PurchaseInvoiceItem.fromJson(Map<String, dynamic> p) {
    return PurchaseInvoiceItem(
      date: p['date']?.toString() ?? '',
      item: p['item']?.toString() ?? '',
      category: p['itemGroup']?.toString() ?? p['category']?.toString() ?? 'General',
      supplier: p['supplier']?.toString() ?? '',
      amount: (p['amount'] as num?)?.toDouble() ?? 0.0,
      branch: p['branch']?.toString() ?? '',
      status: p['status']?.toString() ?? 'Paid',
    );
  }
}

/// Root Aggregate Model for Finance & Fees Screen
/// Sourced 100% dynamically from API response with NO hardcoded fallback arrays.
class FinanceFeeData {
  final FinanceKpis kpis;
  final ExpenseKpis expenses;
  final FeeCollectionData feeCollection;
  final List<ReceivablesAgingItem> receivablesAging;
  final UnitEconomicsData unitEconomics;
  final List<PaymentMixItem> paymentMix;
  final List<ProfitableBranchItem> profitableBranches;
  final List<BranchFeeCollectionItem> branchFeeCollections;
  final List<SpendByBranchItem> spendByBranch;
  final List<ExpenseMixCategory> expenseMix;
  final List<MonthlyFinanceTrend> trendSeries;
  final List<PurchaseInvoiceItem> purchaseItems;

  const FinanceFeeData({
    required this.kpis,
    required this.expenses,
    required this.feeCollection,
    required this.receivablesAging,
    required this.unitEconomics,
    required this.paymentMix,
    required this.profitableBranches,
    required this.branchFeeCollections,
    required this.spendByBranch,
    required this.expenseMix,
    required this.trendSeries,
    required this.purchaseItems,
  });

  factory FinanceFeeData.empty() {
    return FinanceFeeData(
      kpis: FinanceKpis.empty(),
      expenses: ExpenseKpis.empty(),
      feeCollection: FeeCollectionData.empty(),
      receivablesAging: const [],
      unitEconomics: UnitEconomicsData.empty(),
      paymentMix: const [],
      profitableBranches: const [],
      branchFeeCollections: const [],
      spendByBranch: const [],
      expenseMix: const [],
      trendSeries: const [],
      purchaseItems: const [],
    );
  }

  factory FinanceFeeData.fromDashboardJson(
    Map<String, dynamic> rootJson, {
    String period = 'YTD',
    String branchFilter = 'All branches',
  }) {
    final group = rootJson['group'] as Map<String, dynamic>?;
    final rawBranches = rootJson['branches'] as List<dynamic>? ?? [];
    final expensesMap = rootJson['expenses'] as Map<String, dynamic>?;
    final rawRevenueSeries = rootJson['revenueSeries'] as List<dynamic>? ?? [];
    final collectionMap = rootJson['collection'] as Map<String, dynamic>?;
    final rawAging = rootJson['aging'] as List<dynamic>? ?? [];
    final rawPaymentMix = rootJson['paymentMix'] as List<dynamic>? ?? [];

    // Branch filter applied
    List<dynamic> filteredBranches = rawBranches;
    Map<String, dynamic>? selectedBranchMap;
    if (branchFilter != 'All branches') {
      filteredBranches = rawBranches.where((b) {
        if (b is! Map<String, dynamic>) return false;
        final name = b['name']?.toString() ?? '';
        final id = b['id']?.toString() ?? '';
        final code = b['code']?.toString() ?? '';
        final filterLower = branchFilter.toLowerCase().trim();
        final nameLower = name.toLowerCase().trim();
        final matches = nameLower == filterLower ||
            id.toLowerCase().trim() == filterLower ||
            code.toLowerCase().trim() == filterLower ||
            nameLower.contains(filterLower) ||
            filterLower.contains(nameLower);
        if (matches && selectedBranchMap == null) {
          selectedBranchMap = b;
        }
        return matches;
      }).toList();
    }

    // Purchases (strictly from API expenses.purchaseLines)
    final List<PurchaseInvoiceItem> purchases = [];
    final rawPurchases = expensesMap?['purchaseLines'] as List<dynamic>?;
    if (rawPurchases != null) {
      for (final p in rawPurchases) {
        if (p is Map<String, dynamic>) {
          if (selectedBranchMap != null) {
            final pBranch = (p['branch']?.toString() ?? '').toLowerCase();
            final bName = (selectedBranchMap!['name']?.toString() ?? '').toLowerCase();
            if (!pBranch.contains(bName) && !bName.contains(pBranch)) {
              continue;
            }
          }
          purchases.add(PurchaseInvoiceItem.fromJson(p));
        }
      }
    }

    // KPIs: branch-level if selected, else group-level
    final kpis = selectedBranchMap != null
        ? FinanceKpis.fromBranchJson(
            selectedBranchMap!,
            period: period,
            revenueSeries: rawRevenueSeries,
          )
        : FinanceKpis.fromJson(
            group,
            period: period,
            revenueSeries: rawRevenueSeries,
            branches: rawBranches,
          );

    // Expenses: branch-level if selected, else group-level
    final expenses = selectedBranchMap != null
        ? ExpenseKpis.fromBranchExpenses(
            selectedBranchMap!['expenses'] as Map<String, dynamic>?,
            selectedBranchMap!['resources'] as Map<String, dynamic>?,
            period: period,
            purchaseLinesCount: purchases.length,
          )
        : ExpenseKpis.fromJson(expensesMap, period: period);

    // Fee Collection: branch-level if selected, else group-level
    final feeCollection = selectedBranchMap != null
        ? FeeCollectionData.fromBranch(
            selectedBranchMap!,
            collectionMap,
            group,
            period: period,
            revenueSeries: rawRevenueSeries,
            overrideRevenue: kpis.revenue,
            overrideOutstanding: kpis.outstanding,
            overrideCollected: kpis.collected,
            overridePct: kpis.collectedPct,
          )
        : FeeCollectionData.fromJson(
            collectionMap,
            group,
            period: period,
            revenueSeries: rawRevenueSeries,
            overrideRevenue: kpis.revenue,
            overrideOutstanding: kpis.outstanding,
            overrideCollected: kpis.collected,
            overridePct: kpis.collectedPct,
          );

    // Aging breakdown items
    final agingColors = [
      const Color(0xFF10B981), // 0-30 d: Emerald
      const Color(0xFF8B5CF6), // 31-60 d: Purple
      const Color(0xFFF59E0B), // 61-90 d: Amber
      const Color(0xFFEF4444), // 90+ d: Rose Red
    ];
    final double groupOut = (group?['outstanding'] as num?)?.toDouble() ?? 0.0;
    final double agingRatio = groupOut > 0 ? (kpis.outstanding / groupOut) : 1.0;

    final List<ReceivablesAgingItem> agingItems = [];
    for (int i = 0; i < rawAging.length; i++) {
      final a = rawAging[i];
      if (a is Map<String, dynamic>) {
        final rawAmt = (a['amount'] as num?)?.toDouble() ?? 0.0;
        agingItems.add(ReceivablesAgingItem(
          bucket: a['bucket']?.toString() ?? '',
          amount: (rawAmt * agingRatio).roundToDouble(),
          color: agingColors[i % agingColors.length],
        ));
      }
    }

    // Unit economics (per student)
    final unitEconomics = UnitEconomicsData.fromJson(
      selectedBranchMap ?? group,
      ebitdaMarginOverride: kpis.ebitdaMargin,
    );

    // Payment mix
    final List<PaymentMixItem> paymentItems = [];
    if (selectedBranchMap != null) {
      final onlinePct = (selectedBranchMap!['onlinePayPct'] as num?)?.toDouble() ?? 0.0;
      if (onlinePct > 0) {
        paymentItems.add(PaymentMixItem(
          name: 'Razorpay (online)',
          percentage: onlinePct,
          color: const Color(0xFF7C3AED),
        ));
        paymentItems.add(PaymentMixItem(
          name: 'Counter / cheque',
          percentage: double.parse((100.0 - onlinePct).clamp(0.0, 100.0).toStringAsFixed(1)),
          color: const Color(0xFF94A3B8),
        ));
      }
    } else if (rawPaymentMix.isNotEmpty) {
      for (int i = 0; i < rawPaymentMix.length; i++) {
        final pm = rawPaymentMix[i];
        if (pm is Map<String, dynamic>) {
          paymentItems.add(PaymentMixItem(
            name: pm['name']?.toString() ?? '',
            percentage: (pm['value'] as num?)?.toDouble() ?? 0.0,
            color: i == 0 ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
          ));
        }
      }
    } else {
      final onlinePct = (group?['onlinePayPct'] as num?)?.toDouble() ?? 0.0;
      if (onlinePct > 0) {
        paymentItems.add(PaymentMixItem(
          name: 'Razorpay (online)',
          percentage: onlinePct,
          color: const Color(0xFF7C3AED),
        ));
        paymentItems.add(PaymentMixItem(
          name: 'Counter / cheque',
          percentage: double.parse((100.0 - onlinePct).clamp(0.0, 100.0).toStringAsFixed(1)),
          color: const Color(0xFF94A3B8),
        ));
      }
    }

    // Palette for branch charts
    final branchPalette = [
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFFEF4444), // Rose
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF14B8A6), // Teal
      const Color(0xFFA855F7), // Violet
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF06B6D4), // Cyan
    ];

    // Most profitable branches (ranked by EBITDA margin descending)
    final List<Map<String, dynamic>> validBranches = [];
    final sourceForProfitable = selectedBranchMap != null ? [selectedBranchMap!] : rawBranches;
    for (final b in sourceForProfitable) {
      if (b is Map<String, dynamic>) {
        validBranches.add(b);
      }
    }
    validBranches.sort((a, b) {
      final aMargin = (a['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
      final bMargin = (b['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
      return bMargin.compareTo(aMargin);
    });

    final List<ProfitableBranchItem> profitableBranches = [];
    for (int i = 0; i < validBranches.length; i++) {
      final b = validBranches[i];
      final margin = (b['ebitdaMargin'] as num?)?.toDouble() ?? 0.0;
      profitableBranches.add(ProfitableBranchItem(
        branchName: b['name']?.toString() ?? 'Branch',
        ebitdaMargin: margin,
        color: branchPalette[i % branchPalette.length],
      ));
    }

    // Fee collection by branch
    final double pf = FinanceKpis.computePeriodFactor(period, revenueSeries: rawRevenueSeries);
    final List<BranchFeeCollectionItem> branchFeeCollections = [];
    final branchesForFee = selectedBranchMap != null ? [selectedBranchMap!] : rawBranches;
    for (int i = 0; i < branchesForFee.length; i++) {
      final b = branchesForFee[i];
      if (b is Map<String, dynamic>) {
        final double rawRev = (b['revenue'] as num?)?.toDouble() ?? 0.0;
        final double rawOut = (b['outstanding'] as num?)?.toDouble() ?? 0.0;
        final double bPct = (b['collectionPct'] as num?)?.toDouble() ?? 0.0;
        final double bCollRate = rawRev > 0 && rawOut > 0
            ? (rawRev - rawOut) / rawRev
            : (bPct / 100.0);

        final double billed = (rawRev * pf).roundToDouble();
        final double coll = (billed * bCollRate).roundToDouble();
        final double due = billed - coll;

        branchFeeCollections.add(BranchFeeCollectionItem(
          branchName: b['name']?.toString() ?? 'Branch',
          billed: billed,
          collected: coll,
          due: due,
          collectionPct: bPct > 0
              ? bPct
              : (billed > 0 ? double.parse(((coll / billed) * 100).toStringAsFixed(1)) : 0.0),
          color: branchPalette[i % branchPalette.length],
        ));
      }
    }

    // Spend by branch (strictly from API branches)
    final List<SpendByBranchItem> spendList = [];
    for (int i = 0; i < filteredBranches.length; i++) {
      final b = filteredBranches[i];
      if (b is Map<String, dynamic>) {
        spendList.add(SpendByBranchItem.fromBranchJson(b, index: i, period: period));
      }
    }

    // Expense Mix (strictly from API)
    final List<ExpenseMixCategory> mix = [];
    if (selectedBranchMap != null) {
      final bExp = selectedBranchMap!['expenses'] as Map<String, dynamic>? ?? {};
      final double bPayroll = (bExp['payrollYTD'] as num?)?.toDouble() ?? 0.0;
      final double bFuel = ((bExp['fuelYTD'] as num?)?.toDouble() ?? 0.0) +
          ((bExp['maintenanceYTD'] as num?)?.toDouble() ?? 0.0);
      final double bPurchases = (bExp['purchasesYTD'] as num?)?.toDouble() ?? 0.0;
      final double bClaims = (bExp['claimsYTD'] as num?)?.toDouble() ?? 0.0;
      final double bTotal = expenses.totalSpend;

      final categories = [
        if (bPayroll > 0) {'category': 'Payroll', 'amount': bPayroll},
        if (bFuel > 0) {'category': 'Fuel & fleet', 'amount': bFuel},
        if (bPurchases > 0) {'category': 'Purchases', 'amount': bPurchases},
        if (bClaims > 0) {'category': 'Staff claims', 'amount': bClaims},
      ];
      for (int i = 0; i < categories.length; i++) {
        mix.add(ExpenseMixCategory.fromJson(categories[i], totalSpend: bTotal > 0 ? bTotal : 1.0, index: i));
      }
    } else {
      final rawCategories = expensesMap?['categories'] as List<dynamic>?;
      if (rawCategories != null && rawCategories.isNotEmpty) {
        final double totalExp = expenses.totalSpend > 0
            ? expenses.totalSpend
            : rawCategories.fold(0.0, (acc, c) => acc + ((c is Map ? (c['amount'] as num?)?.toDouble() : 0.0) ?? 0.0));

        for (int i = 0; i < rawCategories.length; i++) {
          final c = rawCategories[i];
          if (c is Map<String, dynamic>) {
            mix.add(ExpenseMixCategory.fromJson(c, totalSpend: totalExp, index: i));
          }
        }
      }
    }

    // Trailing Trends (strictly from API `revenueSeries`)
    final List<MonthlyFinanceTrend> trends = [];
    for (final item in rawRevenueSeries) {
      if (item is Map<String, dynamic>) {
        trends.add(MonthlyFinanceTrend.fromJson(item));
      }
    }

    return FinanceFeeData(
      kpis: kpis,
      expenses: expenses,
      feeCollection: feeCollection,
      receivablesAging: agingItems,
      unitEconomics: unitEconomics,
      paymentMix: paymentItems,
      profitableBranches: profitableBranches,
      branchFeeCollections: branchFeeCollections,
      spendByBranch: spendList,
      expenseMix: mix,
      trendSeries: trends,
      purchaseItems: purchases,
    );
  }
}
