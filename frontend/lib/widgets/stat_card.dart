import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? changePercentage;
  final bool isPositive;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.changePercentage,
    this.isPositive = true,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x050F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBgColor ?? AppColors.primarySoft,
                  borderRadius: AppRadius.button,
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (changePercentage != null || subtitle != null)
            Row(
              children: [
                if (changePercentage != null) ...[
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: isPositive ? AppColors.riskLowText : AppColors.riskHighText,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    changePercentage!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPositive ? AppColors.riskLowText : AppColors.riskHighText,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
