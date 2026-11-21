import 'package:flutter/material.dart';
import '../../models/finance_fee_models.dart';
import 'finance_metric_card.dart';

/// Implements V1 Requirements (Row 29):
/// Expenses (KPIs: Total spend · YTD, Payroll · YTD, Rent · monthly, Fuel & fleet, Purchases, Staff claims)
class ExpensesKpiGrid extends StatelessWidget {
  final ExpenseKpis expenses;
  final String period;

  const ExpensesKpiGrid({
    super.key,
    required this.expenses,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXPENSES · ACADEMIC YEAR TO DATE',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1: Total Spend & Payroll
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'TOTAL SPEND · YTD',
                value: expenses.formattedTotalSpend,
                subtext: 'all expense lines',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FinanceMetricCard(
                label: 'PAYROLL · YTD',
                value: expenses.formattedPayroll,
                subtext: 'submitted salary slips',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Rent & Fuel & Fleet
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'RENT · MONTHLY',
                value: expenses.formattedRent,
                subtext: 'committed, not posted',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FinanceMetricCard(
                label: 'FUEL & FLEET · YTD',
                value: expenses.formattedFuelFleet,
                subtext: expenses.fuelAndFleet > 0 ? 'fleet logs' : 'no fuel logged yet',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 3: Purchases & Staff Claims
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'PURCHASES · YTD',
                value: expenses.formattedPurchases,
                subtext: expenses.purchaseLinesCount > 0
                    ? '${expenses.purchaseLinesCount} line items'
                    : 'line items',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FinanceMetricCard(
                label: 'STAFF CLAIMS · YTD',
                value: expenses.formattedStaffClaims,
                subtext: 'approved reimbursements',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

