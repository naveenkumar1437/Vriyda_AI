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
        Text(
          'EXPENSES · ACADEMIC YEAR TO DATE',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        // Row 1: Total Spend, Payroll, Rent
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'TOTAL SPEND · $period',
                value: expenses.formattedTotalSpend,
                subtext: 'all expense lines',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'PAYROLL · $period',
                value: expenses.formattedPayroll,
                subtext: 'submitted salary slips',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'RENT · MONTHLY',
                value: expenses.formattedRent,
                subtext: 'committed, not posted',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Fuel & Fleet, Purchases, Staff Claims
        Row(
          children: [
            Expanded(
              child: FinanceMetricCard(
                label: 'FUEL & FLEET · $period',
                value: expenses.formattedFuelFleet,
                subtext: expenses.fuelAndFleet > 0 ? 'fleet logs' : 'no fuel logged yet',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'PURCHASES · $period',
                value: expenses.formattedPurchases,
                subtext: '4 line items',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FinanceMetricCard(
                label: 'STAFF CLAIMS · $period',
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
