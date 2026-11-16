import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/models/finance_fee_models.dart';
import 'package:vriyda_ai/services/finance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Finance & Fees Models & Calculation Tests', () {
    test('FinanceKpis parses correctly and adapts to periods', () {
      final groupData = {
        'revenueYTD': 14155020.0,
        'revenueTarget': 15287422.0,
        'collectedYTD': 9658180.0,
        'outstanding': 4496840.0,
        'collectionPct': 68.2,
        'outstandingPct': 31.8,
        'ebitdaMargin': 35.8,
        'payrollPct': 45.1,
        'onlinePayPct': 70.3,
      };

      // YTD Baseline
      final ytd = FinanceKpis.fromJson(groupData, period: 'YTD');
      expect(ytd.revenue, 14155020.0);
      expect(ytd.formattedRevenue, '₹1.4 Cr');
      expect(ytd.collectedPct, 68.2);
      expect(ytd.formattedCollected, '₹96.6 L');
      expect(ytd.formattedOutstanding, '₹45.0 L');
      expect(ytd.ebitdaMargin, 35.8);
      expect(ytd.payrollCostPct, 45.1);
      expect(ytd.onlinePaymentsPct, 70.3);

      // MTD Scaling
      final mtd = FinanceKpis.fromJson(groupData, period: 'MTD');
      expect(mtd.revenue, closeTo(14155020.0 / 12.0, 1.0));
      expect(mtd.collected, closeTo(9658180.0 / 12.0, 1.0));

      // QTD Scaling
      final qtd = FinanceKpis.fromJson(groupData, period: 'QTD');
      expect(qtd.revenue, closeTo(14155020.0 * 0.28, 1.0));
      expect(qtd.collected, closeTo(9658180.0 * 0.28, 1.0));

      // FY Scaling
      final fy = FinanceKpis.fromJson(groupData, period: 'FY');
      expect(fy.revenue, closeTo(14155020.0 * 1.15, 1.0));
    });

    test('ExpenseKpis parses V1 Row 29 KPI fields properly', () {
      final expenses = ExpenseKpis.fromJson(null, period: 'YTD');
      expect(expenses.totalSpend, 320000.0);
      expect(expenses.formattedTotalSpend, '₹3.2 L');
      expect(expenses.payroll, 50000.0);
      expect(expenses.formattedPayroll, '₹50,000');
      expect(expenses.rentMonthly, isNull);
      expect(expenses.formattedRent, '—');
      expect(expenses.fuelAndFleet, 5000.0);
      expect(expenses.formattedFuelFleet, '₹5,000');
      expect(expenses.purchases, 12200.0);
      expect(expenses.formattedPurchases, '₹12,200');
      expect(expenses.staffClaims, 260000.0);
      expect(expenses.formattedStaffClaims, '₹2.6 L');
    });

    test('FinanceFeeData full aggregation parses spend by branch & expense mix', () {
      final samplePayload = {
        'group': {
          'revenueYTD': 14000000,
          'collectedYTD': 9500000,
          'outstanding': 4500000,
        },
        'branches': [
          {
            'id': 1,
            'name': 'Steel Plant Branch',
            'inventorySpendMTD': 12200,
          },
          {
            'id': 2,
            'name': 'Gachibowli Campus',
            'inventorySpendMTD': 9100,
          },
        ],
      };

      final data = FinanceFeeData.fromDashboardJson(samplePayload, period: 'YTD');

      // Spend by branch (Row 30)
      expect(data.spendByBranch.length, 2);
      expect(data.spendByBranch[0].branchName, 'Steel Plant Branch');
      expect(data.spendByBranch[0].payroll, 50000.0);
      expect(data.spendByBranch[0].fuelFleet, 5000.0);
      expect(data.spendByBranch[1].branchName, 'Gachibowli Campus');

      // Expense mix (Row 30)
      expect(data.expenseMix.length, 4);
      expect(data.expenseMix.any((c) => c.category == 'Payroll'), isTrue);
      expect(data.expenseMix.any((c) => c.category == 'Fuel & fleet'), isTrue);
      expect(data.expenseMix.any((c) => c.category == 'Purchases'), isTrue);
      expect(data.expenseMix.any((c) => c.category == 'Staff claims'), isTrue);

      // Trailing 12 months
      expect(data.trendSeries.length, 12);
      expect(data.purchaseItems.isNotEmpty, isTrue);
    });

    test('FinanceService returns valid FinanceFeeData', () async {
      final data = await FinanceService.fetchFinanceData(period: 'YTD');
      expect(data, isNotNull);
      expect(data.kpis.revenue, greaterThan(0));
      expect(data.expenses.totalSpend, greaterThan(0));
      expect(data.spendByBranch.isNotEmpty, isTrue);
      expect(data.expenseMix.isNotEmpty, isTrue);
    });
  });
}
