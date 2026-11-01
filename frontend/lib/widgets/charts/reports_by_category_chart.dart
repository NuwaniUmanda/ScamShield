import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/statistics.dart';

class ReportsByCategoryChart extends StatefulWidget {
  final List<ScamTypeDistribution> distributions;
  final int totalCount;

  const ReportsByCategoryChart({
    super.key,
    required this.distributions,
    required this.totalCount,
  });

  @override
  State<ReportsByCategoryChart> createState() => _ReportsByCategoryChartState();
}

class _ReportsByCategoryChartState extends State<ReportsByCategoryChart> {
  int? _hoveredIndex;

  static const List<Color> _chartColors = [
    Color(0xFF1E4DB7), // Primary Royal Blue
    Color(0xFF6366F1), // Indigo
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald Green
    Color(0xFFEC4899), // Pink
  ];

  @override
  Widget build(BuildContext context) {
    final distList = widget.distributions.isNotEmpty
        ? widget.distributions
        : const [
            ScamTypeDistribution(typeName: 'Phishing', count: 4320, percentage: 41.2),
            ScamTypeDistribution(typeName: 'Fake Accounts', count: 2840, percentage: 27.1),
            ScamTypeDistribution(typeName: 'Scam Messages', count: 3450, percentage: 31.7),
          ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 550;

        final chartWidget = Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutChartPainter(
                    distributions: distList,
                    colors: _chartColors,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hoveredIndex != null && _hoveredIndex! < distList.length
                          ? '${distList[_hoveredIndex!].percentage.toStringAsFixed(1)}%'
                          : '${widget.totalCount}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _hoveredIndex != null && _hoveredIndex! < distList.length
                          ? distList[_hoveredIndex!].typeName
                          : 'Total Incidents',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        final legendWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: distList.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final color = _chartColors[idx % _chartColors.length];
            final isHovered = _hoveredIndex == idx;

            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredIndex = idx),
              onExit: (_) => setState(() => _hoveredIndex = null),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isHovered ? AppColors.surfaceMuted : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.typeName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isHovered ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${item.count}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 5, child: chartWidget),
              const SizedBox(width: 20),
              Expanded(flex: 6, child: legendWidget),
            ],
          );
        }

        return Column(
          children: [
            chartWidget,
            const SizedBox(height: 20),
            legendWidget,
          ],
        );
      },
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<ScamTypeDistribution> distributions;
  final List<Color> colors;
  final int? hoveredIndex;

  _DonutChartPainter({
    required this.distributions,
    required this.colors,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    const strokeWidth = 28.0;
    final totalPercentage = distributions.fold<double>(0.0, (sum, e) => sum + e.percentage);
    final totalSafe = totalPercentage == 0 ? 100.0 : totalPercentage;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < distributions.length; i++) {
      final item = distributions[i];
      final sweepAngle = (item.percentage / totalSafe) * 2 * math.pi;
      final color = colors[i % colors.length];
      final isHovered = hoveredIndex == i;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? strokeWidth + 4 : strokeWidth
        ..strokeCap = StrokeCap.butt;

      final rect = Rect.fromCircle(
        center: center,
        radius: outerRadius - (strokeWidth / 2) + (isHovered ? 2 : 0),
      );

      // Draw arc with small gap between segments
      const gapAngle = 0.03;
      final adjustedSweep = sweepAngle > gapAngle ? sweepAngle - gapAngle : sweepAngle;

      canvas.drawArc(rect, startAngle + (gapAngle / 2), adjustedSweep, false, paint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.distributions != distributions;
  }
}
