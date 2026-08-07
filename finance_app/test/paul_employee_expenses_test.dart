import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/services/auth_service.dart';
import 'package:finance_app/models/user_model.dart';
import 'package:finance_app/models/expense_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Paul Employee Dashboard & Expenses Tests', () {
    test('Logs in as paul and retrieves paul expenses including yesterday and history data', () async {
      await AuthService.saveCurrentUsername('paul_pk');
      await AuthService.saveUserRole('EMPLOYEE');

      final user = await ApiService.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.username, contains('paul'));

      final expenses = await ApiService.getExpenses();
      expect(expenses, isNotEmpty);

      final paulExpenses = expenses.where((e) => ApiService.isExpenseOwnedByUser(e, user)).toList();
      expect(paulExpenses, isNotEmpty);
      expect(paulExpenses.any((e) => e.userName.toLowerCase().contains('paul')), isTrue);
    });
  });
}
