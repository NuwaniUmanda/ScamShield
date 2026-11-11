import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/scam_report.dart';

class AiIndicatorBar extends StatelessWidget {
  final String title;
  final double shapValue;
  final String? description;
  final RiskLevel severity;
  final double maxShap;

  const AiIndicatorBar({
    super.key,
    required this.title,
    required this.shapValue,
    this.description,
    this.severity = RiskLevel.high,
    this.maxShap = 0.50,
  });

  Color _getIndicatorColor() {
    if (shapValue >= 0.35 || severity == RiskLevel.critical) {
      return AppColors.highRisk;
    } else if (shapValue >= 0.20 || severity == RiskLevel.high) {
      return const Color(0xFFEA580C); // Vibrant dark orange
    } else if (shapValue >= 0.10 || severity == RiskLevel.medium) {
      return AppColors.mediumRisk;
    }
    return AppColors.primary;
  }

  Color _getBgColor() {
    if (shapValue >= 0.20 || severity == RiskLevel.high || severity == RiskLevel.critical) {
      return const Color(0xFFFEF2F2);
    }
    return const Color(0xFFFFFBEB);
  }

  Color _getBorderColor() {
    if (shapValue >= 0.20 || severity == RiskLevel.high || severity == RiskLevel.critical) {
      return const Color(0xFFFEE2E2);
    }
    return const Color(0xFFFEF3C7);
  }

  IconData _getIcon() {
    final lower = title.toLowerCase();
    if (lower.contains('url') || lower.contains('link') || lower.contains('domain')) {
      return Icons.link_off_rounded;
    }
    if (lower.contains('urgent') || lower.contains('pressure') || lower.contains('time')) {
      return Icons.timer_outlined;
    }
    if (lower.contains('credential') || lower.contains('password') || lower.contains('login') || lower.contains('bank')) {
      return Icons.lock_outline_rounded;
    }
    if (lower.contains('trust') || lower.contains('source') || lower.contains('reputation')) {
      return Icons.gpp_maybe_outlined;
    }
    if (lower.contains('redirect') || lower.contains('external') || lower.contains('hop')) {
      return Icons.alt_route_rounded;
    }
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getIndicatorColor();
    final progress = (shapValue / maxShap).clamp(0.05, 1.0);
    final formattedScore = shapValue >= 0
        ? '+${shapValue.toStringAsFixed(2)}'
        : shapValue.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with Icon, Title, and SHAP Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getBgColor(),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _getBorderColor(), width: 1),
                ),
                child: Icon(_getIcon(), size: 16, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBgColor(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _getBorderColor(), width: 1),
                ),
                child: Text(
                  formattedScore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // SHAP Bar Progress
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 7,
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.7),
                          color,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
