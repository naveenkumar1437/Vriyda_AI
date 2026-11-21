import 'package:flutter/material.dart';

/// Principal Exam Time Table Screen matching Excel Sheet "Examinations (Page-6)":
/// - Title: Exam Time Table (Schedule exam, timetable, latest results with toppers)
/// - 4 KPI Cards: Upcoming Exams (2), Schedules Made (7), Papers Printed (100%), Invigilators (11)
/// - Upcoming Exams:
///   - Unit Test - 2 · Half-Yearly (Grade 10 · Mathematics · Published)
///   - Unit Test-1 · Unit Test (Class - 1 · Class 1-A · Published)
/// - Latest Results & Subject Toppers (matching screenshots 2 & 3):
///   - Term 1 - Steel Plant Branch (avg 78% · pass 92% · 25 graded · Ananya Iyer - 78%)
///   - Class-1 Unit Test-1 Hindi (avg 80% · pass 100% · 2 graded · Jonah B - 80%)
///   - Class-1 Unit Test-1 Mathematics (avg 80% · pass 100% · 1 graded · Jatin kalidindi - 80%)
///   - Class-1 Unit Test-1 English (avg 60% · pass 100% · 1 graded · Jatin kalidindi - 60%)
class PrincipalExaminationsView extends StatelessWidget {
  const PrincipalExaminationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Schedule Exam Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Exam Time Table',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Urbanist',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Branch assessments, schedules & performance',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exam scheduling wizard opened')),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Schedule Exam', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
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
            Expanded(child: _buildExamKpi('Upcoming Exams', '2', 'Term 2 Finals', const Color(0xFFEC4899))),
            const SizedBox(width: 8),
            Expanded(child: _buildExamKpi('Schedules Made', '7', 'Classes 1-7', const Color(0xFF6366F1))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildExamKpi('Papers Printed', '100%', 'All ready', const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildExamKpi('Invigilators', '11', 'Assigned', const Color(0xFF0EA5E9))),
          ],
        ),

        const SizedBox(height: 24),

        // Section: Upcoming Exams
        const Text(
          'Upcoming exams',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Scheduled windows across the branch',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 12),

        _buildExamScheduleCard(
          title: 'Unit Test - 2 · Half-Yearly',
          subtitle: 'Grade 10 · Class 10 · Mathematics',
          dates: 'Starts 02 Dec 2026 · 10:00 AM',
          status: 'Published',
        ),
        const SizedBox(height: 10),
        _buildExamScheduleCard(
          title: 'Unit Test-1 · Unit Test',
          subtitle: 'Class - 1 · Class 1-A',
          dates: 'Starts 05 Dec 2026 · 09:30 AM',
          status: 'Published',
        ),

        const SizedBox(height: 24),

        // Section: Latest Results & Toppers (from web screenshot)
        const Text(
          'Latest results',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Class averages · graded assessments',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontFamily: 'Urbanist'),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildResultRow(
                examName: 'Term 1 - Steel Plant Branch',
                meta: 'avg 78% · pass 92% · 25 graded',
                topper: 'Ananya Iyer',
                score: '78%',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildResultRow(
                examName: 'Class-1 Unit Test-1 Hindi',
                meta: 'avg 80% · pass 100% · 2 graded',
                topper: 'Jonah B',
                score: '80%',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildResultRow(
                examName: 'Class-1 Unit Test-1 Mathematics',
                meta: 'avg 80% · pass 100% · 1 graded',
                topper: 'Jatin kalidindi',
                score: '80%',
              ),
              const Divider(height: 20, color: Color(0xFFF1F5F9)),
              _buildResultRow(
                examName: 'Class-1 Unit Test-1 English',
                meta: 'avg 60% · pass 100% · 1 graded',
                topper: 'Jatin kalidindi',
                score: '60%',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExamKpi(String label, String value, String sub, Color c) {
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

  Widget _buildExamScheduleCard({
    required String title,
    required String subtitle,
    required String dates,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFFEC4899), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontFamily: 'Urbanist'),
                ),
                const SizedBox(height: 2),
                Text(
                  dates,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontFamily: 'Urbanist'),
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
              status,
              style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required String examName,
    required String meta,
    required String topper,
    required String score,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.trending_up_rounded, color: Color(0xFF059669), size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                examName,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    meta,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 10.5),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.emoji_events_outlined, size: 13, color: Color(0xFFD97706)),
                  const SizedBox(width: 3),
                  Text(
                    topper,
                    style: const TextStyle(color: Color(0xFFD97706), fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          score,
          style: const TextStyle(
            color: Color(0xFF059669),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
      ],
    );
  }
}
