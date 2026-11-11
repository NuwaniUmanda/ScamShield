import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../providers/auth_provider.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenuToggle;
  final Function(String)? onSearch;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenuToggle,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final userName = user?.name ?? 'Security Officer';
    final userRole = user?.role ?? 'SecOps Admin';
    final userInitials = userName.isNotEmpty
        ? (userName.contains(' ')
            ? '${userName.split(' ').first[0]}${userName.split(' ').last[0]}'
            : (userName.length >= 2 ? userName.substring(0, 2) : userName))
        : 'SO';

    return Container(
      height: 72,
      padding: AppSpacing.pageHorizontal,
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textPrimary),
              onPressed: onMenuToggle,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Quick Global Search Bar (on large desktop)
          if (MediaQuery.of(context).size.width >= 1100) ...[
            Container(
              width: 220,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.button,
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                onChanged: onSearch,
                decoration: const InputDecoration(
                  hintText: 'Search scams, URLs...',
                  hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: Icon(Icons.search, size: 16, color: AppColors.textMuted),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Notification Bell
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.button,
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  icon: const Icon(Icons.notifications_none, size: 20, color: AppColors.textSecondary),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No new alerts. Ledger node synchronized.'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.highRisk,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // User Profile Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.button,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    userInitials.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        userRole,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
