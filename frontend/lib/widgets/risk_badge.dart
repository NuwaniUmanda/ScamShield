import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/scam_report.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;
  final double? score;
  final bool showScore;
  final String? customLabel;
  final bool useFullLabel;

  const RiskBadge({
    super.key,
    required this.level,
    this.score,
    this.showScore = false,
    this.customLabel,
    this.useFullLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    Color border;
    String label;

    switch (level) {
      case RiskLevel.critical:
        bg = AppColors.riskHighBg;
        text = AppColors.riskHighText;
        border = AppColors.riskHighBorder;
        label = customLabel ??
            (score != null && showScore
                ? '${score!.toStringAsFixed(0)}% Critical'
                : (useFullLabel ? 'Critical Risk' : 'Critical'));
        break;
      case RiskLevel.high:
        bg = AppColors.riskHighBg;
        text = AppColors.riskHighText;
        border = AppColors.riskHighBorder;
        label = customLabel ??
            (score != null && showScore
                ? '${score!.toStringAsFixed(0)}% High'
                : (useFullLabel ? 'High Risk' : 'High'));
        break;
      case RiskLevel.medium:
        bg = AppColors.riskMediumBg;
        text = AppColors.riskMediumText;
        border = AppColors.riskMediumBorder;
        label = customLabel ??
            (score != null && showScore
                ? '${score!.toStringAsFixed(0)}% Med'
                : (useFullLabel ? 'Medium Risk' : 'Medium'));
        break;
      case RiskLevel.low:
        bg = AppColors.riskLowBg;
        text = AppColors.riskLowText;
        border = AppColors.riskLowBorder;
        label = customLabel ??
            (score != null && showScore
                ? '${score!.toStringAsFixed(0)}% Safe'
                : (useFullLabel ? 'Low Risk' : 'Low Risk'));
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
