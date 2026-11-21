import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vriyda_ai/services/session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Alert and Approval Persistence Tests', () {
    test('Persists and retrieves acknowledged alert IDs across sessions', () async {
      const userId = 'USR-12345';
      const alertId1 = 'alt-gachibowli-FINANCE-overdue';
      const alertId2 = 'alt-steel-plant-TRANSPORT-delay';

      // Initially empty
      final initial = await SessionManager.getAcknowledgedAlertIds(userId: userId);
      expect(initial, isEmpty);

      // Save alert 1
      await SessionManager.saveAcknowledgedAlertId(alertId1, userId: userId);
      var current = await SessionManager.getAcknowledgedAlertIds(userId: userId);
      expect(current.contains(alertId1), isTrue);
      expect(current.contains(alertId2), isFalse);

      // Save alert 2
      await SessionManager.saveAcknowledgedAlertId(alertId2, userId: userId);
      current = await SessionManager.getAcknowledgedAlertIds(userId: userId);
      expect(current.contains(alertId1), isTrue);
      expect(current.contains(alertId2), isTrue);

      // Simulate re-login with same user: data persists
      final afterRelogin = await SessionManager.getAcknowledgedAlertIds(userId: userId);
      expect(afterRelogin.length, 2);
      expect(afterRelogin.contains(alertId1), isTrue);
      expect(afterRelogin.contains(alertId2), isTrue);
    });

    test('Persists and retrieves approved item IDs across sessions', () async {
      const userId = 'USR-12345';
      const aprId1 = 'apr-item-101';
      const aprId2 = 'apr-item-102';

      // Initially empty
      final initial = await SessionManager.getApprovedItemIds(userId: userId);
      expect(initial, isEmpty);

      // Save approval 1
      await SessionManager.saveApprovedItemId(aprId1, userId: userId);
      var current = await SessionManager.getApprovedItemIds(userId: userId);
      expect(current.contains(aprId1), isTrue);
      expect(current.contains(aprId2), isFalse);

      // Toggle / remove approval 1
      await SessionManager.removeApprovedItemId(aprId1, userId: userId);
      current = await SessionManager.getApprovedItemIds(userId: userId);
      expect(current.contains(aprId1), isFalse);

      // Add approval 2
      await SessionManager.saveApprovedItemId(aprId2, userId: userId);
      final afterRelogin = await SessionManager.getApprovedItemIds(userId: userId);
      expect(afterRelogin.contains(aprId2), isTrue);
    });
  });
}
