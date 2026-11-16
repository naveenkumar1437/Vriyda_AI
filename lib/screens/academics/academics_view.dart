import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/academics_data.dart';

/// Academics View displaying Exam Timetables and Paper-by-Paper Schedules
/// Matching the web portal layout while adhering to mobile Dashboard / Attendance UI/UX
class AcademicsView extends StatefulWidget {
  final Map<String, dynamic>? dashboardData;

  const AcademicsView({super.key, this.dashboardData});

  @override
  State<AcademicsView> createState() => _AcademicsViewState();
}

class _AcademicsViewState extends State<AcademicsView> {
  String _selectedBranch = 'all';
  String _selectedClass = 'All classes';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTimetables = AcademicsData.timetables;

    // Filter timetables
    final filteredTimetables = allTimetables.where((tt) {
      if (_selectedBranch != 'all' && tt.branchId != _selectedBranch) {
        return false;
      }
      if (_selectedClass != 'All classes' && tt.className != _selectedClass) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchExam = tt.examName.toLowerCase().contains(q);
        final matchCategory = tt.examCategory.toLowerCase().contains(q);
        final matchClass = tt.className.toLowerCase().contains(q);
        final matchBranch = tt.branchName.toLowerCase().contains(q);
        final matchProgram = tt.program.toLowerCase().contains(q);
        if (!matchExam && !matchCategory && !matchClass && !matchBranch && !matchProgram) {
          return false;
        }
      }
      return true;
    }).toList();

    // Summary calculations
    final totalTimetables = filteredTimetables.length;
    final totalPapers = filteredTimetables.fold<int>(0, (sum, tt) => sum + tt.papersCount);
    final publishedCount = filteredTimetables.where((tt) => tt.isPublished).length;
    final draftsCount = filteredTimetables.where((tt) => tt.isDraft).length;
    
    // Branches covered calculation (dynamically read from live API if present)
    final branchesFromApi = widget.dashboardData?['branches'] as List<dynamic>?;
    final totalBranchesCount = (branchesFromApi != null && branchesFromApi.isNotEmpty)
        ? branchesFromApi.length
        : 6;
    final coveredBranches = allTimetables.map((t) => t.branchId).toSet().length;

    final branchLabel = _selectedBranch == 'all'
        ? 'all branches'
        : (AcademicsData.availableBranches.firstWhere(
            (b) => b['id'] == _selectedBranch,
            orElse: () => {'label': _selectedBranch},
          )['label'] ?? _selectedBranch);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Context
        _buildHeaderContext(),
        const SizedBox(height: 14),

        // 2. Five KPI Metric Cards (Horizontal scroll)
        _buildKpiCards(
          totalTimetables: totalTimetables,
          publishedCount: publishedCount,
          totalPapers: totalPapers,
          upcomingCount: 0,
          coveredBranches: coveredBranches,
          totalBranchesCount: totalBranchesCount,
          draftsCount: draftsCount,
        ),
        const SizedBox(height: 16),

        // 3. Filter Selectors Row (Branch & Class)
        _buildFilterSelectorsRow(),
        const SizedBox(height: 14),

        // 4. Main Section Card with Timetable List
        _buildTimetableListCard(filteredTimetables, branchLabel, totalPapers),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Component 1: Header Context ---
  Widget _buildHeaderContext() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'SAI RAVINDRA',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    '•',
                    style: TextStyle(color: Color(0xFF7C3AED), fontSize: 10),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'ACADEMIC SUITE',
                    style: TextStyle(
                      color: Color(0xFF6D28D9),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Exam schedules',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Every branch\'s exam timetables — click one for its paper-by-paper schedule',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Component 2: 5 KPI Metric Cards (Attendance-Screen Style: Compact, Friendly, Color-Tinted) ---
  Widget _buildKpiCards({
    required int totalTimetables,
    required int publishedCount,
    required int totalPapers,
    required int upcomingCount,
    required int coveredBranches,
    required int totalBranchesCount,
    required int draftsCount,
  }) {
    final kpis = [
      {
        'label': 'TIMETABLES',
        'value': '$totalTimetables',
        'subtext': '$publishedCount published',
        'icon': Icons.calendar_month_rounded,
        'dotColor': const Color(0xFF7C3AED),
        'textColor': const Color(0xFF6D28D9),
        'bgColor': const Color(0xFFF3E8FF).withValues(alpha: 0.5),
        'borderColor': const Color(0xFFDDD6FE),
      },
      {
        'label': 'PAPERS',
        'value': '$totalPapers',
        'subtext': 'across timetables',
        'icon': Icons.description_rounded,
        'dotColor': const Color(0xFF2563EB),
        'textColor': const Color(0xFF1D4ED8),
        'bgColor': const Color(0xFFEFF6FF).withValues(alpha: 0.5),
        'borderColor': const Color(0xFFBFDBFE),
      },
      {
        'label': 'UPCOMING',
        'value': '$upcomingCount',
        'subtext': 'today or later',
        'icon': Icons.schedule_rounded,
        'dotColor': const Color(0xFFD97706),
        'textColor': const Color(0xFFB45309),
        'bgColor': const Color(0xFFFEF3C7).withValues(alpha: 0.45),
        'borderColor': const Color(0xFFFDE68A),
      },
      {
        'label': 'BRANCHES',
        'value': '$coveredBranches/$totalBranchesCount',
        'subtext': 'active campus',
        'icon': Icons.apartment_rounded,
        'dotColor': const Color(0xFF059669),
        'textColor': const Color(0xFF047857),
        'bgColor': const Color(0xFFD1FAE5).withValues(alpha: 0.45),
        'borderColor': const Color(0xFFA7F3D0),
      },
      {
        'label': 'DRAFTS',
        'value': '$draftsCount',
        'subtext': 'not published',
        'icon': Icons.edit_note_rounded,
        'dotColor': const Color(0xFF64748B),
        'textColor': const Color(0xFF475569),
        'bgColor': const Color(0xFFF1F5F9),
        'borderColor': const Color(0xFFE2E8F0),
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: kpis.map((kpi) {
          final dotColor = kpi['dotColor'] as Color;
          final textColor = kpi['textColor'] as Color;
          final bgColor = kpi['bgColor'] as Color;
          final borderColor = kpi['borderColor'] as Color;
          final icon = kpi['icon'] as IconData;

          return Container(
            width: 104,
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 10, color: dotColor),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        kpi['label'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  kpi['value'] as String,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  kpi['subtext'] as String,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Component 3: Filter Selectors Row (Branch & Class) ---
  Widget _buildFilterSelectorsRow() {
    final branchLabel = _selectedBranch == 'all'
        ? 'All branches'
        : (AcademicsData.availableBranches.firstWhere(
            (b) => b['id'] == _selectedBranch,
            orElse: () => {'label': _selectedBranch},
          )['label'] ?? _selectedBranch);

    return Row(
      children: [
        // Branch Filter Dropdown
        Expanded(
          child: GestureDetector(
            onTap: () => _showBranchPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.apartment_rounded,
                        size: 13,
                        color: Color(0xFF7C3AED),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          branchLabel,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Class Filter Dropdown
        Expanded(
          child: GestureDetector(
            onTap: () => _showClassPicker(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 13,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 100),
                        child: Text(
                          _selectedClass,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Component 4: Timetable List Card ---
  Widget _buildTimetableListCard(
    List<ExamTimetableItem> timetables,
    String branchLabel,
    int totalPapers,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exam timetables · $branchLabel',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${timetables.length} timetables · $totalPapers papers · drafts included',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${timetables.length} Total',
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search exam, class, or subject...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Icon(
                        Icons.clear_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Timetables List
          if (timetables.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 36,
                    color: Color(0xFFCBD5E1),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No exam timetables match your criteria',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...timetables.map((item) => _buildTimetableCard(item)),
        ],
      ),
    );
  }

  // --- Individual Timetable Card ---
  Widget _buildTimetableCard(ExamTimetableItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showPaperScheduleSheet(item);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Exam Title, Category Badge, Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              item.examName,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE9FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.examCategory,
                              style: const TextStyle(
                                color: Color(0xFF6D28D9),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge (Published in green pill)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.isPublished
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.isPublished
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: item.isPublished
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.status,
                            style: TextStyle(
                              color: item.isPublished
                                  ? const Color(0xFF047857)
                                  : const Color(0xFF475569),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),

                // Grid Details: Branch, Program, Class, Dates, Papers
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaDetail(
                        icon: Icons.apartment_rounded,
                        label: 'Branch',
                        value: item.branchName,
                      ),
                    ),
                    Expanded(
                      child: _buildMetaDetail(
                        icon: Icons.school_rounded,
                        label: 'Program',
                        value: item.program,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaDetail(
                        icon: Icons.class_rounded,
                        label: 'Class',
                        value: item.className,
                      ),
                    ),
                    Expanded(
                      child: _buildMetaDetail(
                        icon: Icons.event_rounded,
                        label: 'Dates',
                        value: item.dateRange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Footer Row: Papers Count & "Click for papers schedule" link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.description_rounded,
                            size: 11,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.papersCount} ${item.papersCount == 1 ? 'Paper' : 'Papers'}',
                            style: const TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: const [
                        Text(
                          'View schedule',
                          style: TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF7C3AED),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Modal Bottom Sheet: Paper-by-Paper Schedule ---
  void _showPaperScheduleSheet(ExamTimetableItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.examName} · Paper Schedule',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.className} • ${item.branchName}',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.status,
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              const Text(
                'SCHEDULED PAPERS',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              ...item.papers.map((paper) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paper.subject,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${paper.date} • ${paper.time}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${paper.maxMarks} M',
                              style: const TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            paper.room,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // --- Filter Picker Helpers ---
  void _showBranchPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Campus Branch',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...AcademicsData.availableBranches.map((b) {
                final id = b['id']!;
                final label = b['label']!;
                final isSelected = _selectedBranch == id;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedBranch = id;
                    });
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEDE9FE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF7C3AED),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showClassPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Select Class',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              ...AcademicsData.availableClasses.map((cls) {
                final isSelected = _selectedClass == cls;

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedClass = cls;
                    });
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFEDE9FE)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cls,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF7C3AED)
                                : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color(0xFF7C3AED),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
