import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const DT7FinanceApp(isAuthenticated: false));
    expect(find.text('Welcome to DT7 Finance'), findsOneWidget);
  });
}
