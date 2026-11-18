import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/services/session_manager.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserSession isOwner tests', () {
    test('Role owner is recognized as owner', () {
      final user = UserSession.fromJson({
        'id': 'charan@example.com',
        'token': 'mock-token',
        'email': 'charan@example.com',
        'name': 'Charan Makkuva',
        'role': 'owner',
        'roles': ['owner'],
        'mustChangePassword': false,
      });

      expect(user.isOwner, isTrue);
    });

    test('Role chairman (case insensitive) is recognized as owner', () {
      final user1 = UserSession.fromJson({
        'id': '1',
        'token': 'mock',
        'email': 'c@test.com',
        'name': 'Chairman User',
        'role': 'chairman',
        'mustChangePassword': false,
      });
      expect(user1.isOwner, isTrue);

      final user2 = UserSession.fromJson({
        'id': '2',
        'token': 'mock',
        'email': 'c@test.com',
        'name': 'Chairman User',
        'role': 'CHAIRMAN',
        'mustChangePassword': false,
      });
      expect(user2.isOwner, isTrue);
    });

    test('Roles array containing owner or chairman is recognized as owner', () {
      final user = UserSession.fromJson({
        'id': '3',
        'token': 'mock',
        'email': 'c@test.com',
        'name': 'Multi Role User',
        'role': 'user',
        'roles': ['user', 'Chairman'],
        'mustChangePassword': false,
      });
      expect(user.isOwner, isTrue);
    });

    test('Roles such as principal, teacher, student are NOT owners', () {
      final roles = ['principal', 'teacher', 'student', 'staff', 'parent', 'admin'];
      for (final r in roles) {
        final user = UserSession.fromJson({
          'id': 'id-$r',
          'token': 'mock',
          'email': '$r@test.com',
          'name': '$r User',
          'role': r,
          'roles': [r],
          'mustChangePassword': false,
        });
        expect(user.isOwner, isFalse, reason: 'Role $r should not be an owner');
      }
    });
  });

  group('Role Under Development Dialog Test', () {
    testWidgets('Under development dialog renders with proper title and message',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => Dialog(
                        backgroundColor: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24.0, vertical: 26.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF59E0B).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.construction_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Role Under Development',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'This role is under development. Please use the web portal to login.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  height: 1.45,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Trigger Dialog'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Trigger Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Role Under Development'), findsOneWidget);
      expect(
        find.text(
            'This role is under development. Please use the web portal to login.'),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Role Under Development'), findsNothing);
    });
  });
}
