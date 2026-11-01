import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/splash/splash_screen.dart';
import '../../layouts/dashboard_layout.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/search_scam/search_scam_screen.dart';
import '../../screens/report_scam/report_scam_screen.dart';
import '../../screens/ai_detection/ai_detection_screen.dart';
import '../../screens/statistics/statistics_screen.dart';
import '../../screens/my_reports/my_reports_screen.dart';
import '../../screens/scam_details/scam_details_screen.dart';
import '../../models/detection_result.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String dashboard = '/';
  static const String searchScam = '/search-scam';
  static const String reportScam = '/report-scam';
  static const String aiDetection = '/ai-detection';
  static const String statistics = '/statistics';
  static const String myReports = '/my-reports';
  static const String scamDetails = '/scam-details/:id';

  static String scamDetailsPath(String id) => '/scam-details/$id';
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.dashboard,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return DashboardLayout(
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.searchScam,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SearchScamScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.reportScam,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReportScamScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.aiDetection,
          pageBuilder: (context, state) {
            final result = state.extra as ScamDetectionResult?;
            return NoTransitionPage(
              child: AiDetectionScreen(result: result),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.statistics,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatisticsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.myReports,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MyReportsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.scamDetails,
          pageBuilder: (context, state) {
            final reportId = state.pathParameters['id'] ?? 'REP-84920';
            return NoTransitionPage(
              child: ScamDetailsScreen(reportId: reportId),
            );
          },
        ),
      ],
    ),
  ],
);
