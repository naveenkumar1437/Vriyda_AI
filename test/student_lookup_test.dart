import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/services/student_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StudentLookup & Garuda AI Tests', () {
    test('StudentService returns empty list when unauthenticated (no static fallback)', () async {
      final students = await StudentService.getStudents();
      expect(students, isEmpty);
    });

    test('StudentService returns null snippet when unauthenticated (no static fallback)', () async {
      final snippet = await StudentService.getStudentSnippet('EDU-STU-2026-00012');
      expect(snippet, isNull);
    });

    test('StudentService returns null AI snippet when unauthenticated (no static fallback)', () async {
      final aiSnippet = await StudentService.getStudentAiSnippet('EDU-STU-2026-00012');
      expect(aiSnippet, isNull);
    });

    test('StudentLookupItem.fromJson parses dynamic student record', () {
      final json = {
        'id': 'EDU-STU-2026-00099',
        'name': 'Dynamic Test Student',
        'branch': 'Campus Central',
        'klass': 'Class - 10',
        'section': 'Section-A',
      };
      final item = StudentLookupItem.fromJson(json);
      expect(item.id, equals('EDU-STU-2026-00099'));
      expect(item.name, equals('Dynamic Test Student'));
      expect(item.branch, equals('Campus Central'));
      expect(item.klass, equals('Class - 10'));
      expect(item.section, equals('Section-A'));
    });

    test('StudentSnippetData.fromJson parses dynamic profile, stats, and Garuda AI bullets', () {
      final json = {
        'profile': {
          'id': 'EDU-STU-2026-00099',
          'name': 'Dynamic Test Student',
          'klass': 'Class - 10',
          'section': 'Section-A',
          'branch': 'Campus Central',
          'gender': 'Female',
        },
        'stats': {
          'attendancePct': 95,
          'examAvg': 88,
          'passed': true,
          'billed': 75000,
          'due': 5000,
          'klass': 'Class - 10',
          'section': 'Section-A',
          'branch': 'Campus Central',
        },
        'bullets': [
          'Academics: Averages 88/100, exceeding benchmark.',
          'Attendance: 95% attendance with 38 of 40 days present.',
          'Fees: ₹5,000 pending due.',
          'Conduct: Clean behavioral record.',
          'Overall: Excelling across all disciplines.',
        ],
        'ai': 'garuda',
      };

      final snippet = StudentSnippetData.fromJson(json);
      expect(snippet.id, equals('EDU-STU-2026-00099'));
      expect(snippet.name, equals('Dynamic Test Student'));
      expect(snippet.gender, equals('Female'));
      expect(snippet.attendancePct, equals(95));
      expect(snippet.examAvg, equals(88));
      expect(snippet.passed, isTrue);
      expect(snippet.billed, equals(75000));
      expect(snippet.due, equals(5000));
      expect(snippet.isGarudaAi, isTrue);
      expect(snippet.bullets.length, equals(5));
      expect(snippet.bullets.any((b) => b.startsWith('Academics:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Attendance:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Fees:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Conduct:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Overall:')), isTrue);
    });
  });
}
