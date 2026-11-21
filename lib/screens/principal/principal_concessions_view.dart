import 'package:flutter/material.dart';

/// Principal Fee Concession Screen matching Excel Sheet "Concessions (Page-12)":
/// - 4 KPI Cards: Approved (8), Rejected (3), Pending (2), Approved Value (₹85,000)
/// - Concession Applications with Approve / Reject action handling
class PrincipalConcessionsView extends StatefulWidget {
  const PrincipalConcessionsView({super.key});

  @override
  State<PrincipalConcessionsView> createState() =>
      _PrincipalConcessionsViewState();
}

class _PrincipalConcessionsViewState extends State<PrincipalConcessionsView> {
  final Map<String, String> _decisions = {};

  final List<Map<String, String>> _concessions = const [
    {
      'id': 'conc-1',
      'student': 'Aisha Menon',
      'class': 'Grade 10 · Class 10',
      'category': 'Merit Scholarship',
      'amount': '₹10,000',
      'reason': 'Secured 98% overall score in Term 1 exams',
      'date': '12 Nov 2026',
    },
    {
      'id': 'conc-2',
      'student': 'Rahul Verma',
      'class': 'Grade 6 · Class 6-A',
      'category': 'Staff Child Concession',
      'amount': '₹15,000',
      'reason': 'Son of Ramana (Primary Teacher, HR-EMP-00002)',
      'date': '10 Nov 2026',
    },
    {
      'id': 'conc-3',
      'student': 'Kabir Das',
      'class': 'Grade 8 · Class 8-B',
      'category': 'Need-based Financial Aid',
      'amount': '₹8,000',
      'reason': 'Single parent income criteria verified by committee',
      'date': '05 Nov 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Fee Concession',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Scholarships, sibling discounts & staff child fee concessions',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildKpiCard('Approved', '8', 'Scholarships', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Pending', '2', 'Action needed', const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Rejected', '3', 'Ineligible', const Color(0xFFEF4444))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Approved Value', '₹85,000', 'Total fee relief', const Color(0xFFA855F7))),
          ],
        ),

        const SizedBox(height: 24),

        // Concessions List
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
                    'Concession Applications',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '2 awaiting decision',
                    style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Column(
                children: _concessions.map((c) {
                  final decision = _decisions[c['id']];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(c['student']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            Text(
                              c['amount']!,
                              style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${c['class']} · ${c['category']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        const SizedBox(height: 3),
                        Text(c['reason']!, style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (decision == null) ...[
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _decisions[c['id']!] = 'Approved');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Concession approved for ${c['student']}')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF059669),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() => _decisions[c['id']!] = 'Rejected');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Concession rejected for ${c['student']}')),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFDC2626),
                                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Reject', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: decision == 'Approved' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  decision,
                                  style: TextStyle(
                                    color: decision == 'Approved' ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
