import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;

  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.textMuted,
              ),
            ),
          ],
          InkWell(
            onTap: items[i].onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: i == items.length - 1 ? FontWeight.w600 : FontWeight.w400,
                  color: i == items.length - 1 ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
