import 'package:flutter/material.dart';

/// Principal Time Table Screen matching Excel Sheet "Time Table (Page - 5)":
/// - Subtitle: Weekly schedule, periods 1-8, class & day filters, calendar view
/// - 4 KPI Cards: Total Periods (8/day), Covered Today (8/8 · 100%), Substitutions (0 · Regular), Open Slots (0)
/// - Day Selector (Mon, Tue, Wed, Thu, Fri, Sat)
/// - Class Selector Dropdown
/// - Period Schedule Cards (Periods 1 - 8)
/// - AI Timetable button (Generate or Revise)
class PrincipalTimeTableView extends StatefulWidget {
  const PrincipalTimeTableView({super.key});

  @override
  State<PrincipalTimeTableView> createState() => _PrincipalTimeTableViewState();
}

class _PrincipalTimeTableViewState extends State<PrincipalTimeTableView> {
  String _selectedDay = 'Mon';
  String _selectedClass = 'Class - 1';

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _classes = ['Class - 1', 'Class - 2', 'Class - 3', 'Class - 4', 'Class - 5', 'Class - 10'];

  final List<Map<String, String>> _periods = const [
    {
      'period': 'Period 1',
      'time': '09:00 - 09:45 AM',
      'subject': 'Mathematics',
      'teacher': 'Gopi Madem',
      'room': 'Room 101',
      'status': 'Regular',
      'color': '0xFF6366F1',
    },
    {
      'period': 'Period 2',
      'time': '09:45 - 10:30 AM',
      'subject': 'Hindi Literature',
      'teacher': 'Keerthana Bangla',
      'room': 'Room 101',
      'status': 'Regular',
      'color': '0xFF10B981',
    },
    {
      'period': 'Period 3',
      'time': '10:45 - 11:30 AM',
      'subject': 'English Grammar',
      'teacher': 'Ramana',
      'room': 'Room 101',
      'status': 'Regular',
      'color': '0xFF3B82F6',
    },
    {
      'period': 'Period 4',
      'time': '11:30 - 12:15 PM',
      'subject': 'General Science',
      'teacher': 'Pooja K',
      'room': 'Science Lab 1',
      'status': 'Regular',
      'color': '0xFFF59E0B',
    },
    {
      'period': 'Period 5',
      'time': '01:00 - 01:45 PM',
      'subject': 'Social Studies',
      'teacher': 'Kalyan Rao',
      'room': 'Room 101',
      'status': 'Regular',
      'color': '0xFF8B5CF6',
    },
    {
      'period': 'Period 6',
      'time': '01:45 - 02:30 PM',
      'subject': 'Computer Science',
      'teacher': 'Sunil V',
      'room': 'IT Lab 2',
      'status': 'Regular',
      'color': '0xFF06B6D4',
    },
    {
      'period': 'Period 7',
      'time': '02:40 - 03:20 PM',
      'subject': 'Physical Education',
      'teacher': 'Rajesh N',
      'room': 'Sports Ground',
      'status': 'Regular',
      'color': '0xFF14B8A6',
    },
    {
      'period': 'Period 8',
      'time': '03:20 - 04:00 PM',
      'subject': 'Library & Reading',
      'teacher': 'Venkatesh P',
      'room': 'Central Library',
      'status': 'Regular',
      'color': '0xFFEC4899',
    },
  ];

  void _showAiTimetableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 22),
            SizedBox(width: 8),
            Text('AI Timetable Generator', style: TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'AI has analyzed teacher workloads, room availability, and student syllabus pacing. All periods are optimized with zero slot conflicts.',
          style: TextStyle(fontFamily: 'Urbanist', fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable re-optimized and published across branch!')),
              );
            },
            child: const Text('Re-optimize'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & AI Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Time Table',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Branch schedule, periods & classroom allocations',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAiTimetableDialog,
              icon: const Icon(Icons.auto_awesome, size: 14),
              label: const Text('AI Timetable', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildKpi('Total Periods', '8', 'Per day', const Color(0xFF6366F1))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpi('Covered Today', '8/8', '100% active', const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpi('Substitutions', '0', 'All regular', const Color(0xFF3B82F6))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpi('Open Slots', '0', 'None pending', const Color(0xFF059669))),
          ],
        ),

        const SizedBox(height: 20),

        // Class & Day Filters
        Row(
          children: [
            // Class selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedClass,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                  items: _classes.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))).toList(),
                  onChanged: (v) => setState(() => _selectedClass = v!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Day Pills
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _days.map((d) {
                    final isSel = _selectedDay == d;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDay = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            d,
                            style: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Periods List
        Column(
          children: _periods.map((p) {
            final col = Color(int.parse(p['color']!));
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              p['period']!,
                              style: TextStyle(
                                color: col,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                            Text(
                              p['time']!,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontFamily: 'Urbanist',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p['subject']!,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p['teacher']} · ${p['room']}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11.5,
                            fontFamily: 'Urbanist',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p['status']!,
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildKpi(String label, String value, String sub, Color c) {
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
