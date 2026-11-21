import 'package:flutter/material.dart';

/// Principal Attendance Screen matching Web Screenshots 7, 8, 9, 10, 11:
/// - Subtitle: Saturday, 21 November 2026 · daily attendance | Date: 21-11-2026
/// - Sub-Tabs: Students | Staff
/// - Students Tab:
///   - Class dropdown filter (All classes, Class - 1 to 10, Unassigned)
///   - Section dropdown filter (All sections, No section, Section-A, Section-B)
///   - Right counter: All classes · 0/43 present
///   - 5 KPI cards: Total 43, Present 0, Absent 0, On leave 0, Not marked 43
///   - Absent List: "Students absent · 0" (Attendance hasn't been marked for these students yet.)
/// - Staff Tab:
///   - Type dropdown filter: All staff (Teaching, Non-teaching)
///   - Right counter: Teaching 0/11 · Non-teaching 0/14 present
///   - Teaching staff 5 KPI cards (Total 11, Present 0, Absent 1, On leave 0, Not marked 10)
///   - Non-teaching staff 5 KPI cards (Total 14, Present 0, Absent 0, On leave 0, Not marked 14)
///   - Staff absent or on leave · 1 Table with Keerthana Bangla (Absent)
class PrincipalAttendanceView extends StatefulWidget {
  const PrincipalAttendanceView({super.key});

  @override
  State<PrincipalAttendanceView> createState() =>
      _PrincipalAttendanceViewState();
}

class _PrincipalAttendanceViewState extends State<PrincipalAttendanceView> {
  String _activeTab = 'Students'; // 'Students' or 'Staff'

  // Student filters
  String _selectedClass = 'All classes';
  String _selectedSection = 'All sections';

  // Staff filter
  String _selectedStaffType = 'All staff';

  final List<String> _classList = [
    'All classes',
    'Class - 1',
    'Class - 2',
    'Class - 3',
    'Class - 4',
    'Class - 5',
    'Class - 6',
    'Class - 9',
    'Class - 10',
    'Unassigned',
  ];

  final List<String> _sectionList = [
    'All sections',
    'No section',
    'Section-A',
    'Section-B',
  ];

  final List<String> _staffTypeList = [
    'All staff',
    'Teaching',
    'Non-teaching',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Date Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Attendance for today',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Saturday, 21 November 2026 · daily attendance',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                ],
              ),
            ),
            // Date pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  Text(
                    '21-11-2026',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Urbanist',
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Sub-tabs: Students | Staff
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSegmentPill('Students'),
              const SizedBox(width: 4),
              _buildSegmentPill('Staff'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_activeTab == 'Students') _buildStudentsContent(),
        if (_activeTab == 'Staff') _buildStaffContent(),
      ],
    );
  }

  Widget _buildSegmentPill(String tab) {
    final isSel = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
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

  // --- Students Content ---
  Widget _buildStudentsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Filters Row
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                label: 'Class',
                value: _selectedClass,
                items: _classList,
                onChanged: (v) => setState(() => _selectedClass = v!),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFilterDropdown(
                label: 'Section',
                value: _selectedSection,
                items: _sectionList,
                onChanged: (v) => setState(() => _selectedSection = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_selectedClass · 0/43 present',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Urbanist',
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 5 KPI Cards for Students
        _buildFiveKpis(
          totalVal: '43',
          totalSub: '16 sections',
          presentVal: '0',
          presentSub: '0%',
          absentVal: '0',
          absentSub: '0%',
          leaveVal: '0',
          leaveSub: '0%',
          notMarkedVal: '43',
          notMarkedSub: '16 sections pending',
        ),

        const SizedBox(height: 20),

        // Students Absent Section
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Students absent · 0',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              SizedBox(height: 3),
              Text(
                'All classes · absent or on leave on 21 Nov',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
              SizedBox(height: 24),
              Center(
                child: Text(
                  "Attendance hasn't been marked for these students yet.",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
              SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  // --- Staff Content ---
  Widget _buildStaffContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Staff filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 160,
              child: _buildFilterDropdown(
                label: 'Type',
                value: _selectedStaffType,
                items: _staffTypeList,
                onChanged: (v) => setState(() => _selectedStaffType = v!),
              ),
            ),
            const Text(
              'Teaching 0/11 · Non-teaching 0/14 present',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Teaching Staff Section
        if (_selectedStaffType == 'All staff' || _selectedStaffType == 'Teaching') ...[
          const Text(
            'Teaching staff',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 10),
          _buildFiveKpis(
            totalVal: '11',
            totalSub: 'Staff',
            presentVal: '0',
            presentSub: '0%',
            absentVal: '1',
            absentSub: 'Teacher',
            leaveVal: '0',
            leaveSub: 'None',
            notMarkedVal: '10',
            notMarkedSub: 'Pending',
          ),
          const SizedBox(height: 18),
        ],

        // Non-teaching Staff Section
        if (_selectedStaffType == 'All staff' || _selectedStaffType == 'Non-teaching') ...[
          const Text(
            'Non-teaching staff',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 10),
          _buildFiveKpis(
            totalVal: '14',
            totalSub: 'Staff',
            presentVal: '0',
            presentSub: '0%',
            absentVal: '0',
            absentSub: 'None',
            leaveVal: '0',
            leaveSub: 'None',
            notMarkedVal: '14',
            notMarkedSub: 'Pending',
          ),
          const SizedBox(height: 20),
        ],

        // Staff Absent or On Leave Table
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
                'Staff absent or on leave · 1',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'All staff · 0/25 present on 21 Nov',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Urbanist',
                ),
              ),
              const SizedBox(height: 16),

              // Staff Table Header & Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 0,
                  columnSpacing: 18,
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
                    DataColumn(label: Text('NAME')),
                    DataColumn(label: Text('EMPLOYEE ID')),
                    DataColumn(label: Text('DESIGNATION')),
                    DataColumn(label: Text('DEPARTMENT')),
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('LEAVE TYPE')),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        const DataCell(Text(
                          'Keerthana Bangla',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        )),
                        const DataCell(Text(
                          'HR-EMP-00027',
                          style: TextStyle(color: Color(0xFF64748B)),
                        )),
                        const DataCell(Text('Teacher')),
                        const DataCell(Text('Hindi')),
                        const DataCell(Text('Teaching')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Absent',
                              style: TextStyle(
                                color: Color(0xFFB91C1C),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const DataCell(Text('—')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Urbanist',
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Urbanist',
              ),
              items: items.map((it) {
                return DropdownMenuItem<String>(
                  value: it,
                  child: Text(it),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFiveKpis({
    required String totalVal,
    required String totalSub,
    required String presentVal,
    required String presentSub,
    required String absentVal,
    required String absentSub,
    required String leaveVal,
    required String leaveSub,
    required String notMarkedVal,
    required String notMarkedSub,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildMiniKpiCard('Total', totalVal, totalSub, const Color(0xFF64748B)),
          const SizedBox(width: 8),
          _buildMiniKpiCard('Present', presentVal, presentSub, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildMiniKpiCard('Absent', absentVal, absentSub, const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildMiniKpiCard('On leave', leaveVal, leaveSub, const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildMiniKpiCard('Not marked', notMarkedVal, notMarkedSub, const Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildMiniKpiCard(String label, String value, String sub, Color dotColor) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 5, height: 5, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Urbanist',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Urbanist',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              fontFamily: 'Urbanist',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
