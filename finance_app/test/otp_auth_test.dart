import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/services/auth_service.dart';
import 'package:finance_app/screens/02_login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OTP Authentication Unit Tests', () {
    test('sendOtp returns error when identifier is empty', () async {
      final res = await AuthService.sendOtp('');
      expect(res['success'], false);
      expect(res['message'], contains('Please enter your email or username'));
    });

    test('sendOtp returns success for valid test email/username', () async {
      final res = await AuthService.sendOtp('npaulprasanakumar@gmail.com');
      expect(res['success'], true);
      expect(res['email'], contains('@'));
    });

    test('verifyOtpAndLogin returns null when OTP is empty or invalid', () async {
      final role = await AuthService.verifyOtpAndLogin('npaulprasanakumar@gmail.com', '');
      expect(role, isNull);

      final wrongOtpRole = await AuthService.verifyOtpAndLogin('npaulprasanakumar@gmail.com', '000000');
      expect(wrongOtpRole, isNull);
    });
  });

  group('Login Screen OTP Toggle UI Tests', () {
    testWidgets('Renders LoginScreen and switches between Password and OTP modes', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Password mode is active by default
      expect(find.text('Password'), findsWidgets);
      expect(find.text('Email OTP'), findsOneWidget);
      expect(find.text('Welcome Back!'), findsOneWidget);

      // Tap on "Email OTP" pill tab
      await tester.tap(find.text('Email OTP'));
      await tester.pumpAndSettle();

      // Check that OTP verification UI is now active
      expect(find.text('OTP Verification'), findsOneWidget);
      expect(find.text('Send OTP Code'), findsOneWidget);

      // Switch back to Password mode
      await tester.tap(find.text('Password').first);
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
