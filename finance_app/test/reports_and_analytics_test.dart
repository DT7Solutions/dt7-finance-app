import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Reports & Analytics Tests', () {
    test('Loads category expenses breakdown and top spending employees dynamically from database data', () async {
      await AuthService.saveCurrentUsername('founder');
      await AuthService.saveUserRole('FOUNDER');

      final users = await ApiService.getUsers();
      expect(users, isNotEmpty);

      final expenses = await ApiService.getExpenses();
      expect(expenses, isNotEmpty);

      // Verify category breakdown calculates from real database expenses
      final totalSpent = expenses.fold(0.0, (s, e) => s + e.amount);
      expect(totalSpent, greaterThan(0));

      Map<String, double> catSum = {};
      for (var e in expenses) {
        catSum[e.categoryName] = (catSum[e.categoryName] ?? 0) + e.amount;
      }
      expect(catSum.keys, isNotEmpty);
      expect(catSum.values.fold(0.0, (a, b) => a + b), equals(totalSpent));

      // Verify user spenders leaderboard uses database users
      Map<int, double> userSpentMap = {};
      for (var u in users) {
        final uExpenses = expenses.where((e) => ApiService.isExpenseOwnedByUser(e, u)).toList();
        final sum = uExpenses.fold(0.0, (s, e) => s + e.amount);
        userSpentMap[u.id] = sum > 0 ? sum : u.usedAmount;
      }
      final topSpenders = users.where((u) => (userSpentMap[u.id] ?? 0) > 0).toList();
      topSpenders.sort((a, b) => (userSpentMap[b.id] ?? 0).compareTo(userSpentMap[a.id] ?? 0));

      expect(topSpenders, isNotEmpty);
      expect(userSpentMap[topSpenders.first.id], greaterThan(0));
    });
  });
}
