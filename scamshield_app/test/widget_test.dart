import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_app/main.dart';

void main() {
  testWidgets('ScamShield app loads navigation shell test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScamShieldApp());
    expect(find.byType(ScamShieldApp), findsOneWidget);
  });
}
