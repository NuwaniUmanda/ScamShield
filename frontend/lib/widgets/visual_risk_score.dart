import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/scam_report.dart';

class VisualRiskScore extends StatelessWidget {
  final double score; // 0 to 100
  final double confidence; // 0 to 100
  final String category;
  final RiskLevel riskLevel;
  final String verdict;

  const VisualRiskScore({
    super.key,
    required this.score,
    required this.confidence,
    required this.category,
    required this.riskLevel,
    this.verdict = 'Potential Scam Detected',
  });

  Color _getRiskColor() {
    switch (riskLevel) {
      case RiskLevel.critical:
      case RiskLevel.high:
        return AppColors.highRisk;
      case RiskLevel.medium:
        return AppColors.mediumRisk;
      case RiskLevel.low:
        return AppColors.success;
    }
  }

  Color _getRiskBg() {
    switch (riskLevel) {
      case RiskLevel.critical:
      case RiskLevel.high:
        return const Color(0xFFFEF2F2);
      case RiskLevel.medium:
        return const Color(0xFFFFFBEB);
      case RiskLevel.low:
        return const Color(0xFFF0FDF4);
    }
  }

  Color _getRiskBorder() {
    switch (riskLevel) {
      case RiskLevel.critical:
      case RiskLevel.high:
        return const Color(0xFFFECACA);
      case RiskLevel.medium:
        return const Color(0xFFFDE68A);
      case RiskLevel.low:
        return const Color(0xFFBBF7D0);
    }
  }

  String _getRiskLevelLabel() {
    switch (riskLevel) {
      case RiskLevel.critical:
        return 'CRITICAL RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.medium:
        return 'MEDIUM RISK';
      case RiskLevel.low:
        return 'LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor();
    final riskBg = _getRiskBg();
    final riskBorder = _getRiskBorder();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Banner with Verdict & High Risk Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: riskBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: riskBorder, width: 1.5),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: riskBorder),
                      ),
                      child: Icon(
                        riskLevel == RiskLevel.low
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: riskColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      verdict,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                // Risk Badge (e.g. HIGH RISK)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: riskColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        _getRiskLevelLabel(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Visual Risk Metrics & Gauges
          Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;

                if (isWide) {
                  return Row(
                    children: [
                      // Radial Score Circle (Risk Score: 92%)
                      _buildCircularScore(riskColor),
                      const SizedBox(width: 32),
                      // Key Metrics Column (AI Confidence, Category, Threat Level)
                      Expanded(
                        child: _buildMetricsGrid(riskColor),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Center(child: _buildCircularScore(riskColor)),
                    const SizedBox(height: 24),
                    _buildMetricsGrid(riskColor),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore(Color riskColor) {
    final scoreInt = score.round();
    final progress = (score / 100.0).clamp(0.0, 1.0);

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background track
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF1F5F9)),
            ),
          ),
          // Gradient or colored progress
          SizedBox(
            width: 130,
            height: 130,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$scoreInt%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: riskColor,
                  letterSpacing: -1,
                  height: 1.1,
                ),
              ),
              const Text(
                'Risk Score',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(Color riskColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricTile(
                title: 'Risk Score:',
                value: '${score.toStringAsFixed(0)}%',
                valueColor: riskColor,
                icon: Icons.speed_rounded,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              _buildMetricTile(
                title: 'AI Confidence:',
                value: '${confidence.toStringAsFixed(0)}%',
                valueColor: AppColors.primary,
                icon: Icons.psychology_outlined,
                isFullWidth: true,
              ),
              const SizedBox(height: 12),
              _buildMetricTile(
                title: 'Category:',
                value: category,
                valueColor: AppColors.textPrimary,
                icon: Icons.category_outlined,
                isFullWidth: true,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Risk Score:',
                    value: '${score.toStringAsFixed(0)}%',
                    valueColor: riskColor,
                    icon: Icons.speed_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricTile(
                    title: 'AI Confidence:',
                    value: '${confidence.toStringAsFixed(0)}%',
                    valueColor: AppColors.primary,
                    icon: Icons.psychology_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricTile(
              title: 'Category:',
              value: category,
              valueColor: AppColors.textPrimary,
              icon: Icons.category_outlined,
              isFullWidth: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: valueColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
