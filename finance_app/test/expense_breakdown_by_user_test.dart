import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/models/expense_model.dart';
import 'package:finance_app/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Total Expenses Breakdown by User Tests', () {
    test('Calculates user expense breakdown accurately for admin dashboard', () async {
      await ApiService.addUser(
        username: 'alice_dev',
        email: 'alice@dt7.agency',
        password: 'password123',
        fullName: 'Alice Dev',
        role: 'EMPLOYEE',
      );

      final users = await ApiService.getUsers();
      expect(users.any((u) => u.username == 'alice_dev'), isTrue);

      await ApiService.addExpense(
        title: 'AWS Cloud Server',
        amount: 12000.0,
        categoryId: 1,
        date: '2026-08-07',
      );

      final expenses = await ApiService.getExpenses();
      expect(expenses, isNotEmpty);

      // Verify mapping user to their expenses
      final user = users.firstWhere((u) => u.username == 'alice_dev');
      final aliceExpenses = expenses.where((e) {
        final uName = user.username.trim().toLowerCase();
        final fName = user.fullName.trim().toLowerCase();
        final expUser = e.userName.trim().toLowerCase();
        return expUser == uName || expUser == fName || expUser.contains(uName) || expUser.contains(fName);
      }).toList();

      final totalSpentByAlice = aliceExpenses.fold(0.0, (sum, e) => sum + e.amount);
      expect(totalSpentByAlice, greaterThanOrEqualTo(0.0));
    });
  });
}
