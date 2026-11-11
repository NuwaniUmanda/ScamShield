import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('ScamShieldApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const ScamShieldApp());
    expect(find.text('ScamShield'), findsWidgets);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('ScamShield'), findsWidgets);
  });
}
