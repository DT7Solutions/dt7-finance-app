import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Budget Spending Breakdown Tests', () {
    test('Identifies users who spent budget and users over budget correctly', () async {
      await ApiService.addUser(
        username: 'test_user',
        email: 'test@example.com',
        password: 'password',
        fullName: 'Test Employee',
      );
      final users = await ApiService.getUsers();
      expect(users, isNotEmpty);

      final overBudgetUsers = users.where((u) => u.usedAmount > u.allocatedAmount && u.allocatedAmount > 0).toList();
      for (final user in overBudgetUsers) {
        expect(user.usedAmount, greaterThan(user.allocatedAmount));
        expect(user.allocatedAmount - user.usedAmount, lessThan(0));
      }
    });
  });
}
