import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Role-Based Login Authentication Tests', () {
    test('Founder Side Login Test (founder@dt7.agency)', () async {
      final role = await AuthService.authenticateUser('founder@dt7.agency', 'password123');
      expect(role, equals('FOUNDER'));

      final savedRole = await AuthService.getUserRole();
      expect(savedRole, equals('FOUNDER'));
    });

    test('Founder Side Login Test (admin@gmail.com)', () async {
      final role = await AuthService.authenticateUser('admin@gmail.com', '123456');
      expect(role, equals('FOUNDER'));

      final savedRole = await AuthService.getUserRole();
      expect(savedRole, equals('FOUNDER'));
    });

    test('Employee Side Login Test (dinesh@gmail.com)', () async {
      final role = await AuthService.authenticateUser('dinesh@gmail.com', 'password123');
      expect(role, equals('EMPLOYEE'));

      final savedRole = await AuthService.getUserRole();
      expect(savedRole, equals('EMPLOYEE'));
    });

    test('Employee Side Login Test (paul@gmail.com)', () async {
      final role = await AuthService.authenticateUser('paul@gmail.com', 'password123');
      expect(role, equals('EMPLOYEE'));

      final savedRole = await AuthService.getUserRole();
      expect(savedRole, equals('EMPLOYEE'));
    });

    test('Wrong Password Rejection Test (founder@dt7.agency + wrongpassword)', () async {
      final role = await AuthService.authenticateUser('founder@dt7.agency', 'wrongpassword');
      expect(role, isNull);
    });

    test('Wrong Password Rejection Test (admin@gmail.com + 999999)', () async {
      final role = await AuthService.authenticateUser('admin@gmail.com', '999999');
      expect(role, isNull);
    });

    test('Non-Existent Account Rejection Test (unknown@domain.com + pass)', () async {
      final role = await AuthService.authenticateUser('unknown@domain.com', 'pass');
      expect(role, isNull);
    });

    test('Invalid Login Test (Empty Credentials)', () async {
      final role = await AuthService.authenticateUser('', '');
      expect(role, isNull);
    });
  });
}
