import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/scam_report.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/screens/my_reports/my_reports_screen.dart';

void main() {
  testWidgets('My Reports screen displays all required columns and mock records', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    ScamReport? selectedReport;

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ScamProvider()),
          ],
          child: Scaffold(
            body: MyReportsScreen(
              onReportSelected: (report) {
                selectedReport = report;
              },
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Heading and Breadcrumb
    expect(find.text('My Reports'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Submit New Report'), findsOneWidget);

    // 2. Table Column Headers
    expect(find.text('REPORT'), findsOneWidget);
    expect(find.text('CATEGORY'), findsOneWidget);
    expect(find.text('RISK'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('ACTION'), findsOneWidget);

    // 3. User Requested Mock Records
    expect(find.text('Fake profile impersonating celebrity'), findsOneWidget);
    expect(find.text('Urgent bank security alert'), findsOneWidget);
    expect(find.text('Facebook marketplace seller'), findsOneWidget);
    expect(find.text('Crypto mining investment offer'), findsOneWidget);

    // Categories
    expect(find.text('Fake Account'), findsWidgets);
    expect(find.text('Phishing'), findsWidgets);
    expect(find.text('Spam Messages'), findsWidgets);

    // 4. "View Details" buttons
    final viewDetailsButtons = find.text('View Details');
    expect(viewDetailsButtons, findsWidgets);

    // Tap first View Details button
    await tester.tap(viewDetailsButtons.first);
    await tester.pumpAndSettle();

    expect(selectedReport, isNotNull);
    expect(selectedReport!.title, 'Fake profile impersonating celebrity');
  });
}
