/// Model representing an individual exam paper schedule within a timetable
class ExamPaperItem {
  final String id;
  final String subject;
  final String date;
  final String time;
  final int maxMarks;
  final int passMarks;
  final String room;
  final String invigilator;

  const ExamPaperItem({
    required this.id,
    required this.subject,
    required this.date,
    required this.time,
    required this.maxMarks,
    required this.passMarks,
    required this.room,
    required this.invigilator,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject': subject,
        'date': date,
        'time': time,
        'maxMarks': maxMarks,
        'passMarks': passMarks,
        'room': room,
        'invigilator': invigilator,
      };
}

/// Model representing an exam timetable covering a branch, program, and class
class ExamTimetableItem {
  final String id;
  final String examName;
  final String examCategory; // e.g. 'Half-Yearly', 'Unit Test', 'Annual'
  final String branchId; // branch ID from API
  final String branchName;
  final String program; // e.g. 'Grade 10', 'Class - 1'
  final String className; // e.g. 'Class 10 - Mathematics', 'Class 1-A'
  final String dateRange; // e.g. '5 Nov 2026' or '17 Aug 2026 → 19 Aug 2026'
  final String academicYear; // e.g. '2026–27'
  final int papersCount;
  final String status; // 'Published', 'Draft', 'Archived'
  final List<ExamPaperItem> papers;

  const ExamTimetableItem({
    required this.id,
    required this.examName,
    required this.examCategory,
    required this.branchId,
    required this.branchName,
    required this.program,
    required this.className,
    required this.dateRange,
    this.academicYear = '2026–27',
    required this.papersCount,
    required this.status,
    required this.papers,
  });

  bool get isPublished => status.toLowerCase() == 'published';
  bool get isDraft => status.toLowerCase() == 'draft';
}

/// Data repository containing exam timetable data matching the live API & web portal
class AcademicsData {
  /// Parses real-time exam timetables and papers from the live GET /owner-dashboard payload
  static List<ExamTimetableItem> parseFromDashboard(Map<String, dynamic>? dashboardData) {
    if (dashboardData == null) return const [];
    final exams = dashboardData['exams'];
    if (exams is! Map<String, dynamic>) return const [];

    final rawTimetables = exams['timetables'];
    final rawPapers = exams['papers'];
    if (rawTimetables is! List || rawTimetables.isEmpty) return const [];

    // Group papers by timetableId
    final Map<String, List<ExamPaperItem>> papersByTimetable = {};
    if (rawPapers is List) {
      for (final p in rawPapers) {
        if (p is! Map<String, dynamic>) continue;
        final ttId = p['timetableId']?.toString() ?? '';
        final course = p['course']?.toString() ?? 'Subject';
        final rawDate = p['date']?.toString() ?? '';
        final start = p['start']?.toString() ?? '';
        final end = p['end']?.toString() ?? '';
        final room = p['room']?.toString() ?? 'Room TBD';
        final instructor = p['instructor']?.toString() ?? 'Not assigned';
        final maxMarks = (p['maxMarks'] as num?)?.toInt() ?? 100;
        final passingMarks = (p['passingMarks'] as num?)?.toInt() ?? 35;

        final formattedDate = formatDate(rawDate);
        final formattedTime = formatTimeRange(start, end);

        final paperItem = ExamPaperItem(
          id: 'paper-$ttId-$course',
          subject: course,
          date: formattedDate,
          time: formattedTime,
          maxMarks: maxMarks,
          passMarks: passingMarks,
          room: room,
          invigilator: instructor,
        );

        papersByTimetable.putIfAbsent(ttId, () => []).add(paperItem);
      }
    }

    final List<ExamTimetableItem> result = [];
    for (final tt in rawTimetables) {
      if (tt is! Map<String, dynamic>) continue;
      final id = tt['id']?.toString() ?? '';
      final title = tt['title']?.toString() ?? 'Exam';
      final examType = tt['examType']?.toString() ?? 'Exam';
      final branch = tt['branch']?.toString() ?? 'Main Branch';
      final branchId = slugify(branch);
      final program = tt['program']?.toString() ?? '';
      final studentGroup = tt['studentGroup']?.toString() ?? '';
      final rawStartDate = tt['startDate']?.toString() ?? '';
      final rawEndDate = tt['endDate']?.toString() ?? '';
      final dateRange = formatDateRange(rawStartDate, rawEndDate);
      final academicYear = (tt['academicYear']?.toString() ?? '2026-27').replaceAll('-', '–');
      final status = tt['status']?.toString() ?? 'Published';
      final paperCount = (tt['paperCount'] as num?)?.toInt() ?? 0;

      final papers = papersByTimetable[id] ?? [];

      result.add(ExamTimetableItem(
        id: id,
        examName: title,
        examCategory: examType,
        branchId: branchId,
        branchName: branch,
        program: program,
        className: studentGroup,
        dateRange: dateRange,
        academicYear: academicYear,
        papersCount: papers.isNotEmpty ? papers.length : paperCount,
        status: status,
        papers: papers,
      ));
    }

    return result;
  }

  /// Parses active branches dynamically from dashboard payload
  static List<Map<String, String>> parseBranchesFromDashboard(Map<String, dynamic>? dashboardData) {
    final list = <Map<String, String>>[
      {'id': 'all', 'label': 'All branches'},
    ];
    if (dashboardData != null && dashboardData['branches'] is List) {
      for (final b in dashboardData['branches']) {
        if (b is Map<String, dynamic>) {
          final name = b['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            list.add({
              'id': slugify(name),
              'label': name,
            });
          }
        }
      }
    }
    return list;
  }

  /// Helper: converts YYYY-MM-DD to DD Mon YYYY (e.g. 2026-11-05 -> 5 Nov 2026)
  static String formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final parts = isoDate.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '$day ${months[month - 1]} $year';
      }
    } catch (_) {}
    return isoDate;
  }

  /// Helper: formats date range (e.g. 5 Nov 2026 or 17 Aug 2026 → 19 Aug 2026)
  static String formatDateRange(String start, String end) {
    final s = formatDate(start);
    final e = formatDate(end);
    if (s.isEmpty) return e;
    if (e.isEmpty || s == e) return s;
    return '$s → $e';
  }

  /// Helper: formats time range from HH:MM:SS to HH:MM–HH:MM (e.g. 11:00–12:00)
  static String formatTimeRange(String start, String end) {
    String cleanTime(String t) {
      final parts = t.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return t;
    }

    if (start.isEmpty && end.isEmpty) return 'TBD';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '${cleanTime(start)}–${cleanTime(end)}';
    }
    return cleanTime(start.isNotEmpty ? start : end);
  }

  /// Helper: converts name to URL/ID friendly slug
  static String slugify(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Timetables container (dynamically parsed from API)
  static const List<ExamTimetableItem> timetables = [];

  static List<String> get availableClasses => const ['All classes'];

  static const List<Map<String, String>> availableBranches = [
    {'id': 'all', 'label': 'All branches'},
  ];
}
