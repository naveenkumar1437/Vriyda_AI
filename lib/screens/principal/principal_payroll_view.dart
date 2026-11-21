import 'package:flutter/material.dart';

/// Principal Payroll Screen matching Excel Sheet "Payroll (Page-8)":
/// - Sub-Tabs: My Payroll | Staff Payroll
/// - My Payroll:
///   - 4 KPI Cards: Employee ID (HR-EMP-00058), Base Salary (₹85,000), Last Net Pay (₹79,500), Net This Year (₹7,15,500)
///   - My Salary Slips (Nov 2026, Oct 2026, Sep 2026, Aug 2026) with Download action
/// - Staff Payroll:
///   - 4 KPI Cards: Gross Staff Pay (₹8,40,000), Deductions (₹42,000), Net Pay (₹7,98,000), Staff Paid (25/25)
///   - Teaching vs Non-teaching breakdown
///   - Non-teaching by Area (Accounts, Front office, Library, Maintenance)
///   - Staff Salary Slips Roster
class PrincipalPayrollView extends StatefulWidget {
  const PrincipalPayrollView({super.key});

  @override
  State<PrincipalPayrollView> createState() => _PrincipalPayrollViewState();
}

class _PrincipalPayrollViewState extends State<PrincipalPayrollView> {
  String _activeTab = 'My Payroll'; // 'My Payroll' or 'Staff Payroll'

  final List<Map<String, String>> _mySlips = const [
    {'month': 'November 2026', 'gross': '₹85,000', 'ded': '₹5,500', 'net': '₹79,500', 'status': 'Paid'},
    {'month': 'October 2026', 'gross': '₹85,000', 'ded': '₹5,500', 'net': '₹79,500', 'status': 'Paid'},
    {'month': 'September 2026', 'gross': '₹85,000', 'ded': '₹5,500', 'net': '₹79,500', 'status': 'Paid'},
    {'month': 'August 2026', 'gross': '₹85,000', 'ded': '₹5,500', 'net': '₹79,500', 'status': 'Paid'},
  ];

  final List<Map<String, dynamic>> _staffSlips = const [
    {'name': 'Keerthana Bangla', 'id': 'HR-EMP-00027', 'role': 'Senior Teacher', 'net': '₹48,000', 'status': 'Paid'},
    {'name': 'Ramana', 'id': 'HR-EMP-00002', 'role': 'Primary Teacher', 'net': '₹42,500', 'status': 'Paid'},
    {'name': 'Gopi Madem', 'id': 'HR-EMP-00003', 'role': 'Maths Teacher', 'net': '₹45,000', 'status': 'Paid'},
    {'name': 'Suresh Kumar', 'id': 'HR-EMP-00010', 'role': 'Account Manager', 'net': '₹38,000', 'status': 'Paid'},
    {'name': 'Lakshmi Rao', 'id': 'HR-EMP-00011', 'role': 'Receptionist', 'net': '₹24,000', 'status': 'Paid'},
    {'name': 'Venkatesh P', 'id': 'HR-EMP-00012', 'role': 'Senior Librarian', 'net': '₹32,000', 'status': 'Paid'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Payroll',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Personal compensation slips & campus staff payroll disbursements',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 16),

        // Sub-tabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentPill('My Payroll'),
              const SizedBox(width: 4),
              _buildSegmentPill('Staff Payroll'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_activeTab == 'My Payroll') _buildMyPayrollContent(),
        if (_activeTab == 'Staff Payroll') _buildStaffPayrollContent(),
      ],
    );
  }

  Widget _buildSegmentPill(String tab) {
    final isSel = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          tab,
          style: TextStyle(
            color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            fontFamily: 'Urbanist',
          ),
        ),
      ),
    );
  }

  // --- My Payroll ---
  Widget _buildMyPayrollContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Employee ID', 'HR-EMP-00058', 'Steel Plant Branch', const Color(0xFF6366F1))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Base Salary', '₹85,000', 'Monthly Gross', const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Last Net Pay', '₹79,500', 'Nov 2026 Disbursed', const Color(0xFF059669))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Net This Year', '₹7,15,500', 'FY 2026-27 YTD', const Color(0xFF3B82F6))),
          ],
        ),

        const SizedBox(height: 20),

        // Salary Slips
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
                'My Salary Slips',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: _mySlips.map((s) {
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
                        const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['month']!, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('Gross ${s['gross']} · Deductions ${s['ded']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(s['net']!, style: const TextStyle(color: Color(0xFF059669), fontSize: 13.5, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Downloading salary slip for ${s['month']}')),
                                );
                              },
                              child: const Text('Download →', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
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

  // --- Staff Payroll ---
  Widget _buildStaffPayrollContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildKpiCard('Gross Staff Pay', '₹8,40,000', '25 campus staff', const Color(0xFF6366F1))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Deductions', '₹42,000', 'PF + TDS + ESI', const Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Net Disbursed', '₹7,98,000', '100% processed', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Staff Paid', '25/25', 'Zero pending', const Color(0xFF059669))),
          ],
        ),

        const SizedBox(height: 20),

        // Teaching vs Non-teaching card
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
                'Teaching vs Non-teaching payroll',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('TEACHING (11)', style: TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('₹4,95,000', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('62% of payroll', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('NON-TEACHING (14)', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('₹3,45,000', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
                          Text('38% of payroll', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Staff Salary Slips Roster
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
                'Staff Salary Slips · Nov 2026',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Column(
                children: _staffSlips.map((ss) {
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
                              Text(ss['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${ss['id']} · ${ss['role']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(ss['net'] as String, style: const TextStyle(color: Color(0xFF059669), fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                              child: const Text('Disbursed', style: TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.bold)),
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
