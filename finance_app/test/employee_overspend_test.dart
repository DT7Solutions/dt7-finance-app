import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Employee Dashboard Overspend Tests', () {
    test('Correctly identifies overspending and calculates extra overspent amount', () {
      final allocated = 10000.0;
      final used = 13500.0;
      final remaining = allocated - used;
      final isOverspent = remaining < 0;
      final extraOverspent = (used - allocated).clamp(0.0, double.infinity);

      expect(isOverspent, isTrue);
      expect(remaining, equals(-3500.0));
      expect(extraOverspent, equals(3500.0));
    });

    test('Normal budget within limit is not marked as overspent', () {
      final allocated = 10000.0;
      final used = 6000.0;
      final remaining = allocated - used;
      final isOverspent = remaining < 0;

      expect(isOverspent, isFalse);
      expect(remaining, equals(4000.0));
    });
  });
}
