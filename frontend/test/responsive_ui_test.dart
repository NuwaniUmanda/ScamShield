import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/layouts/dashboard_layout.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/scam_provider.dart';
import 'package:frontend/providers/stats_provider.dart';
import 'package:frontend/providers/detection_provider.dart';
import 'package:frontend/providers/blockchain_provider.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/screens/report_scam/report_scam_screen.dart';
import 'package:frontend/screens/ai_detection/ai_detection_screen.dart';
import 'package:frontend/screens/search_scam/search_scam_screen.dart';
import 'package:frontend/screens/scam_details/scam_details_screen.dart';
import 'package:frontend/screens/statistics/statistics_screen.dart';
import 'package:frontend/screens/my_reports/my_reports_screen.dart';

Widget wrapScreen(Widget child, String currentPath) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ScamProvider()),
      ChangeNotifierProvider(create: (_) => StatsProvider()),
      ChangeNotifierProvider(create: (_) => DetectionProvider()),
      ChangeNotifierProvider(create: (_) => BlockchainProvider()),
    ],
    child: MaterialApp(
      home: DashboardLayout(
        currentPath: currentPath,
        child: child,
      ),
    ),
  );
}

final List<Size> testResolutions = [
  const Size(1920, 1080),
  const Size(1440, 900),
  const Size(1366, 768),
  const Size(1280, 720),
  const Size(1024, 768),
  const Size(800, 600),
];

void main() {
  for (final size in testResolutions) {
    group('Responsive tests at ${size.width.toInt()}x${size.height.toInt()}', () {
      testWidgets('1. Dashboard renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const DashboardScreen(), '/dashboard'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('2. Report Scam renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const ReportScamScreen(), '/report-scam'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(ReportScamScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('3. AI Detection renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const AiDetectionScreen(), '/ai-detection'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(AiDetectionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('4. Search Scam renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const SearchScamScreen(), '/search-scam'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(SearchScamScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('5. Scam Details renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const ScamDetailsScreen(reportId: 'REP-84920'), '/scam-details/REP-84920'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(ScamDetailsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('6. Statistics renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const StatisticsScreen(), '/statistics'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(StatisticsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('7. My Reports renders without overflow', (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(wrapScreen(const MyReportsScreen(), '/my-reports'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.byType(MyReportsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }
}
