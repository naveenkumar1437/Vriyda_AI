import 'package:flutter/material.dart';

/// Principal Office Overheads Screen matching Excel Sheet "Office heads (page-10)":
/// - 4 KPI Cards: Total Overheads (₹1,85,000), Inventory Used (₹45,000), Office Expense (₹1,40,000), Last Month (₹1,92,000 · 3.6% lower)
/// - Spend By Category (Stationery, Maintenance, Utilities, Lab supplies)
/// - Recent Invoices & Entries list
class PrincipalOverheadsView extends StatelessWidget {
  const PrincipalOverheadsView({super.key});

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Stationery & Printing', 'amount': '₹42,000', 'pct': 0.23, 'color': Color(0xFF6366F1)},
    {'name': 'Maintenance & Facility Repairs', 'amount': '₹55,000', 'pct': 0.30, 'color': Color(0xFFF59E0B)},
    {'name': 'Utilities & Electricity', 'amount': '₹48,000', 'pct': 0.26, 'color': Color(0xFF0EA5E9)},
    {'name': 'Lab & Classroom Supplies', 'amount': '₹40,000', 'pct': 0.21, 'color': Color(0xFF10B981)},
  ];

  final List<Map<String, String>> _entries = const [
    {'title': 'Exam Answer Booklets & Printing', 'vendor': 'Sri Balaji Printers', 'date': '19 Nov 2026', 'amount': '₹18,500', 'status': 'Paid'},
    {'title': 'Campus Generator Diesel Refill', 'vendor': 'Indian Oil Corp', 'date': '17 Nov 2026', 'amount': '₹14,200', 'status': 'Paid'},
    {'title': 'Science Chemistry Lab Reagents', 'vendor': 'Sigma Edu Supplies', 'date': '14 Nov 2026', 'amount': '₹22,000', 'status': 'Paid'},
    {'title': 'Broadband Fiber & Telecom Bill', 'vendor': 'Airtel Enterprise', 'date': '10 Nov 2026', 'amount': '₹8,500', 'status': 'Paid'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Office Overheads',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Operational spending, inventory usage & branch facility expenses',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildKpiCard('Total Overheads', '₹1,85,000', 'MTD Spend', const Color(0xFF84CC16))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Inventory Used', '₹45,000', 'Stationery + Lab', const Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Office Expense', '₹1,40,000', 'Utilities + Repairs', const Color(0xFF0EA5E9))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Last Month', '₹1,92,000', '▲ 3.6% lower', const Color(0xFF059669))),
          ],
        ),

        const SizedBox(height: 20),

        // Spend By Category
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spending by category',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Column(
                children: _categories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text(c['amount'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: c['pct'] as double,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(c['color'] as Color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Recent Entries
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Expense Entries',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Column(
                children: _entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${e['vendor']} · ${e['date']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(e['amount']!, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                              child: Text(e['status']!, style: const TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, String sub, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
