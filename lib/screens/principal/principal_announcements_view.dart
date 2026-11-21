import 'package:flutter/material.dart';

/// Principal Announcements Screen matching Excel Sheet "Announcements (Page-14)":
/// - 4 KPI Cards: Active Circulars (4), Sent This Week (2), Parent Read Rate (89%), Drafts (1)
/// - Audience Tabs: All | Parents | Teachers | Students
/// - Announcement Circular Cards with [+ Create Announcement] dialog
class PrincipalAnnouncementsView extends StatefulWidget {
  const PrincipalAnnouncementsView({super.key});

  @override
  State<PrincipalAnnouncementsView> createState() =>
      _PrincipalAnnouncementsViewState();
}

class _PrincipalAnnouncementsViewState
    extends State<PrincipalAnnouncementsView> {
  String _selectedAudience = 'All';

  final List<Map<String, String>> _announcements = const [
    {
      'title': 'Term 2 Examination Schedule & Guidelines',
      'audience': 'Parents & Students',
      'audienceType': 'Parents',
      'date': '20 Nov 2026 · 11:30 AM',
      'body':
          'Final exam timetables for Classes 1 to 10 have been published. Please ensure timely fee settlement and hall ticket collection from the front office.',
      'readRate': '92% read',
      'badgeColor': '0xFF3B82F6',
    },
    {
      'title': 'Winter Vacation & Revision Camp Schedule',
      'audience': 'All Campus',
      'audienceType': 'All',
      'date': '18 Nov 2026 · 02:15 PM',
      'body':
          'Campus will observe winter vacation starting 24th December. Special doubt-clearing sessions for Class 10 board students will continue online.',
      'readRate': '88% read',
      'badgeColor': '0xFF10B981',
    },
    {
      'title': 'Parent-Teacher Meeting (PTM) for Term 1 Review',
      'audience': 'Parents',
      'audienceType': 'Parents',
      'date': '15 Nov 2026 · 09:00 AM',
      'body':
          'PTM scheduled this Saturday between 10:00 AM to 01:00 PM. Progress cards will be handed over by respective class teachers.',
      'readRate': '95% read',
      'badgeColor': '0xFFF59E0B',
    },
    {
      'title': 'Staff Development Workshop: AI in the Classroom',
      'audience': 'Teaching Staff',
      'audienceType': 'Teachers',
      'date': '12 Nov 2026 · 03:00 PM',
      'body':
          'All teachers must attend the interactive session on utilizing lesson planning tools and smart board resources in Room 102.',
      'readRate': '100% read',
      'badgeColor': '0xFF8B5CF6',
    },
  ];

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Circular Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Circular Title', hintText: 'e.g. Sports Day Schedule')),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Target Audience', hintText: 'Parents, Teachers, All')),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Announcement Details'), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAB308),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement broadcasted successfully to campus!')),
              );
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedAudience == 'All'
        ? _announcements
        : _announcements.where((a) => a['audienceType'] == _selectedAudience || a['audienceType'] == 'All').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Create Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Announcements',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Campus-wide circulars, SMS broadcasts & student notifications',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontFamily: 'Urbanist'),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showCreateDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Create', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4 KPI Cards
        Row(
          children: [
            Expanded(child: _buildKpiCard('Active Circulars', '4', 'Campus-wide', const Color(0xFFEAB308))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Sent This Week', '2', 'SMS + App', const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildKpiCard('Parent Read Rate', '89%', 'High engagement', const Color(0xFF0EA5E9))),
            const SizedBox(width: 8),
            Expanded(child: _buildKpiCard('Drafts', '1', 'Holiday notice', const Color(0xFF64748B))),
          ],
        ),

        const SizedBox(height: 20),

        // Audience Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Parents', 'Teachers', 'Students'].map((aud) {
              final isSel = _selectedAudience == aud;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(aud),
                  selected: isSel,
                  onSelected: (val) {
                    if (val) setState(() => _selectedAudience = aud);
                  },
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : const Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w600,
                    fontFamily: 'Urbanist',
                  ),
                  selectedColor: const Color(0xFF0F172A),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSel ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Announcements Cards
        Column(
          children: filtered.map((a) {
            final col = Color(int.parse(a['badgeColor']!));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          a['audience']!,
                          style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        a['date']!,
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'Urbanist'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a['title']!,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a['body']!,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 11.5,
                      height: 1.35,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        a['readRate']!,
                        style: const TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Resent SMS blast to unread recipients')),
                          );
                        },
                        child: const Text('Resend blast →', style: TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
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
