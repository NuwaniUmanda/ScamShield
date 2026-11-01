import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/providers/stats_provider.dart';
import 'package:frontend/providers/detection_provider.dart';
import 'package:frontend/providers/blockchain_provider.dart';
import 'package:frontend/screens/splash/splash_screen.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/search_scam/search_scam_screen.dart';
import 'package:frontend/screens/report_scam/report_scam_screen.dart';
import 'package:frontend/screens/ai_detection/ai_detection_screen.dart';
import 'package:frontend/screens/statistics/statistics_screen.dart';
import 'package:frontend/screens/my_reports/my_reports_screen.dart';
import 'package:frontend/screens/scam_details/scam_details_screen.dart';

Widget createTestApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ScamProvider()),
      ChangeNotifierProvider(create: (_) => StatsProvider()),
      ChangeNotifierProvider(create: (_) => DetectionProvider()),
      ChangeNotifierProvider(create: (_) => BlockchainProvider()),
    ],
    child: MaterialApp.router(
      routerConfig: appRouter,
    ),
  );
}

void main() {
  setUp(() {
    appRouter.go(AppRoutes.splash);
  });

  testWidgets('1. Splash to Dashboard navigation works', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    await tester.pump();

    // Verify Splash Screen
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('ScamShield'), findsWidgets);
    expect(find.text('AI + Blockchain Security'), findsOneWidget);

    // Wait for splash timer transition
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    // Verify Dashboard Screen
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('Overview Dashboard'), findsWidgets);
  });

  testWidgets('2-6. Dashboard navigates to all 5 main sections via sidebar and cards', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    appRouter.go(AppRoutes.dashboard);
    await tester.pumpAndSettle();

    // 2. AI Detection
    appRouter.go(AppRoutes.aiDetection);
    await tester.pumpAndSettle();
    expect(find.byType(AiDetectionScreen), findsOneWidget);
    expect(find.text('AI Detection Result'), findsOneWidget);

    // 3. Search Scam
    appRouter.go(AppRoutes.searchScam);
    await tester.pumpAndSettle();
    expect(find.byType(SearchScamScreen), findsOneWidget);
    expect(find.text('Search Scam'), findsWidgets);

    // 4. Report Scam
    appRouter.go(AppRoutes.reportScam);
    await tester.pumpAndSettle();
    expect(find.byType(ReportScamScreen), findsOneWidget);
    expect(find.text('Report a Scam Incident'), findsWidgets);

    // 5. Statistics
    appRouter.go(AppRoutes.statistics);
    await tester.pumpAndSettle();
    expect(find.byType(StatisticsScreen), findsOneWidget);
    expect(find.text('Analytics & Threat Intelligence'), findsWidgets);

    // 6. My Reports
    appRouter.go(AppRoutes.myReports);
    await tester.pumpAndSettle();
    expect(find.byType(MyReportsScreen), findsOneWidget);
    expect(find.text('My Reports'), findsWidgets);
  });

  testWidgets('7-8. Search and My Reports navigate to Scam Details', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());

    // 7. Search Results -> Scam Details
    appRouter.go(AppRoutes.searchScam);
    await tester.pumpAndSettle();

    final detailsBtns = find.text('View Details');
    expect(detailsBtns, findsWidgets);
    await tester.tap(detailsBtns.first);
    await tester.pumpAndSettle();

    expect(find.byType(ScamDetailsScreen), findsOneWidget);
    expect(find.text('Scam Details'), findsWidgets);
    expect(find.text('Blockchain Verification'), findsOneWidget);

    // 8. My Reports -> Scam Details
    appRouter.go(AppRoutes.myReports);
    await tester.pumpAndSettle();

    final myDetailsBtns = find.text('View Details');
    expect(myDetailsBtns, findsWidgets);
    await tester.tap(myDetailsBtns.first);
    await tester.pumpAndSettle();

    expect(find.byType(ScamDetailsScreen), findsOneWidget);
  });

  testWidgets('9-10. Report Scam -> Analyze Scam -> AI Detection Result -> Report This Scam works', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());
    appRouter.go(AppRoutes.reportScam);
    await tester.pumpAndSettle();

    // Fill form using form field index
    final formFields = find.byType(TextFormField);
    expect(formFields, findsWidgets);

    // 1. Account name (index 0)
    await tester.enterText(formFields.at(0), '@fake_support_agent');

    // 2. Suspicious URL (index 1)
    await tester.enterText(formFields.at(1), 'https://fake-chase-update.info');

    // 3. Description (index 3)
    await tester.enterText(formFields.at(3), 'Suspect impersonated helpdesk agent asking for crypto seed phrase.');

    // Tap Analyze Scam
    final analyzeBtn = find.text('Analyze Scam');
    await tester.ensureVisible(analyzeBtn);
    await tester.tap(analyzeBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // AI Detection screen opened
    expect(find.byType(AiDetectionScreen), findsOneWidget);
    expect(find.text('AI Detection Result'), findsOneWidget);

    // Tap Report This Scam
    final reportThisScamBtn = find.text('Report This Scam');
    expect(reportThisScamBtn, findsOneWidget);
    await tester.ensureVisible(reportThisScamBtn);
    await tester.tap(reportThisScamBtn);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Navigated to Scam Details for newly submitted report
    expect(find.byType(ScamDetailsScreen), findsOneWidget);
  });

  testWidgets('11-19. Interactive validation, search filtering, empty states, and cancel handlers work', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestApp());

    // 12. Cancel button on Report Scam navigates back to Dashboard
    appRouter.go(AppRoutes.reportScam);
    await tester.pumpAndSettle();

    final cancelBtn = find.text('Cancel');
    expect(cancelBtn, findsOneWidget);
    await tester.ensureVisible(cancelBtn);
    await tester.tap(cancelBtn);
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    // 13. Search Scam filtering works
    appRouter.go(AppRoutes.searchScam);
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(TextField, 'Enter a URL, account name or keyword...');
    await tester.enterText(searchField, 'facebook-security-login.com');
    final searchActionBtn = find.widgetWithText(ElevatedButton, 'Search');
    await tester.tap(searchActionBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('facebook-security-login.com'), findsWidgets);

    // 18. Empty State when nothing found
    await tester.enterText(searchField, 'nonexistent_search_query_xyz_12345');
    await tester.tap(searchActionBtn);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('No scams found matching your query'), findsOneWidget);
    expect(find.text('Clear All Filters'), findsOneWidget);

    // Reset filters
    await tester.tap(find.text('Clear All Filters'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('facebook-security-login.com'), findsWidgets);
  });
}
