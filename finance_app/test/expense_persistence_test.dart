import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Expense Persistence Tests', () {
    test('Creating expense persists and is retrieved on refresh', () async {
      final initialExpenses = await ApiService.getExpenses();
      final initialCount = initialExpenses.length;

      final success = await ApiService.createExpense(
        title: 'Test Client Transport',
        amount: 850.0,
        categoryId: 1,
        description: 'Taxi fare for meeting',
      );

      expect(success, isTrue);

      final refreshedExpenses = await ApiService.getExpenses();
      expect(refreshedExpenses.length, equals(initialCount + 1));
      expect(refreshedExpenses.first.title, equals('Test Client Transport'));
      expect(refreshedExpenses.first.amount, equals(850.0));
      expect(refreshedExpenses.first.status, equals('APPROVED'));
      expect(refreshedExpenses.first.isApproved, isTrue);
      expect(refreshedExpenses.first.isPending, isFalse);
    });

    test('Updating expense updates local persistence', () async {
      final expenses = await ApiService.getExpenses();
      if (expenses.isNotEmpty) {
        final target = expenses.first;
        final updated = await ApiService.updateExpense(
          id: target.id,
          title: 'Updated Transport Claim',
          amount: 900.0,
          categoryName: target.categoryName,
        );
        expect(updated, isTrue);

        final reloaded = await ApiService.getExpenses();
        final match = reloaded.firstWhere((e) => e.id == target.id);
        expect(match.title, equals('Updated Transport Claim'));
        expect(match.amount, equals(900.0));
      }
    });

    test('Deleting expense removes it from persistence', () async {
      final expenses = await ApiService.getExpenses();
      if (expenses.isNotEmpty) {
        final target = expenses.first;
        final initialCount = expenses.length;

        final deleted = await ApiService.deleteExpense(target.id);
        expect(deleted, isTrue);

        final reloaded = await ApiService.getExpenses();
        expect(reloaded.length, equals(initialCount - 1));
        expect(reloaded.any((e) => e.id == target.id), isFalse);
      }
    });
  });
}
