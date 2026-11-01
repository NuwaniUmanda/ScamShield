import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/scam_report.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/screens/search_scam/search_scam_screen.dart';

void main() {
  Widget createTestableWidget({Function(ScamReport)? onReportSelected}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScamProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SearchScamScreen(onReportSelected: onReportSelected),
        ),
      ),
    );
  }

  testWidgets('Search Scam screen renders heading, search field, filters, and mock data',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 1. Heading
    expect(find.text('Search Scam'), findsWidgets);

    // 2. Search Field
    expect(find.text('Enter a URL, account name or keyword...'), findsOneWidget);

    // 3. Search Button
    expect(find.text('Search'), findsOneWidget);

    // 4. Filters
    expect(find.text('All Categories'), findsOneWidget);
    expect(find.text('All Risk Levels'), findsOneWidget);

    // 5. Check mock record: facebook-security-login.com
    expect(find.text('facebook-security-login.com'), findsOneWidget);
    expect(find.text('Phishing Link'), findsOneWidget);
    expect(find.text('27 Reports'), findsOneWidget);
    expect(find.text('Blockchain Verified'), findsWidgets);
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('View Details'), findsWidgets);
  });

  testWidgets('Search input filters mock records dynamically',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Type query in search field
    await tester.enterText(
      find.byType(TextField),
      'facebook',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Should find facebook record
    expect(find.text('facebook-security-login.com'), findsOneWidget);
    // Non-matching records should not be displayed
    expect(find.text('Urgent Account Suspension Phishing SMS'), findsNothing);

    // Type query that matches nothing to verify empty state
    await tester.enterText(
      find.byType(TextField),
      'nonexistent_query_xyz_123',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No scams found matching your query'), findsOneWidget);
  });

  testWidgets('View Details button triggers navigation callback',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    ScamReport? selectedReport;
    await tester.pumpWidget(createTestableWidget(
      onReportSelected: (r) => selectedReport = r,
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final viewDetailsButtons = find.text('View Details');
    expect(viewDetailsButtons, findsWidgets);

    await tester.tap(viewDetailsButtons.first);
    await tester.pumpAndSettle();

    expect(selectedReport, isNotNull);
    expect(selectedReport!.id, equals('REP-84921'));
  });
}
