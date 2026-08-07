import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.saveCurrentUsername('paul_pk');
    await AuthService.saveUserRole('EMPLOYEE');
  });

  group('Admin Budget Request Queue Tests', () {
    test('User submits budget request and Admin retrieves it in pending queue', () async {
      await ApiService.submitBudgetRequest(
        requestAmount: 10000.0,
        categoryId: 3,
        reason: 'Domain renewal and SSL certificate purchase',
      );

      final requests = await ApiService.getBudgetRequests();
      expect(requests, isNotEmpty);

      final pendingReq = requests.firstWhere((r) => r.status == 'PENDING');
      expect(pendingReq.requestAmount, equals(10000.0));
      expect(pendingReq.categoryName, contains('Domain'));
      expect(pendingReq.userName, equals('Paul PK'));
    });

    test('Admin approves budget request and user allocated budget increases', () async {
      final userBefore = await ApiService.getCurrentUser();
      final allocBefore = userBefore?.allocatedAmount ?? 0.0;

      await ApiService.submitBudgetRequest(
        requestAmount: 5000.0,
        categoryId: 1,
        reason: 'Extra hosting bandwidth',
      );

      final reqs = await ApiService.getBudgetRequests();
      final pendingReq = reqs.firstWhere((r) => r.status == 'PENDING');

      final success = await ApiService.updateBudgetRequestStatus(pendingReq.id, 'APPROVED');
      expect(success, isTrue);

      final userAfter = await ApiService.getCurrentUser();
      expect(userAfter?.allocatedAmount, equals(allocBefore + 5000.0));
    });
  });
}
