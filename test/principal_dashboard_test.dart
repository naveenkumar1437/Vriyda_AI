import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vriyda_ai/screens/principal_dashboard_screen.dart';
import 'package:vriyda_ai/services/session_manager.dart';

void main() {
  test('UserSession identifies principal role correctly', () {
    final principalSession = UserSession(
      id: 'principal-1',
      token: 'token-abc',
      email: 'principal@innovorex.co.in',
      name: 'Vinod Kumar',
      role: 'Principal',
      mustChangePassword: false,
    );

    expect(principalSession.isPrincipal, isTrue);
    expect(principalSession.isOwner, isFalse);

    final ownerSession = UserSession(
      id: 'owner-1',
      token: 'token-xyz',
      email: 'owner@innovorex.co.in',
      name: 'Charan Makkuva',
      role: 'owner',
      mustChangePassword: false,
    );

    expect(ownerSession.isOwner, isTrue);
    expect(ownerSession.isPrincipal, isFalse);

    final teacherSession = UserSession(
      id: 'teacher-1',
      token: 'token-123',
      email: 'teacher@innovorex.co.in',
      name: 'Teacher One',
      role: 'Teacher',
      mustChangePassword: false,
    );

    expect(teacherSession.isOwner, isFalse);
    expect(teacherSession.isPrincipal, isFalse);
  });

  testWidgets('PrincipalDashboardScreen renders and switches tabs smoothly',
      (WidgetTester tester) async {
    final principal = UserSession(
      id: 'HR-EMP-0005',
      token: 'fake-token',
      email: 'principal@innovorex.co.in',
      name: 'Vinod Kumar',
      role: 'Principal',
      branchName: 'Steel Plant Branch',
      mustChangePassword: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PrincipalDashboardScreen(user: principal),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Principal Header
    expect(find.text('Vinod Kumar'), findsOneWidget);
    expect(find.textContaining('Principal · HR-EMP-0005'), findsWidgets);

    // Verify top tabs exist
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Approvals'), findsWidgets);
    expect(find.text('Students'), findsWidgets);
    expect(find.text('Staff'), findsWidgets);

    // Verify Overview content (Needs you now, School at a glance, Attendance)
    expect(find.text('NEEDS YOU NOW'), findsOneWidget);
    expect(find.text('SCHOOL AT A GLANCE'), findsOneWidget);
    expect(find.text('ATTENDANCE & ABSENTEES'), findsOneWidget);

    // Tap Approvals tab
    await tester.tap(find.text('Approvals').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('16 waiting for you'), findsWidgets);

    // Tap Students tab
    await tester.tap(find.text('Students').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Student Management'), findsOneWidget);
    expect(find.textContaining('Jatin kalidindi'), findsOneWidget);

    // Tap Staff tab
    await tester.tap(find.text('Staff').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Total staff'), findsWidgets);

    // Tap Insights tab
    await tester.tap(find.text('Insights').first);
    await tester.pumpAndSettle();

    expect(find.text('Key insights & recommendations'), findsOneWidget);
    expect(find.text('Student attendance trend'), findsOneWidget);

    // Scroll to and tap Attendance tab
    await tester.ensureVisible(find.text('Attendance').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendance').first);
    await tester.pumpAndSettle();

    expect(find.text('Attendance for today'), findsOneWidget);
    expect(find.text('Students absent · 0'), findsOneWidget);

    // Scroll to and tap Front Office tab
    await tester.ensureVisible(find.text('Front Office').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Front Office').first);
    await tester.pumpAndSettle();

    expect(find.text('Admission queries'), findsOneWidget);
    expect(find.text('Appointments'), findsOneWidget);
    expect(find.text('My availability'), findsOneWidget);
  });
}
