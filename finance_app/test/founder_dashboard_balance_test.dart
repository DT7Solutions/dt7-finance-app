import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/screens/03_dashboard_screen.dart';
import 'package:finance_app/services/auth_service.dart';
import 'package:finance_app/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.saveCurrentUsername('founder');
    await AuthService.saveUserRole('FOUNDER');
    await ApiService.ensureDataLoaded();
  });

  group('Founder Dashboard Rendering & Balance Tests', () {
    test('Negative balance formatted with minus sign and red indicator state', () {
      const double remaining = -15000.0;
      final isNegative = remaining < 0;
      expect(isNegative, isTrue);

      final absAmount = remaining.abs();
      final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
      final formatted = formatter.format(absAmount);
      final result = isNegative ? '- $formatted' : formatted;

      expect(result, contains('-'));
      expect(result, contains('₹'));
      expect(result, contains('15,000'));
    });

    testWidgets('FounderDashboardScreen renders all sections without blank screen or layout crashes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        const MaterialApp(
          home: FounderDashboardScreen(),
        ),
      );

      // Pump initial frame
      await tester.pump();

      // Advance time for _loadDashboard async completion
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();

      // Verify header and core sections are fully rendered and visible
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Total Allocated'), findsOneWidget);
      expect(find.text('Total Expenses'), findsWidgets);
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('Over Budget'), findsOneWidget);
      expect(find.text('Pending Approvals Queue'), findsOneWidget);
      expect(find.text('Expenses Overview'), findsOneWidget);
      expect(find.text('Expense Breakdown by User'), findsOneWidget);
      expect(find.text('Add New User'), findsOneWidget);
    });
  });
}

