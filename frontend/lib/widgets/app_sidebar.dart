import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/router/app_router.dart';
import '../providers/auth_provider.dart';
import 'app_logo.dart';

enum NavSection {
  dashboard,
  aiDetection,
  searchScam,
  reportScam,
  statistics,
  myReports,
  settings,
  logout,
}

class AppSidebar extends StatelessWidget {
  final String? currentPath;
  final NavSection? currentSection;
  final Function(NavSection)? onSectionSelected;

  const AppSidebar({
    super.key,
    this.currentPath,
    this.currentSection,
    this.onSectionSelected,
  });

  bool _isItemActive(String routePath, NavSection section) {
    if (currentPath != null) {
      if (routePath == AppRoutes.dashboard && (currentPath == AppRoutes.dashboard || currentPath == '/')) {
        return true;
      }
      return currentPath!.startsWith(routePath);
    }
    return currentSection == section;
  }

  void _handleNavigation(BuildContext context, String routePath, NavSection section) {
    if (onSectionSelected != null) {
      onSectionSelected!(section);
    }
    context.go(routePath);
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to end your SecOps session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthProvider>().signOut();
              context.go(AppRoutes.splash);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.highRisk),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _handleSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Security Settings'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Connected Ledger: ScamShield Decentralized Node #12'),
            SizedBox(height: 6),
            Text('• AI Model: Transformer NLP v2.4 (Active)'),
            SizedBox(height: 6),
            Text('• Threat Intelligence Feeds: Real-time sync enabled'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.sidebar,
            AppColors.sidebarBgDark,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Brand Header with centralized AppLogo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: InkWell(
              onTap: () => context.go(AppRoutes.dashboard),
              child: const AppLogo(
                iconSize: 22,
                withIconCard: true,
                textColor: Colors.white,
                subtitleColor: AppColors.sidebarTextInactive,
                showSubtitle: true,
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0x26FFFFFF), height: 1),
          ),

          const SizedBox(height: 18),

          // Menu Category Label
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'MAIN NAVIGATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0x99FFFFFF),
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Navigation Links in exact requested order
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.dashboard,
                  section: NavSection.dashboard,
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                ),
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.aiDetection,
                  section: NavSection.aiDetection,
                  title: 'AI Detection',
                  icon: Icons.auto_awesome_rounded,
                ),
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.searchScam,
                  section: NavSection.searchScam,
                  title: 'Search Scam',
                  icon: Icons.search_rounded,
                ),
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.reportScam,
                  section: NavSection.reportScam,
                  title: 'Report Scam',
                  icon: Icons.add_moderator_rounded,
                ),
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.statistics,
                  section: NavSection.statistics,
                  title: 'Statistics',
                  icon: Icons.bar_chart_rounded,
                ),
                _buildNavItem(
                  context: context,
                  routePath: AppRoutes.myReports,
                  section: NavSection.myReports,
                  title: 'My Reports',
                  icon: Icons.description_outlined,
                ),
              ],
            ),
          ),

          // Bottom Navigation Section (Settings & Logout)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Color(0x26FFFFFF), height: 1),
          ),

          const SizedBox(height: 6),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _buildActionItem(
                  title: 'Settings',
                  icon: Icons.settings_outlined,
                  onTap: () => _handleSettings(context),
                ),
                _buildActionItem(
                  title: 'Logout',
                  icon: Icons.logout_rounded,
                  onTap: () => _handleLogout(context),
                  textColor: const Color(0xFFFCA5A5),
                  iconColor: const Color(0xFFF87171),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Bottom Blockchain Node Status Badge
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: AppRadius.card,
              border: Border.all(color: const Color(0x2EFFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80), // Active green
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blockchain Node',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Ledger Synced (100%)',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.sidebarTextInactive,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.lock_outline,
                  color: Colors.white70,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required String routePath,
    required NavSection section,
    required String title,
    required IconData icon,
  }) {
    final isActive = _isItemActive(routePath, section);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNavigation(context, routePath, section),
          borderRadius: AppRadius.button,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppColors.sidebarActiveItemBg : Colors.transparent,
              borderRadius: AppRadius.button,
              border: isActive
                  ? Border.all(color: const Color(0x40FFFFFF), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.sidebarTextActive : AppColors.sidebarIconInactive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? AppColors.sidebarTextActive : AppColors.sidebarTextInactive,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.button,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.sidebarIconInactive,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? AppColors.sidebarTextInactive,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
