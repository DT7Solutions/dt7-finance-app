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
  });
}
