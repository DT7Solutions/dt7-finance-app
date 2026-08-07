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

  group('Budget Request & Allocation Tests', () {
    test('Submits budget request and verifies it is retrieved with PENDING status', () async {
      final initialRequests = await ApiService.getBudgetRequests();
      final countBefore = initialRequests.length;

      final success = await ApiService.submitBudgetRequest(
        requestAmount: 5000.0,
        categoryId: 1,
        reason: 'Need extra budget for server hosting',
      );
      expect(success, isTrue);

      final updatedRequests = await ApiService.getBudgetRequests();
      expect(updatedRequests.length, equals(countBefore + 1));

      final newReq = updatedRequests.first;
      expect(newReq.requestAmount, equals(5000.0));
      expect(newReq.status, equals('PENDING'));
      expect(newReq.reason, contains('server hosting'));
    });

    test('Approving a budget request updates request status to APPROVED and increases user allocated budget', () async {
      await ApiService.submitBudgetRequest(
        requestAmount: 7500.0,
        categoryId: 2,
        reason: 'Additional AI tools subscription',
      );

      final requests = await ApiService.getBudgetRequests();
      final reqToApprove = requests.firstWhere((r) => r.status == 'PENDING');

      final userBefore = await ApiService.getCurrentUser();
      final allocatedBefore = userBefore?.allocatedAmount ?? 0.0;

      final approved = await ApiService.updateBudgetRequestStatus(reqToApprove.id, 'APPROVED');
      expect(approved, isTrue);

      final requestsAfter = await ApiService.getBudgetRequests();
      final reqAfter = requestsAfter.firstWhere((r) => r.id == reqToApprove.id);
      expect(reqAfter.status, equals('APPROVED'));

      final userAfter = await ApiService.getCurrentUser();
      expect(userAfter?.allocatedAmount, equals(allocatedBefore + 7500.0));
    });
  });
}
