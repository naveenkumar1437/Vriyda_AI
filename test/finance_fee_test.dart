import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/models/finance_fee_models.dart';
import 'package:vriyda_ai/services/finance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Finance & Fees Models & Dynamic API Parsing Tests', () {
    test('FinanceKpis parses correctly and scales across periods without hardcoding', () {
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

      // MTD scaling matching web periodFactor: default 0.088
      final mtd = FinanceKpis.fromJson(groupData, period: 'MTD');
      expect(mtd.revenue, (14155020.0 * 0.088).roundToDouble());
      expect(mtd.collected, (mtd.revenue * (9658180.0 / 14155020.0)).roundToDouble());
      expect(mtd.outstanding, mtd.revenue - mtd.collected);

      // QTD scaling matching web periodFactor: default 0.25
      final qtd = FinanceKpis.fromJson(groupData, period: 'QTD');
      expect(qtd.revenue, (14155020.0 * 0.25).roundToDouble());
      expect(qtd.collected, (qtd.revenue * (9658180.0 / 14155020.0)).roundToDouble());
      expect(qtd.outstanding, qtd.revenue - qtd.collected);

      // FY scaling matching web periodFactor: 1.08 (+8% full-year forecast)
      final fy = FinanceKpis.fromJson(groupData, period: 'FY');
      expect(fy.revenue, (14155020.0 * 1.08).roundToDouble());
      expect(fy.collected, (fy.revenue * (9658180.0 / 14155020.0)).roundToDouble());
      expect(fy.outstanding, fy.revenue - fy.collected);

      // MTD scaling with revenueSeries: tail(1) / total
      final series = [
        {'month': 'Jun', 'revenue': 1000000.0},
        {'month': 'Jul', 'revenue': 1000000.0},
        {'month': 'Aug', 'revenue': 2000000.0},
      ];
      final mtdWithSeries = FinanceKpis.fromJson(groupData, period: 'MTD', revenueSeries: series);
      expect(mtdWithSeries.revenue, (14155020.0 * 0.5).roundToDouble());

      // Branch-level KPIs
      final branchData = {
        'id': 1,
        'name': 'Gachibowli Campus',
        'revenue': 2730000.0,
        'outstanding': 1320000.0,
        'collectionPct': 51.6,
        'ebitdaMargin': 42.0,
        'payrollPct': 41.0,
        'onlinePayPct': 84.0,
      };
      final branchKpis = FinanceKpis.fromBranchJson(branchData);
      expect(branchKpis.revenue, 2730000.0);
      expect(branchKpis.formattedRevenue, '₹27.3 L');
      expect(branchKpis.outstanding, 1320000.0);
      expect(branchKpis.formattedOutstanding, '₹13.2 L');
      expect(branchKpis.collected, 1410000.0);
      expect(branchKpis.formattedCollected, '₹14.1 L');
      expect(branchKpis.ebitdaMargin, 42.0);
      expect(branchKpis.payrollCostPct, 41.0);
      expect(branchKpis.onlinePaymentsPct, 84.0);
    });

    test('ExpenseKpis returns zeros for null/empty API responses with zero hardcoding', () {
      final empty = ExpenseKpis.fromJson(null, period: 'YTD');
      expect(empty.totalSpend, 0.0);
      expect(empty.payroll, 0.0);
      expect(empty.rentMonthly, isNull);
      expect(empty.fuelAndFleet, 0.0);
      expect(empty.purchases, 0.0);
      expect(empty.staffClaims, 0.0);
      expect(empty.purchaseLinesCount, 0);
      expect(empty.formattedTotalSpend, '₹0');
      expect(empty.formattedRent, '—');
    });

    test('ExpenseKpis parses dynamic API expenses correctly', () {
      final expensesJson = {
        'totalYTD': 326200.0,
        'payrollYTD': 50000.0,
        'rentMonthly': 0.0,
        'fuelYTD': 7000.0,
        'purchasesYTD': 12700.0,
        'claimsYTD': 256500.0,
        'purchaseLines': [
          {'item': 'Notebook', 'amount': 2200.0},
          {'item': 'Chalk', 'amount': 500.0},
        ],
      };

      final expenses = ExpenseKpis.fromJson(expensesJson, period: 'YTD');
      expect(expenses.totalSpend, 326200.0);
      expect(expenses.formattedTotalSpend, '₹3.3 L');
      expect(expenses.payroll, 50000.0);
      expect(expenses.formattedPayroll, '₹50,000');
      expect(expenses.fuelAndFleet, 7000.0);
      expect(expenses.formattedFuelFleet, '₹7,000');
      expect(expenses.purchases, 12700.0);
      expect(expenses.formattedPurchases, '₹12,700');
      expect(expenses.staffClaims, 256500.0);
      expect(expenses.formattedStaffClaims, '₹2.6 L');
      expect(expenses.purchaseLinesCount, 2);
    });

    test('FinanceFeeData full dynamic aggregation parses all V1 sections', () {
      final samplePayload = {
        'group': {
          'revenueYTD': 14000000.0,
          'collectedYTD': 9500000.0,
          'outstanding': 4500000.0,
          'collectionPct': 67.8,
          'ebitdaMargin': 35.8,
          'revPerStudent': 116025.0,
          'costPerStudent': 74371.0,
          'onlinePayPct': 70.4,
        },
        'collection': {
          'collected': 9500000.0,
          'due': 2620000.0,
          'overdue': 1880000.0,
        },
        'aging': [
          {'bucket': '0–30 d', 'amount': 1850000.0},
          {'bucket': '31–60 d', 'amount': 1220000.0},
          {'bucket': '61–90 d', 'amount': 860000.0},
          {'bucket': '90+ d', 'amount': 590000.0},
        ],
        'paymentMix': [
          {'name': 'Razorpay (online)', 'value': 70.4},
          {'name': 'Counter / cheque', 'value': 29.6},
        ],
        'branches': [
          {
            'id': 1,
            'name': 'Gachibowli Campus',
            'revenue': 2730000.0,
            'outstanding': 1320000.0,
            'collectionPct': 51.6,
            'ebitdaMargin': 42.0,
            'expenses': {
              'payrollYTD': 0.0,
              'fuelYTD': 0.0,
              'totalYTD': 0.0,
            },
          },
          {
            'id': 6,
            'name': 'Steel Plant Branch',
            'revenue': 2500000.0,
            'outstanding': 420000.0,
            'collectionPct': 83.3,
            'ebitdaMargin': 38.0,
            'expenses': {
              'payrollYTD': 50000.0,
              'fuelYTD': 5000.0,
              'totalYTD': 55000.0,
            },
          },
        ],
        'expenses': {
          'totalYTD': 326200.0,
          'payrollYTD': 50000.0,
          'fuelYTD': 5000.0,
          'purchasesYTD': 12200.0,
          'claimsYTD': 256500.0,
          'categories': [
            {'category': 'Payroll', 'amount': 50000.0},
            {'category': 'Fuel & fleet', 'amount': 5000.0},
            {'category': 'Purchases', 'amount': 12200.0},
            {'category': 'Staff claims', 'amount': 256500.0},
          ],
          'purchaseLines': [
            {
              'date': '2026-11-03',
              'item': 'A4 Notebook - 200 Pages',
              'category': 'Stationary',
              'supplier': 'Sri Sai Enterprises',
              'amount': 2200.0,
              'branch': 'Steel Plant Branch',
              'status': 'Paid',
            },
          ],
        },
        'revenueSeries': [
          {'month': 'Jul', 'revenue': 1.2, 'expenses': 0.8},
          {'month': 'Aug', 'revenue': 1.4, 'expenses': 0.9},
        ],
      };

      final data = FinanceFeeData.fromDashboardJson(samplePayload, period: 'YTD');

      // KPIs
      expect(data.kpis.revenue, 14000000.0);
      expect(data.kpis.collected, 9500000.0);

      // Fee Collection
      expect(data.feeCollection.collected, 9500000.0);
      expect(data.feeCollection.due, 2620000.0);
      expect(data.feeCollection.overdue, 1880000.0);
      expect(data.receivablesAging.length, 4);

      // Unit Economics
      expect(data.unitEconomics.revPerStudent, 116025.0);
      expect(data.unitEconomics.costPerStudent, 74371.0);
      expect(data.unitEconomics.contributionPerStudent, 116025.0 - 74371.0);

      // Payment Mix
      expect(data.paymentMix.length, 2);
      expect(data.paymentMix[0].percentage, 70.4);

      // Most Profitable Branches (Ranked descending)
      expect(data.profitableBranches.length, 2);
      expect(data.profitableBranches[0].branchName, 'Gachibowli Campus');
      expect(data.profitableBranches[0].ebitdaMargin, 42.0);
      expect(data.profitableBranches[1].branchName, 'Steel Plant Branch');
      expect(data.profitableBranches[1].ebitdaMargin, 38.0);

      // Fee Collection by branch
      expect(data.branchFeeCollections.length, 2);
      expect(data.branchFeeCollections[0].branchName, 'Gachibowli Campus');
      expect(data.branchFeeCollections[0].billed, 2730000.0);
      expect(data.branchFeeCollections[0].due, 1320000.0);

      // Spend by branch (Row 30)
      expect(data.spendByBranch.length, 2);
      expect(data.spendByBranch[1].branchName, 'Steel Plant Branch');
      expect(data.spendByBranch[1].payroll, 50000.0);
      expect(data.spendByBranch[1].fuelFleet, 5000.0);

      // Expense mix (Row 30)
      expect(data.expenseMix.length, 4);

      // Purchase Invoices
      expect(data.purchaseItems.length, 1);
      expect(data.purchaseItems[0].item, 'A4 Notebook - 200 Pages');

      // Trailing Trend
      expect(data.trendSeries.length, 2);

      // Branch Filtering isolated verification
      final branchFiltered = FinanceFeeData.fromDashboardJson(
        samplePayload,
        period: 'YTD',
        branchFilter: 'Gachibowli Campus',
      );
      expect(branchFiltered.kpis.revenue, 2730000.0);
      expect(branchFiltered.kpis.formattedRevenue, '₹27.3 L');
      expect(branchFiltered.kpis.outstanding, 1320000.0);
      expect(branchFiltered.kpis.formattedOutstanding, '₹13.2 L');
      expect(branchFiltered.kpis.collected, 1410000.0);
      expect(branchFiltered.kpis.formattedCollected, '₹14.1 L');
      expect(branchFiltered.kpis.ebitdaMargin, 42.0);
      expect(branchFiltered.spendByBranch.length, 1);
      expect(branchFiltered.spendByBranch[0].branchName, 'Gachibowli Campus');
      expect(branchFiltered.branchFeeCollections.length, 1);
      expect(branchFiltered.branchFeeCollections[0].branchName, 'Gachibowli Campus');
    });

    test('FinanceService throws meaningful error when authentication token is missing', () async {
      expect(
        () => FinanceService.fetchFinanceData(period: 'YTD'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
