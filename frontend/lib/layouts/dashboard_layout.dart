import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/router/app_router.dart';
import '../providers/scam_provider.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';

class DashboardLayout extends StatefulWidget {
  final String? currentPath;
  final Widget? child;

  const DashboardLayout({
    super.key,
    this.currentPath,
    this.child,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getHeaderTitle(String path) {
    if (path.startsWith('/scam-details')) {
      return 'Scam Report Details';
    }
    switch (path) {
      case AppRoutes.dashboard:
        return 'Overview Dashboard';
      case AppRoutes.aiDetection:
        return 'AI Scam Detection & Analysis';
      case AppRoutes.searchScam:
        return 'Search Scam Database';
      case AppRoutes.reportScam:
        return 'Report a Scam Incident';
      case AppRoutes.statistics:
        return 'Analytics & Threat Intelligence';
      case AppRoutes.myReports:
        return 'Incident Reports Ledger';
      default:
        return 'ScamShield Security';
    }
  }

  String? _getHeaderSubtitle(String path) {
    if (path.startsWith('/scam-details')) {
      return 'Decentralized cryptographic verification & AI threat evaluation';
    }
    switch (path) {
      case AppRoutes.dashboard:
        return 'Real-time AI detection and decentralized scam defense ledger';
      case AppRoutes.aiDetection:
        return 'Deep learning neural evaluation & smart contract verification';
      case AppRoutes.searchScam:
        return 'Search through verified incident reports and threat feeds';
      case AppRoutes.reportScam:
        return 'Submit suspicious messages, phishing URLs, or crypto fraud';
      case AppRoutes.statistics:
        return 'Global scam trends, detection accuracy, and category breakdown';
      case AppRoutes.myReports:
        return 'Manage and review historical scam records';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final path = widget.currentPath ?? GoRouterState.of(context).uri.path;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: isDesktop
          ? null
          : Drawer(
              width: 250,
              child: AppSidebar(
                currentPath: path,
                onSectionSelected: (_) {
                  if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
      body: Row(
        children: [
          if (isDesktop)
            AppSidebar(
              currentPath: path,
            ),
          Expanded(
            child: Column(
              children: [
                AppHeader(
                  title: _getHeaderTitle(path),
                  subtitle: _getHeaderSubtitle(path),
                  onMenuToggle: () => _scaffoldKey.currentState?.openDrawer(),
                  onSearch: (q) {
                    context.read<ScamProvider>().searchScams(query: q);
                    if (path != AppRoutes.searchScam) {
                      context.go(AppRoutes.searchScam);
                    }
                  },
                ),
                Expanded(
                  child: SelectionArea(
                    child: widget.child ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
