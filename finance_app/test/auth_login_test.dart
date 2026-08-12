import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Authentication Verification Tests', () {
    test('Unregistered credentials (unregistered_user/123456) are rejected by default', () async {
      final role = await AuthService.authenticateUser('unregistered_user', '123456');
      expect(role, isNull);
    });

    test('Invalid credentials (wrong_user/wrong_pass) return null', () async {
      final role = await AuthService.authenticateUser('invalid_user', 'invalid_password');
      expect(role, isNull);
    });

    test('Session persists across app reloads after login', () async {
      // 1. Initial state: not authenticated
      expect(await AuthService.isAuthenticated(), isFalse);

      // 2. User logs in
      final role = await AuthService.authenticateUser('founder', '123456');
      expect(role, equals('FOUNDER'));

      // 3. User is now authenticated
      expect(await AuthService.isAuthenticated(), isTrue);
      expect(await AuthService.getCurrentUsername(), isNotEmpty);
      expect(await AuthService.getUserRole(), equals('FOUNDER'));

      // 4. Simulate closing app and opening again (reading saved prefs)
      final reloadedAuth = await AuthService.isAuthenticated();
      final reloadedUser = await AuthService.getCurrentUsername();
      final reloadedRole = await AuthService.getUserRole();
      expect(reloadedAuth, isTrue);
      expect(reloadedUser, isNotEmpty);
      expect(reloadedRole, equals('FOUNDER'));

      // 5. Explicit logout clears session
      await AuthService.logout();
      expect(await AuthService.isAuthenticated(), isFalse);
      expect(await AuthService.getCurrentUsername(), isEmpty);
    });
  });
}
