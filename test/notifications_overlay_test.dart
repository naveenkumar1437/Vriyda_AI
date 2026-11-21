import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/widgets/notifications_overlay.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'mock-test-token'});
  });

  group('NotificationsOverlay Tests', () {
    testWidgets('NotificationsDropdownSheet renders alerts and approvals', (
      tester,
    ) async {
      Map<String, dynamic>? selectedAlert;
      Map<String, dynamic>? selectedApproval;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsDropdownSheet(
              alerts: const [
                {
                  'id': 'alt-test-1',
                  'type': 'Finance',
                  'branch': 'Gachibowli Campus',
                  'time': '2h ago',
                  'level': 'critical',
                },
              ],
              approvals: const [
                {
                  'id': 'apr-test-1',
                  'type': 'Fee Waiver',
                  'title': 'Hardship fee waiver — 3 students',
                  'branch': 'Gachibowli Campus',
                  'age': '166d',
                  'amount': 45000,
                },
              ],
              branches: const [],
              onAlertTap: (al) => selectedAlert = al,
              onApprovalTap: (ap) => selectedApproval = ap,
            ),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.textContaining('need your attention'), findsOneWidget);

      // Verify Section Titles
      expect(find.text('CRITICAL ALERTS'), findsOneWidget);
      expect(find.text('APPROVALS WAITING'), findsOneWidget);

      // Verify First Critical Alert
      expect(find.textContaining('Gachibowli Campus'), findsWidgets);

      // Tap an alert
      await tester.tap(find.textContaining('Gachibowli Campus').first);
      await tester.pump();
      expect(selectedAlert, isNotNull);

      // Tap an approval
      final feeWaiverFinder = find.textContaining('Fee Waiver').first;
      await tester.tap(feeWaiverFinder);
      await tester.pump();
      expect(selectedApproval, isNotNull);
    });

    testWidgets('NotificationsDropdownSheet renders empty states when lists are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NotificationsDropdownSheet(
              alerts: const [],
              approvals: const [],
              branches: const [],
              onAlertTap: (_) {},
              onApprovalTap: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('No critical alerts'), findsOneWidget);
      expect(find.text('No pending approvals'), findsOneWidget);
    });

    testWidgets('BranchNotificationDetailsDialog renders metrics table', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BranchNotificationDetailsDialog(
              branchName: 'Gachibowli Campus',
              status: 'STABLE',
            ),
          ),
        ),
      );

      // Verify Branch header and STABLE tag
      expect(find.text('Gachibowli Campus'), findsOneWidget);
      expect(find.text('STABLE'), findsOneWidget);

      // Verify table rows from Screenshot 2
      expect(find.text('Students'), findsOneWidget);
      expect(find.text('Capacity / fill'), findsOneWidget);
      expect(find.text('Revenue (billed)'), findsOneWidget);
      expect(find.text('Collected'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
      expect(find.text('Collection'), findsOneWidget);

      // Scroll to bottom rows
      await tester.scrollUntilVisible(
        find.text('Fleet vehicles'),
        50.0,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Open vacancies'), findsOneWidget);
      expect(find.text('· Teacher'), findsOneWidget);
      expect(find.text('Fleet vehicles'), findsOneWidget);
    });

    testWidgets('ApprovalDecisionDialog renders fields and handles decisions', (
      tester,
    ) async {
      String? recordedDecision;
      String? recordedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ApprovalDecisionDialog(
              approvalItem: const {
                'id': 'apr-test-1',
                'type': 'Fee Waiver',
                'title': 'Hardship fee waiver — 3 students',
                'branch': 'Gachibowli Campus',
                'age': '166d',
                'amount': '₹45,000',
              },
              onDecision: (decision, note) {
                recordedDecision = decision;
                recordedNote = note;
              },
            ),
          ),
        ),
      );

      // Verify Header & Subtitle
      expect(find.text('Fee Waiver'), findsOneWidget);
      expect(find.text('Hardship fee waiver — 3 students'), findsOneWidget);
      expect(
        find.text('Gachibowli Campus · 166d waiting · ₹45,000'),
        findsOneWidget,
      );

      // Verify Note TextField
      expect(find.text('Optional note for the record...'), findsOneWidget);

      // Verify Buttons
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);

      // Enter a note
      await tester.enterText(find.byType(TextField), 'Verified hardship');
      await tester.pump();

      // Tap Reject button
      await tester.tap(find.text('Reject'));
      await tester.pumpAndSettle();

      expect(recordedDecision, 'rejected');
      expect(recordedNote, 'Verified hardship');
    });
  });
}
