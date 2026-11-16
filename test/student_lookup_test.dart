import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/services/student_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StudentLookup & Garuda AI Tests', () {
    test('StudentService returns default institutional students', () async {
      final students = await StudentService.getStudents();
      expect(students, isNotEmpty);
      expect(students.any((s) => s.name.toLowerCase().contains('jatin')), isTrue);
    });

    test('StudentService fetches student snippet for Jatin kalidindi', () async {
      final snippet = await StudentService.getStudentSnippet('EDU-STU-2026-00012');
      expect(snippet, isNotNull);
      expect(snippet!.name.toLowerCase(), contains('jatin'));
      expect(snippet.attendancePct, equals(92));
      expect(snippet.examAvg, equals(32));
      expect(snippet.due, equals(65000));
      expect(snippet.bullets.length, equals(5));
      expect(snippet.bullets.any((b) => b.startsWith('Academics:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Attendance:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Fees:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Conduct:')), isTrue);
      expect(snippet.bullets.any((b) => b.startsWith('Overall:')), isTrue);
    });

    test('StudentService fetches Garuda AI student snippet', () async {
      final aiSnippet = await StudentService.getStudentAiSnippet('EDU-STU-2026-00012');
      expect(aiSnippet, isNotNull);
      expect(aiSnippet!.isGarudaAi, isTrue);
      expect(aiSnippet.bullets.length, equals(5));
    });
  });
}
