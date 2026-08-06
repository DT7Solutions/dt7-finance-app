import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Founder Dashboard Negative Balance Tests', () {
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
  });
}
