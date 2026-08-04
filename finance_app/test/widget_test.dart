import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/main.dart';

void main() {
  testWidgets('DT7 Agency App initializes splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DT7AgencyFinanceApp());
    expect(find.text('Finance Management\nApp'), findsOneWidget);
  });
}
