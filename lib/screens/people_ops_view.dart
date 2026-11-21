import 'package:flutter/material.dart';

/// People & Ops (Resources) Screen matching the official web screens:
/// - Header: Resources (Classrooms, digital rooms, labs, fleet, hostel & library — by branch)
/// - 6 Summary KPI Cards:
///   1. CLASSROOMS (count, seats · campuses)
///   2. DIGITAL CLASSROOMS (count, % of classrooms)
///   3. LABS (count, science · computer)
///   4. BUSES (count, routes · seats)
///   5. HOSTEL BEDS (count, occupied)
///   6. LIBRARY COPIES (count, catalogued copies)
/// - Resources by branch table:
///   Counts per campus (Branch, Classrooms, Digital, Science labs, Computer labs, Seats, Buses, Routes, Hostel beds, Library, Rented bldgs)
class PeopleOpsView extends StatelessWidget {
  final List<dynamic> branches;
  final Map<String, dynamic>? dashboardData;

  const PeopleOpsView({
    super.key,
    required this.branches,
    this.dashboardData,
  });

  @override
  Widget build(BuildContext context) {
    // Aggregate resources across all branches
    int totalClassrooms = 0;
    int totalSeats = 0;
    int campusesWithClassrooms = 0;

    int totalDigitalClassrooms = 0;
    int totalScienceLabs = 0;
    int totalComputerLabs = 0;

    int totalBuses = 0;
    int totalBusSeats = 0;
    int totalBusRoutes = 0;

    int totalHostelBeds = 0;
    int totalHostelOccupied = 0;

    int totalLibraryCopies = 0;

    for (final b in branches) {
      if (b is! Map) continue;
      final res = (b['resources'] is Map) ? (b['resources'] as Map) : const {};

      final cr = (res['classrooms'] as num?)?.toInt() ?? 0;
      final seats = (res['totalSeats'] as num?)?.toInt() ?? 0;
      if (cr > 0) {
        totalClassrooms += cr;
        campusesWithClassrooms++;
      }
      totalSeats += seats;

      totalDigitalClassrooms += (res['digitalClassrooms'] as num?)?.toInt() ?? 0;
      totalScienceLabs += (res['scienceLabs'] as num?)?.toInt() ?? 0;
      totalComputerLabs += (res['computerLabs'] as num?)?.toInt() ?? 0;

      totalBuses += (res['buses'] as num?)?.toInt() ?? 0;
      totalBusSeats += (res['busSeats'] as num?)?.toInt() ?? 0;
      totalBusRoutes += (res['busRoutes'] as num?)?.toInt() ?? 0;

      // Check both resources.hostelBeds and top-level branch hostelCapacity
      final beds = (res['hostelBeds'] as num?)?.toInt() ??
          (b['hostelCapacity'] as num?)?.toInt() ??
          0;
      final occ = (res['hostelBedsOccupied'] as num?)?.toInt() ??
          (b['hostelOccupied'] as num?)?.toInt() ??
          0;

      totalHostelBeds += beds;
      totalHostelOccupied += occ;
      totalLibraryCopies += (res['libraryCopies'] as num?)?.toInt() ?? 0;
    }

    final digitalPct = totalClassrooms > 0
        ? ((totalDigitalClassrooms / totalClassrooms) * 100).toInt()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Section
        _buildHeader(),
        const SizedBox(height: 14),

        // 2. 6 Summary KPI Cards (2x3 Grid)
        _buildKpiGrid(
          classrooms: totalClassrooms,
          seats: totalSeats,
          campusesWithClassrooms: campusesWithClassrooms,
          digitalClassrooms: totalDigitalClassrooms,
          digitalPct: digitalPct,
          scienceLabs: totalScienceLabs,
          computerLabs: totalComputerLabs,
          buses: totalBuses,
          busRoutes: totalBusRoutes,
          busSeats: totalBusSeats,
          hostelBeds: totalHostelBeds,
          hostelOccupied: totalHostelOccupied,
          libraryCopies: totalLibraryCopies,
        ),
        const SizedBox(height: 16),

        // 3. Resources by branch Table Card
        _buildResourcesByBranchTable(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: const [
            Text(
              'Resources',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Classrooms, digital rooms, labs, fleet, hostel & library — by branch',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiGrid({
    required int classrooms,
    required int seats,
    required int campusesWithClassrooms,
    required int digitalClassrooms,
    required int digitalPct,
    required int scienceLabs,
    required int computerLabs,
    required int buses,
    required int busRoutes,
    required int busSeats,
    required int hostelBeds,
    required int hostelOccupied,
    required int libraryCopies,
  }) {
    return Column(
      children: [
        // Row 1: Classrooms, Digital Classrooms, Labs
        Row(
          children: [
            Expanded(
              child: _buildResourceKpiCard(
                label: 'CLASSROOMS',
                value: classrooms > 0 ? '$classrooms' : '—',
                subtext: '$seats seats · $campusesWithClassrooms campus',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceKpiCard(
                label: 'DIGITAL CLASSROOMS',
                value: digitalClassrooms > 0 ? '$digitalClassrooms' : '—',
                subtext: '$digitalPct% of classrooms',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceKpiCard(
                label: 'LABS',
                value: (scienceLabs + computerLabs) > 0
                    ? '${scienceLabs + computerLabs}'
                    : '—',
                subtext: '$scienceLabs science · $computerLabs computer',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Buses, Hostel Beds, Library Copies
        Row(
          children: [
            Expanded(
              child: _buildResourceKpiCard(
                label: 'BUSES',
                value: buses > 0 ? '$buses' : '—',
                subtext: '$busRoutes routes · $busSeats seats',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceKpiCard(
                label: 'HOSTEL BEDS',
                value: hostelBeds > 0 ? '$hostelBeds' : '—',
                subtext: '$hostelOccupied occupied',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildResourceKpiCard(
                label: 'LIBRARY COPIES',
                value: libraryCopies > 0 ? '$libraryCopies' : '—',
                subtext: 'catalogued copies',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResourceKpiCard({
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: value == '—' ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesByBranchTable() {
    const branchColors = [
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFF06B6D4),
      Color(0xFF6366F1),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF3B82F6),
    ];

    String formatVal(dynamic v) {
      if (v == null) return '—';
      if (v is num && v == 0) return '—';
      final s = v.toString().trim();
      return (s.isEmpty || s == '0') ? '—' : s;
    }

    final campusList = <_CampusRowData>[];
    for (int i = 0; i < branches.length; i++) {
      final b = branches[i];
      if (b is! Map) continue;
      final name = b['name']?.toString() ?? 'Branch ${i + 1}';
      final res = (b['resources'] is Map) ? (b['resources'] as Map) : const {};
      final color = branchColors[i % branchColors.length];

      campusList.add(
        _CampusRowData(
          name: name,
          color: color,
          classrooms: formatVal(res['classrooms']),
          digital: formatVal(res['digitalClassrooms']),
          scienceLabs: formatVal(res['scienceLabs']),
          computerLabs: formatVal(res['computerLabs']),
          seats: formatVal(res['totalSeats']),
          buses: formatVal(res['buses']),
          routes: formatVal(res['busRoutes']),
          hostelBeds: formatVal(res['hostelBeds'] ?? b['hostelCapacity']),
          library: formatVal(res['libraryCopies']),
          rentedBldgs: formatVal(res['rentedBuildings']),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Resources by branch',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Counts per campus · a dash means nothing has been recorded yet',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Horizontally Scrollable Table
          if (campusList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No campus resources recorded',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: DataTable(
              horizontalMargin: 16,
              columnSpacing: 16,
              headingRowHeight: 38,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 44,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Branch', style: _headerStyle)),
                DataColumn(label: Text('Classrooms', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Digital', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Science labs', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Computer labs', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Seats', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Buses', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Routes', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Hostel beds', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Library', style: _headerStyle), numeric: true),
                DataColumn(label: Text('Rented bldgs', style: _headerStyle), numeric: true),
              ],
              rows: campusList.map((campus) {
                return DataRow(
                  cells: [
                    // Branch with color block indicator
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: campus.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            campus.name,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(Text(campus.classrooms, style: _cellStyle(campus.classrooms))),
                    DataCell(Text(campus.digital, style: _cellStyle(campus.digital))),
                    DataCell(Text(campus.scienceLabs, style: _cellStyle(campus.scienceLabs))),
                    DataCell(Text(campus.computerLabs, style: _cellStyle(campus.computerLabs))),
                    DataCell(Text(campus.seats, style: _cellStyle(campus.seats))),
                    DataCell(Text(campus.buses, style: _cellStyle(campus.buses))),
                    DataCell(Text(campus.routes, style: _cellStyle(campus.routes))),
                    DataCell(Text(campus.hostelBeds, style: _cellStyle(campus.hostelBeds))),
                    DataCell(Text(campus.library, style: _cellStyle(campus.library))),
                    DataCell(Text(campus.rentedBldgs, style: _cellStyle(campus.rentedBldgs))),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static const TextStyle _headerStyle = TextStyle(
    color: Color(0xFF475569),
    fontSize: 11,
    fontWeight: FontWeight.w800,
  );

  static TextStyle _cellStyle(String val) {
    return TextStyle(
      color: val == '—' ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
      fontSize: 11.5,
      fontWeight: val == '—' ? FontWeight.w400 : FontWeight.w700,
    );
  }
}

class _CampusRowData {
  final String name;
  final Color color;
  final String classrooms;
  final String digital;
  final String scienceLabs;
  final String computerLabs;
  final String seats;
  final String buses;
  final String routes;
  final String hostelBeds;
  final String library;
  final String rentedBldgs;

  const _CampusRowData({
    required this.name,
    required this.color,
    required this.classrooms,
    required this.digital,
    required this.scienceLabs,
    required this.computerLabs,
    required this.seats,
    required this.buses,
    required this.routes,
    required this.hostelBeds,
    required this.library,
    required this.rentedBldgs,
  });
}
