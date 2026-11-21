import 'package:flutter/material.dart';

/// Principal Fee Particulars Screen matching Excel Sheet "Fee Particulars (Page-7)":
/// - 4 KPI Cards: Collected (₹23,90,620 · 88%), Outstanding (₹3,21,300 · 12%), Due (₹2,40,000), Next Month Projected (₹18,00,000)
/// - Class-wise fee collection & dues table (Classes 1 - 10)
/// - Students with dues / fee defaulters with [Send Reminder]
class PrincipalFeesView extends StatelessWidget {
  const PrincipalFeesView({super.key});

  final List<Map<String, dynamic>> _classDues = const [
    {'class': 'Class - 1', 'billed': '₹3,20,000', 'collected': '₹2,80,000', 'due': '₹40,000', 'pct': '87.5%'},
    {'class': 'Class - 2', 'billed': '₹3,50,000', 'collected': '₹3,10,000', 'due': '₹40,000', 'pct': '88.6%'},
    {'class': 'Class - 3', 'billed': '₹3,00,000', 'collected': '₹2,60,000', 'due': '₹40,000', 'pct': '86.7%'},
    {'class': 'Class - 4', 'billed': '₹3,80,000', 'collected': '₹3,40,000', 'due': '₹40,000', 'pct': '89.5%'},
    {'class': 'Class - 5', 'billed': '₹4,00,000', 'collected': '₹3,50,000', 'due': '₹50,000', 'pct': '87.5%'},
    {'class': 'Class - 10', 'billed': '₹6,40,000', 'collected': '₹5,70,000', 'due': '₹70,000', 'pct': '89.1%'},
  ];

  final List<Map<String, String>> _studentsWithDues = const [
    {'name': 'Jatin kalidindi', 'class': 'Class - 1 · Sec A', 'due': '₹15,000', 'parent': 'Sriram Mullapudi (9010234560)'},
    {'name': 'Sai Purushotham Gude', 'class': 'Class - 2 · Sec A', 'due': '₹25,000', 'parent': 'Ramesh Kumar (9618200812)'},
    {'name': 'Mary B', 'class': 'Class - 3 · Sec A', 'due': '₹18,000', 'parent': 'John Doe (9011837901)'},
    {'name': 'Anika Sharma', 'class': 'Class - 1 · Sec A', 'due': '₹12,000', 'parent': 'M. Sharma (9876543210)'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Fee Particulars',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Campus fee collection, outstanding balances & student dues',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildFeeCard('Collected', '₹23,90,620', '88% of billed', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildFeeCard('Outstanding', '₹3,21,300', 'Current dues', const Color(0xFFEF4444))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildFeeCard('Due Today', '₹2,40,000', 'Overdue stage', const Color(0xFFF59E0B))),
            const SizedBox(width: 8),
            Expanded(child: _buildFeeCard('Projected (Next Mo)', '₹18,00,000', 'Term 3 invoicing', const Color(0xFF6366F1))),
          ],
        ),

        const SizedBox(height: 24),

        // Class-wise Dues Table
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
                'Class-wise fee collection',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 16,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                  headingTextStyle: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    fontFamily: 'Urbanist',
                  ),
                  dataTextStyle: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Urbanist',
                  ),
                  columns: const [
                    DataColumn(label: Text('CLASS')),
                    DataColumn(label: Text('BILLED')),
                    DataColumn(label: Text('COLLECTED')),
                    DataColumn(label: Text('DUE')),
                    DataColumn(label: Text('RECOVERY %')),
                  ],
                  rows: _classDues.map((cd) {
                    return DataRow(cells: [
                      DataCell(Text(cd['class'] as String, style: const TextStyle(fontWeight: FontWeight.w700))),
                      DataCell(Text(cd['billed'] as String)),
                      DataCell(Text(cd['collected'] as String, style: const TextStyle(color: Color(0xFF059669)))),
                      DataCell(Text(cd['due'] as String, style: const TextStyle(color: Color(0xFFDC2626)))),
                      DataCell(Text(cd['pct'] as String, style: const TextStyle(fontWeight: FontWeight.w800))),
                    ]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Students with Dues List
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Students with dues',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  Text(
                    '4 flagged',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: _studentsWithDues.map((stu) {
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
                              Text(
                                stu['name']!,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stu['class']} · ${stu['parent']}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              stu['due']!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Payment reminder SMS sent to ${stu['name']}')),
                                );
                              },
                              child: const Text(
                                'Remind →',
                                style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700),
                              ),
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

  Widget _buildFeeCard(String label, String value, String sub, Color c) {
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
