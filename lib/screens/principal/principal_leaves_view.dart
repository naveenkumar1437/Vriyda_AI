import 'package:flutter/material.dart';

/// Principal Leaves Screen matching Excel Sheet "Leaves (page-9)":
/// - Sub-Tabs: Leaves | Permissions
/// - Leaves Tab:
///   - Leave Balance (Casual 8, Sick 6, Earned 12)
///   - Leave Requests (Pending review)
///   - Team Leave Balance (84 days)
///   - Team Leave Requests (Ramana, Gopi Madem with Approve/Reject)
/// - Permissions Tab:
///   - 4 KPI Cards: Permissions (14), Total Hours (28h), Staff Paid (100%), Half Days (1)
///   - Permissions list with [+ Apply Permission] button
class PrincipalLeavesView extends StatefulWidget {
  const PrincipalLeavesView({super.key});

  @override
  State<PrincipalLeavesView> createState() => _PrincipalLeavesViewState();
}

class _PrincipalLeavesViewState extends State<PrincipalLeavesView> {
  String _activeTab = 'Leaves'; // 'Leaves' or 'Permissions'

  final Map<String, String> _leaveDecisions = {};

  final List<Map<String, String>> _teamRequests = const [
    {
      'id': 'lr-1',
      'name': 'Ramana',
      'role': 'Primary Teacher',
      'type': 'Sick Leave',
      'dates': '10 Nov - 11 Nov (2 days)',
      'reason': 'Viral fever and medical rest advised',
    },
    {
      'id': 'lr-2',
      'name': 'Gopi Madem',
      'role': 'Mathematics Instructor',
      'type': 'Casual Leave',
      'dates': '24 Nov (1 day)',
      'reason': 'Family emergency out of station',
    },
    {
      'id': 'lr-3',
      'name': 'Lakshmi Rao',
      'role': 'Receptionist',
      'type': 'Casual Leave',
      'dates': '28 Nov (1 day)',
      'reason': 'Personal administrative appointment',
    },
  ];

  final List<Map<String, String>> _permissionsList = const [
    {'name': 'Keerthana Bangla', 'date': '20 Nov 2026', 'duration': '2 hours (02:00 - 04:00 PM)', 'reason': 'Medical clinic visit', 'status': 'Approved'},
    {'name': 'Suresh Kumar', 'date': '18 Nov 2026', 'duration': '1.5 hours (10:00 - 11:30 AM)', 'reason': 'Bank branch token appointment', 'status': 'Approved'},
    {'name': 'Venkatesh P', 'date': '15 Nov 2026', 'duration': '2 hours (03:00 - 05:00 PM)', 'reason': 'Book publisher logistics meet', 'status': 'Approved'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Leaves & Permissions',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Personal leave balance, staff requests & gate permissions',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
                ),
              ],
            ),
            if (_activeTab == 'Permissions')
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permission request form opened')),
                  );
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Apply', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
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
              _buildSegmentPill('Leaves'),
              const SizedBox(width: 4),
              _buildSegmentPill('Permissions'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_activeTab == 'Leaves') _buildLeavesContent(),
        if (_activeTab == 'Permissions') _buildPermissionsContent(),
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

  // --- Leaves Content ---
  Widget _buildLeavesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // My Leave Balances
        const Text(
          'My Leave Balance',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildBalanceCard('Casual Leave', '8 / 12', 'Available', const Color(0xFF059669))),
            const SizedBox(width: 8),
            Expanded(child: _buildBalanceCard('Sick Leave', '6 / 10', 'Available', const Color(0xFF2563EB))),
            const SizedBox(width: 8),
            Expanded(child: _buildBalanceCard('Earned Leave', '12 / 15', 'Available', const Color(0xFF7C3AED))),
          ],
        ),

        const SizedBox(height: 20),

        // Team Leave Requests Section
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
                    'Team Leave Requests',
                    style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '3 pending',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Column(
                children: _teamRequests.map((req) {
                  final decision = _leaveDecisions[req['id']];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
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
                          children: [
                            Text(req['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(4)),
                              child: Text(req['type']!, style: const TextStyle(color: Color(0xFFB45309), fontSize: 9.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text('${req['role']} · ${req['dates']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        const SizedBox(height: 3),
                        Text('Reason: ${req['reason']}', style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (decision == null) ...[
                              ElevatedButton(
                                onPressed: () {
                                  setState(() => _leaveDecisions[req['id']!] = 'Approved');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Leave approved for ${req['name']}')),
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
                                  setState(() => _leaveDecisions[req['id']!] = 'Rejected');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Leave rejected for ${req['name']}')),
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

  // --- Permissions Content ---
  Widget _buildPermissionsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildBalanceCard('Permissions', '14', 'This month', const Color(0xFF6366F1))),
            const SizedBox(width: 8),
            Expanded(child: _buildBalanceCard('Total Hours', '28h', 'Accumulated', const Color(0xFF0EA5E9))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildBalanceCard('Staff Paid', '100%', 'No wage penalty', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildBalanceCard('Half Days', '1', 'Current term', const Color(0xFFF59E0B))),
          ],
        ),

        const SizedBox(height: 20),

        // Permissions Log
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
                'Recent Staff Permissions Log',
                style: TextStyle(color: Color(0xFF0F172A), fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Column(
                children: _permissionsList.map((p) {
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
                              Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('${p['date']} · ${p['duration']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(p['reason']!, style: const TextStyle(color: Color(0xFF334155), fontSize: 10.5, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Approved', style: TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.bold)),
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

  Widget _buildBalanceCard(String label, String value, String sub, Color c) {
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
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
