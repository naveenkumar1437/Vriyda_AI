import 'package:flutter/material.dart';

/// Principal Insights View matching Web Screenshots 4, 5, 6:
/// - 6 Top KPI Metrics (Attendance 0%, Pass rate 98%, Syllabus 3%, Faculty rating 4.3, Approvals 0, Open incidents 2)
/// - Key Insights & Recommendations (AI · Garuda) with 6 action cards
/// - Visual Charts: Student Attendance Trend (Line Chart), Fee Collection by Month (Bar Chart),
///   Results by Subject (Progress Bars), Syllabus Coverage by Subject (60% Target indicator)
class PrincipalInsightsView extends StatefulWidget {
  final Function(String routeId)? onNavigate;

  const PrincipalInsightsView({super.key, this.onNavigate});

  @override
  State<PrincipalInsightsView> createState() => _PrincipalInsightsViewState();
}

class _PrincipalInsightsViewState extends State<PrincipalInsightsView> {
  bool _isRegenerating = false;

  void _handleRegenerate() {
    setState(() => _isRegenerating = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isRegenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insights regenerated from latest branch metrics.'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle
        const Text(
          'Insights',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Trends across attendance, fees, results and syllabus for your branch.',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 16),

        // 6 KPI Metric Cards in 2 rows
        _buildKpiRow1(),
        const SizedBox(height: 10),
        _buildKpiRow2(),

        const SizedBox(height: 24),

        // Key Insights & Recommendations (AI Garuda)
        _buildGarudaRecommendationsCard(),

        const SizedBox(height: 24),

        // Charts: Student Attendance Trend
        _buildAttendanceTrendCard(),

        const SizedBox(height: 16),

        // Charts: Fee Collection By Month
        _buildMonthlyFeeCollectionCard(),

        const SizedBox(height: 16),

        // Results by Subject & Syllabus Coverage
        _buildSubjectResultsCard(),

        const SizedBox(height: 16),

        _buildSyllabusCoverageCard(),
      ],
    );
  }

  Widget _buildKpiRow1() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Attendance',
            value: '0%',
            subtext: 'watch',
            dotColor: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Pass rate',
            value: '98%',
            subtext: 'avg',
            dotColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Syllabus',
            value: '3%',
            subtext: 'behind',
            dotColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow2() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Faculty rating',
            value: '4.3',
            subtext: '/5',
            dotColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Approvals',
            value: '0',
            subtext: 'pending',
            dotColor: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            label: 'Open incidents',
            value: '2',
            subtext: 'high',
            dotColor: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    required Color dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Urbanist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                subtext,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Key Insights & Recommendations (AI Garuda) ---
  Widget _buildGarudaRecommendationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFF0D9488), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Key insights & recommendations',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'AI · Garuda',
                  style: TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Generated 9:44 pm from live branch metrics',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontFamily: 'Urbanist',
                ),
              ),
              TextButton(
                onPressed: _isRegenerating ? null : _handleRegenerate,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _isRegenerating
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Regenerate',
                        style: TextStyle(
                          color: Color(0xFF0D9488),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Urbanist',
                        ),
                      ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // 6 Insight Cards
          _buildInsightItem(
            tag: 'ATTENDANCE · ATTENDANCE TREND',
            tagColor: const Color(0xFFB45309),
            body:
                'Latest data shows 0% attendance, though recent trend averages 91%, exceeding the 90% benchmark.',
            suggested:
                'Verify data entry errors immediately and confirm student presence for the current day to ensure accurate tracking.',
            actionLabel: 'Open attendance →',
            onAction: () => widget.onNavigate?.call('view-attendance'),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            tag: 'ACADEMICS · RESULTS BY SUBJECT',
            tagColor: const Color(0xFF047857),
            body:
                'Term 1 results show a 92% pass rate with an average score of 78%, surpassing the 75% target.',
            suggested:
                'Recognize top performer Ananya Iyer and share these positive outcomes with parents to maintain high academic morale.',
            actionLabel: 'Open examinations →',
            onAction: () => widget.onNavigate?.call('view-examinations'),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            tag: 'SYLLABUS · SYLLABUS COVERAGE',
            tagColor: const Color(0xFFB91C1C),
            body:
                'Overall coverage stands at 3%, significantly below the 60% on-track benchmark, with English, Mathematics, and Science at 0%.',
            suggested:
                'Schedule immediate catch-up classes for all core subjects to recover lost instructional time before the next assessment.',
            actionLabel: 'Open academics →',
            onAction: () => widget.onNavigate?.call('view-timetable'),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            tag: 'CONDUCT · DISCIPLINE',
            tagColor: const Color(0xFFB91C1C),
            body:
                'Two open incidents are marked as high severity, requiring urgent attention to maintain a safe learning environment.',
            suggested:
                'Review the incident reports with the discipline committee and implement specific remedial actions for the involved students.',
            actionLabel: 'Open discipline →',
            onAction: () {},
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            tag: 'OPERATIONS · APPROVALS & FRONT OFFICE',
            tagColor: const Color(0xFF4338CA),
            body:
                'Front office reports two open complaints, while teacher appraisals average 4.3/5 with 11 reviews pending.',
            suggested:
                'Address the pending complaints within 48 hours and follow up with instructors to complete outstanding reviews.',
            actionLabel: 'Open front office →',
            onAction: () => widget.onNavigate?.call('view-front-office'),
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            tag: 'OVERALL · ALL MODULES',
            tagColor: const Color(0xFF0F766E),
            body:
                'Academic performance is strong, but syllabus coverage and attendance data integrity require immediate correction to sustain progress.',
            suggested:
                'Prioritize resolving the 0% attendance discrepancy and accelerating curriculum delivery to meet the 60% coverage target.',
            actionLabel: 'Open dashboard →',
            onAction: () => widget.onNavigate?.call('view-overview'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required String tag,
    required Color tagColor,
    required String body,
    required String suggested,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tag,
            style: TextStyle(
              color: tagColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Suggested: $suggested',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              fontFamily: 'Urbanist',
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(
                color: Color(0xFF0D9488),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'Urbanist',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Student Attendance Trend ---
  Widget _buildAttendanceTrendCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Student attendance trend',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                'Avg 91%',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Trend Visual Chart Mockup
          SizedBox(
            height: 110,
            child: Stack(
              children: [
                // Horizontal reference lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRefLine('100%'),
                    _buildRefLine('92%'),
                    _buildRefLine('83%'),
                    _buildRefLine('75%'),
                  ],
                ),
                // Custom drawn trend curve
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36, right: 10, top: 8, bottom: 8),
                    child: CustomPaint(
                      painter: _TrendLinePainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 36, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('9 Sept', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                Text('12 Sept', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
                Text('16 Sept', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefLine(String val) {
    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            val,
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  // --- Fee Collection By Month ---
  Widget _buildMonthlyFeeCollectionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fee collection by month',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Row(
                children: [
                  _buildLegend(const Color(0xFF059669), 'Collected'),
                  const SizedBox(width: 8),
                  _buildLegend(const Color(0xFFD97706), 'Invoiced'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '79% collected this term · ₹24.1 L of ₹30.7 L invoiced · ₹6.8 L outstanding',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart Simulation (Jun - Nov)
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarPair('Jun', 0.90, 0.08),
                _buildBarPair('Jul', 0.05, 0.04),
                _buildBarPair('Aug', 0.05, 0.05),
                _buildBarPair('Sep', 0.04, 0.04),
                _buildBarPair('Oct', 0.05, 0.05),
                _buildBarPair('Nov', 0.45, 0.65),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color c, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBarPair(String month, double colRatio, double invRatio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 10,
              height: 70 * colRatio,
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 3),
            Container(
              width: 10,
              height: 70 * invRatio,
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          month,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
        ),
      ],
    );
  }

  // --- Results by Subject ---
  Widget _buildSubjectResultsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Results by subject · class average',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 14),
          _buildSubjectProgress('Mathematics', 0.78, '78%'),
          const SizedBox(height: 10),
          _buildSubjectProgress('Hindi', 0.80, '80%'),
          const SizedBox(height: 10),
          _buildSubjectProgress('Mathematics (Grade 10)', 0.80, '80%'),
          const SizedBox(height: 10),
          _buildSubjectProgress('English', 0.60, '60%'),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(String subject, double val, String pctText) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            subject,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 32,
          child: Text(
            pctText,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Urbanist',
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // --- Syllabus Coverage by Subject ---
  Widget _buildSyllabusCoverageCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Syllabus coverage by subject',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              Text(
                'Target: 60%',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Urbanist',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSyllabusItem('Hindi', 0.07, '7%'),
          const SizedBox(height: 10),
          _buildSyllabusItem('English', 0.00, '0%'),
          const SizedBox(height: 10),
          _buildSyllabusItem('Mathematics', 0.00, '0%'),
          const SizedBox(height: 10),
          _buildSyllabusItem('Sanskrit', 0.00, '0%'),
          const SizedBox(height: 10),
          _buildSyllabusItem('Science', 0.00, '0%'),
          const SizedBox(height: 10),
          _buildSyllabusItem('Social Studies', 0.00, '0%'),
          const SizedBox(height: 12),
          const Text(
            'Target tick marks 60% on-track benchmark. Orange = below target.',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 10,
              fontStyle: FontStyle.italic,
              fontFamily: 'Urbanist',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusItem(String subject, double val, String pctText) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            subject,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                  minHeight: 8,
                ),
              ),
              // Target indicator at 60%
              Positioned(
                left: 120 * 0.6, // relative indicator position
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 28,
          child: Text(
            pctText,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Urbanist',
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Points representing: 80% (low) -> 100% (high) -> 91% -> 93% -> 80%
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.25, size.height * 0.05);
    path.lineTo(size.width * 0.50, size.height * 0.35);
    path.lineTo(size.width * 0.75, size.height * 0.28);
    path.lineTo(size.width, size.height * 0.75);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
