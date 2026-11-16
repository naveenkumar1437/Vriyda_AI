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
  final String branchId; // e.g. 'steel-plant'
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

/// Data repository containing exam timetable data matching the web portal
class AcademicsData {
  static const List<ExamTimetableItem> timetables = [
    ExamTimetableItem(
      id: 'tt-001',
      examName: 'Unit Test - 2',
      examCategory: 'Half-Yearly',
      branchId: 'steel-plant',
      branchName: 'Steel Plant Branch',
      program: 'Grade 10',
      className: 'Class 10 - Mathematics',
      dateRange: '5 Nov 2026',
      academicYear: '2026–27',
      papersCount: 1,
      status: 'Published',
      papers: [
        ExamPaperItem(
          id: 'p-101',
          subject: 'Mathematics',
          date: '5 Nov 2026',
          time: '09:00–10:30',
          maxMarks: 25,
          passMarks: 9,
          room: 'HTL-ROOM-2026-00007',
          invigilator: 'Dr. Neha Gupta',
        ),
      ],
    ),
    ExamTimetableItem(
      id: 'tt-002',
      examName: 'Unit Test-1',
      examCategory: 'Unit Test',
      branchId: 'steel-plant',
      branchName: 'Steel Plant Branch',
      program: 'Class - 1',
      className: 'Class 1-A',
      dateRange: '17 Aug 2026 → 19 Aug 2026',
      academicYear: '2026–27',
      papersCount: 3,
      status: 'Published',
      papers: [
        ExamPaperItem(
          id: 'p-201',
          subject: 'English',
          date: '17 Aug 2026',
          time: '09:00–10:30',
          maxMarks: 25,
          passMarks: 9,
          room: 'HTL-ROOM-2026-00007',
          invigilator: 'Bhavya Malli',
        ),
        ExamPaperItem(
          id: 'p-202',
          subject: 'Hindi',
          date: '18 Aug 2026',
          time: '09:00–10:30',
          maxMarks: 25,
          passMarks: 9,
          room: 'HTL-ROOM-2026-00007',
          invigilator: 'Bhavya Malli',
        ),
        ExamPaperItem(
          id: 'p-203',
          subject: 'Mathematics',
          date: '19 Aug 2026',
          time: '09:00–10:30',
          maxMarks: 25,
          passMarks: 9,
          room: 'HTL-ROOM-2026-00007',
          invigilator: 'Jeevani Boppudi',
        ),
      ],
    ),
  ];

  static List<String> get availableClasses {
    final classes = {'All classes'};
    for (final tt in timetables) {
      classes.add(tt.className);
    }
    return classes.toList();
  }

  static List<Map<String, String>> get availableBranches {
    return [
      {'id': 'all', 'label': 'All branches'},
      {'id': 'steel-plant', 'label': 'Steel Plant Branch'},
      {'id': 'gachibowli', 'label': 'Gachibowli Campus'},
      {'id': 'maddipalem', 'label': 'Maddipalem'},
      {'id': 'kukatpally', 'label': 'Kukatpally Campus'},
      {'id': 'kondapur', 'label': 'Kondapur Branch'},
      {'id': 'madhapur', 'label': 'Madhapur Branch'},
    ];
  }
}
