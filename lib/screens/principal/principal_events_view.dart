import 'package:flutter/material.dart';

/// Principal Events Screen matching Excel Sheet "Events (page-11)":
/// - 5 KPI Cards: Upcoming (3), Awaiting Approval (1), Drafts (2), This Month (4), Upcoming Budget (₹1,20,000)
/// - View toggle: List | Calendar
/// - Event Plan List (Annual Sports Meet, Science Fair, Grand Annual Day)
class PrincipalEventsView extends StatefulWidget {
  const PrincipalEventsView({super.key});

  @override
  State<PrincipalEventsView> createState() => _PrincipalEventsViewState();
}

class _PrincipalEventsViewState extends State<PrincipalEventsView> {
  String _viewMode = 'List'; // 'List' or 'Calendar'

  final List<Map<String, String>> _events = const [
    {
      'title': 'Grand Annual Day Celebrations 2026',
      'date': '15 Dec 2026 · 05:00 PM',
      'venue': 'Campus Amphitheater',
      'budget': '₹50,000',
      'status': 'Confirmed',
      'coordinator': 'Keerthana Bangla',
      'color': '0xFF10B981',
    },
    {
      'title': 'Inter-Branch Science & Robotics Exhibition',
      'date': '28 Nov 2026 · 10:00 AM',
      'venue': 'School Auditorium & Lab Hall',
      'budget': '₹30,000',
      'status': 'Awaiting Approval',
      'coordinator': 'Gopi Madem',
      'color': '0xFFF59E0B',
    },
    {
      'title': 'Annual Sports Day & Athletics Meet',
      'date': '05 Dec 2026 · 08:30 AM',
      'venue': 'Main Sports Ground',
      'budget': '₹40,000',
      'status': 'Confirmed',
      'coordinator': 'Rajesh N',
      'color': '0xFF10B981',
    },
    {
      'title': 'Constitution Day Special Assembly',
      'date': '26 Nov 2026 · 09:00 AM',
      'venue': 'Central Assembly Hall',
      'budget': '₹5,000',
      'status': 'Draft',
      'coordinator': 'Ramana',
      'color': '0xFF64748B',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & View Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Events',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Campus cultural, sports & academic calendar plans',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildToggleBtn('List', Icons.list_rounded),
                  _buildToggleBtn('Calendar', Icons.calendar_month_rounded),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 5 KPI Cards
        Row(
          children: [
            Expanded(child: _buildKpiCard('Upcoming', '3', 'Scheduled', const Color(0xFFF97316))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Awaiting Approval', '1', 'Science Fair', const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Drafts', '2', 'Planning stage', const Color(0xFF64748B))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('This Month', '4', 'Nov & Dec', const Color(0xFF0EA5E9))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Budget', '₹1.2 L', 'Allocated', const Color(0xFF10B981))),
          ],
        ),

        const SizedBox(height: 24),

        // Events List View
        if (_viewMode == 'List')
          Column(
            children: _events.map((ev) {
              final isConfirmed = ev['status'] == 'Confirmed';
              final isAwaiting = ev['status'] == 'Awaiting Approval';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.celebration_outlined, color: Color(0xFFEA580C), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev['title']!,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${ev['date']} · ${ev['venue']}',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Coordinator: ${ev['coordinator']} · Budget: ${ev['budget']}',
                                style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isConfirmed
                                ? const Color(0xFFDCFCE7)
                                : isAwaiting
                                    ? const Color(0xFFFEF3C7)
                                    : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ev['status']!,
                            style: TextStyle(
                              color: isConfirmed
                                  ? const Color(0xFF15803D)
                                  : isAwaiting
                                      ? const Color(0xFFB45309)
                                      : const Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: const [
                Icon(Icons.calendar_month_outlined, size: 40, color: Color(0xFF6366F1)),
                SizedBox(height: 12),
                Text('Monthly Event Calendar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 4),
                Text('4 scheduled events marked across November & December 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildToggleBtn(String label, IconData icon) {
    final isSel = _viewMode == label;
    return InkWell(
      onTap: () => setState(() => _viewMode = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: isSel ? const Color(0xFF0F172A) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String sub, Color c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: c, fontSize: 9.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
