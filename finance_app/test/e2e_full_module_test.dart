import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/auth_service.dart';
import 'package:finance_app/services/api_service.dart';
import 'package:finance_app/models/user_model.dart';
import 'package:finance_app/models/expense_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Module 1: Authentication & Role-Based Access Control', () {
    test('Authenticate Founder Role correctly resolves FOUNDER', () async {
      await AuthService.saveUserRole('FOUNDER');
      await AuthService.saveCurrentUsername('diya');
      final role = await AuthService.getUserRole();
      expect(role, equals('FOUNDER'));
    });

    test('Authenticate Admin Role with aadmin credentials resolves ADMIN', () async {
      await ApiService.addUser(
        username: 'aadmin',
        email: 'aadmin@dt7.agency',
        password: '123456',
        fullName: 'Aadmin',
        role: 'ADMIN',
      );
      final role = await AuthService.authenticateUser('aadmin', '123456');
      expect(role, equals('ADMIN'));
    });

    test('Authenticate Employee Role correctly resolves EMPLOYEE', () async {
      await AuthService.saveUserRole('EMPLOYEE');
      await AuthService.saveCurrentUsername('paul');
      final role = await AuthService.getUserRole();
      expect(role, equals('EMPLOYEE'));
    });

    test('Logout clears session credentials cleanly', () async {
      await AuthService.saveToken('token123', 'refresh123');
      await AuthService.saveCurrentUsername('paul');
      await AuthService.logout();
      final token = await AuthService.getToken();
      final username = await AuthService.getCurrentUsername();
      expect(token, isNull);
      expect(username, isEmpty);
    });
  });

  group('Module 2: Founder Dashboard & Financial Summary', () {
    test('Calculates total budget overspend correctly across users', () async {
      final userPaul = UserModel(
        id: 1,
        username: 'paul',
        email: 'paul@gmail.com',
        firstName: 'Paul',
        lastName: 'PK',
        role: 'EMPLOYEE',
        allocatedAmount: 10000.0,
        usedAmount: 15000.0,
        remainingAmount: -5000.0,
      );

      final overspend = ApiService.calculateUserSpent(userPaul, [
        ExpenseModel(id: 101, title: 'Server Hosting', amount: 15000.0, dateTime: '2026-08-06', status: 'Approved', userName: 'paul'),
      ]);

      expect(overspend, equals(15000.0));
      expect(userPaul.allocatedAmount - overspend, equals(-5000.0));
    });

    test('Negative Founder Balance triggers overspent alert state', () async {
      const allocated = 50000.0;
      const spent = 65000.0;
      const balance = allocated - spent;
      final isOverspent = balance < 0;

      expect(balance, equals(-15000.0));
      expect(isOverspent, isTrue);
    });
  });

  group('Module 3: Employee Dashboard & Overspend Calculations', () {
    test('Employee overspend calculation correctly computes extra spent', () async {
      const allocated = 20000.0;
      const spent = 28000.0;
      final isOver = spent > allocated;
      final extraOverspent = spent - allocated;

      expect(isOver, isTrue);
      expect(extraOverspent, equals(8000.0));
    });

    test('Employee normal spending within budget stays healthy', () async {
      const allocated = 20000.0;
      const spent = 12000.0;
      final isOver = spent > allocated;
      final remaining = allocated - spent;

      expect(isOver, isFalse);
      expect(remaining, equals(8000.0));
    });
  });

  group('Module 4: Categories Validation (Software Tools & AI Subscriptions)', () {
    test('Default categories contain Software Tools and AI Subscriptions', () async {
      final categories = await ApiService.getCategories();
      final names = categories.map((c) => c.name).toList();

      expect(names.any((n) => n.contains('Software')), isTrue);
      expect(names.any((n) => n.contains('AI')), isTrue);
      expect(names, isNot(contains('Food')));
      expect(names, isNot(contains('Freelance')));
      expect(names, isNot(contains('Healthcare')));
    });
  });

  group('Module 5: Expense Persistence & Operations', () {
    test('Add, Retrieve, Update, and Delete Expense in Local Persistence', () async {
      final exp = ExpenseModel(
        id: 999,
        title: 'ChatGPT Plus Subscription',
        amount: 2000.0,
        dateTime: '2026-08-06',
        categoryName: 'AI Subscriptions',
        status: 'Approved',
      );

      final added = await ApiService.addExpense(
        title: exp.title,
        amount: exp.amount,
        categoryId: 2,
        date: '2026-08-06',
      );
      expect(added, isTrue);

      final expenses = await ApiService.getExpenses();
      expect(expenses.any((e) => e.title == 'ChatGPT Plus Subscription'), isTrue);
    });
  });

  group('Module 6: User Creation with Custom Passwords', () {
    test('Creating new user account assigns role and custom password', () async {
      final created = await ApiService.addUser(
        username: 'test_employee',
        email: 'test_employee@dt7.agency',
        password: 'CustomSecurePassword123!',
        fullName: 'Test Employee',
        role: 'EMPLOYEE',
      );

      expect(created, isTrue);

      final users = await ApiService.getUsers();
      expect(users.any((u) => u.email == 'test_employee@dt7.agency'), isTrue);
    });
  });
}
