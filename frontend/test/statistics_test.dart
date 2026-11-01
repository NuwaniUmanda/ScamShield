import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/providers/stats_provider.dart';
import 'package:frontend/screens/statistics/statistics_screen.dart';
import 'package:frontend/widgets/charts/reports_by_category_chart.dart';
import 'package:frontend/widgets/charts/reports_over_time_chart.dart';

void main() {
  Widget createTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScamProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: StatisticsScreen(),
        ),
      ),
    );
  }

  testWidgets('Statistics screen displays 5 stat cards, percentage changes, charts, and table',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestableWidget());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // 1. Heading & Breadcrumb
    expect(find.text('Analytics & Threat Intelligence'), findsOneWidget);
    expect(find.text('Statistics'), findsWidgets);

    // 2. 5 Statistic Cards
    expect(find.text('Total Reports'), findsOneWidget);
    expect(find.text('+12.5%'), findsOneWidget);

    expect(find.text('Phishing Links'), findsOneWidget);
    expect(find.text('+18.7%'), findsOneWidget);

    expect(find.text('Fake Accounts'), findsWidgets);
    expect(find.text('+8.2%'), findsOneWidget);

    expect(find.text('Scam Messages'), findsWidgets);
    expect(find.text('-4.3%'), findsOneWidget);

    expect(find.text('Verified Reports'), findsOneWidget);
    expect(find.text('+15.6%'), findsOneWidget);

    // 3. Reports by Category Chart
    expect(find.text('Reports by Category'), findsOneWidget);
    expect(find.byType(ReportsByCategoryChart), findsOneWidget);
    expect(find.text('Phishing'), findsWidgets);

    // 4. Reports Over Time Chart
    expect(find.text('Reports Over Time'), findsOneWidget);
    expect(find.byType(ReportsOverTimeChart), findsOneWidget);
    expect(find.text('Reported Incidents'), findsOneWidget);
    expect(find.text('Neutralized Threats'), findsOneWidget);

    // 5. Recent Reports Table
    expect(find.text('Recent Reports & Threat Intelligence'), findsOneWidget);
    expect(find.text('TARGET / TITLE'), findsOneWidget);
    expect(find.text('facebook-security-login.com'), findsOneWidget);
  });
}
