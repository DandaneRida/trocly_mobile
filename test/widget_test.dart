import 'package:flutter_test/flutter_test.dart';
import 'package:trocly_mobile/main.dart';

void main() {
  testWidgets('TroclyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TroclyApp());
    expect(find.text('Trocly'), findsOneWidget);
  });
}
