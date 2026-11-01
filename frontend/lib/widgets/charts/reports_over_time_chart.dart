import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/statistics.dart';

class ReportsOverTimeChart extends StatefulWidget {
  final List<MonthlyTrendPoint> trends;

  const ReportsOverTimeChart({
    super.key,
    required this.trends,
  });

  @override
  State<ReportsOverTimeChart> createState() => _ReportsOverTimeChartState();
}

class _ReportsOverTimeChartState extends State<ReportsOverTimeChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final points = widget.trends.isNotEmpty
        ? widget.trends
        : const [
            MonthlyTrendPoint(month: 'Jan', reportedCount: 650, blockedCount: 590),
            MonthlyTrendPoint(month: 'Feb', reportedCount: 820, blockedCount: 780),
            MonthlyTrendPoint(month: 'Mar', reportedCount: 950, blockedCount: 910),
            MonthlyTrendPoint(month: 'Apr', reportedCount: 1100, blockedCount: 1050),
            MonthlyTrendPoint(month: 'May', reportedCount: 1320, blockedCount: 1280),
            MonthlyTrendPoint(month: 'Jun', reportedCount: 1480, blockedCount: 1430),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend Header
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _buildLegendItem('Reported Incidents', AppColors.primary),
                _buildLegendItem('Neutralized Threats', const Color(0xFF10B981)),
              ],
            ),
            if (_hoveredIndex != null && _hoveredIndex! < points.length)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${points[_hoveredIndex!].month}: ${points[_hoveredIndex!].reportedCount} reported / ${points[_hoveredIndex!].blockedCount} blocked',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Line Chart Area
        SizedBox(
          height: 210,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return MouseRegion(
                onHover: (event) {
                  final segmentWidth = constraints.maxWidth / points.length;
                  final idx = (event.localPosition.dx / segmentWidth).floor().clamp(0, points.length - 1);
                  if (_hoveredIndex != idx) {
                    setState(() => _hoveredIndex = idx);
                  }
                },
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: CustomPaint(
                  size: Size(constraints.maxWidth, 210),
                  painter: _LineChartPainter(
                    points: points,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<MonthlyTrendPoint> points;
  final int? hoveredIndex;

  _LineChartPainter({
    required this.points,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const topPadding = 20.0;
    const bottomPadding = 30.0;
    const leftPadding = 36.0;
    final rightPadding = 16.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Determine max value for Y-axis scale
    const maxY = 1600.0;
    const ySteps = 4;

    // Draw horizontal grid lines and Y-axis labels
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= ySteps; i++) {
      final yVal = (maxY / ySteps) * i;
      final yPos = topPadding + chartHeight - (i / ySteps) * chartHeight;

      // Grid line
      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      // Y-axis text
      textPainter.text = TextSpan(
        text: yVal.toInt().toString(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - (textPainter.height / 2)));
    }

    final reportedOffsets = <Offset>[];
    final blockedOffsets = <Offset>[];

    final stepX = points.length > 1 ? chartWidth / (points.length - 1) : chartWidth;

    for (int i = 0; i < points.length; i++) {
      final x = leftPadding + (i * stepX);
      final reportedY = topPadding + chartHeight - (points[i].reportedCount / maxY) * chartHeight;
      final blockedY = topPadding + chartHeight - (points[i].blockedCount / maxY) * chartHeight;

      reportedOffsets.add(Offset(x, reportedY));
      blockedOffsets.add(Offset(x, blockedY));

      // Draw X-axis month label
      textPainter.text = TextSpan(
        text: points[i].month,
        style: TextStyle(
          fontSize: 11,
          fontWeight: hoveredIndex == i ? FontWeight.w800 : FontWeight.w600,
          color: hoveredIndex == i ? AppColors.primary : AppColors.textSecondary,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - (textPainter.width / 2), size.height - bottomPadding + 10),
      );
    }

    // 1. Draw Area Gradient under Reported Line
    final fillPath = Path();
    fillPath.moveTo(reportedOffsets.first.dx, topPadding + chartHeight);
    fillPath.lineTo(reportedOffsets.first.dx, reportedOffsets.first.dy);

    for (int i = 0; i < reportedOffsets.length - 1; i++) {
      final p0 = reportedOffsets[i];
      final p1 = reportedOffsets[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      fillPath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }
    fillPath.lineTo(reportedOffsets.last.dx, topPadding + chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x331E4DB7),
          Color(0x021E4DB7),
        ],
      ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw Blocked Series Line (Green)
    _drawCurvedLine(canvas, blockedOffsets, const Color(0xFF10B981), 2.5);

    // 3. Draw Reported Series Line (Royal Blue)
    _drawCurvedLine(canvas, reportedOffsets, AppColors.primary, 3.0);

    // 4. Draw Data Point Dots & Hover Indicator
    for (int i = 0; i < reportedOffsets.length; i++) {
      final isHovered = hoveredIndex == i;

      // Blocked dot
      final blockedDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final blockedBorderPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(blockedOffsets[i], 4, blockedDotPaint);
      canvas.drawCircle(blockedOffsets[i], 4, blockedBorderPaint);

      // Reported dot
      final dotPaint = Paint()
        ..color = isHovered ? AppColors.primary : Colors.white
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3.0 : 2.5;

      canvas.drawCircle(reportedOffsets[i], isHovered ? 6 : 4.5, dotPaint);
      canvas.drawCircle(reportedOffsets[i], isHovered ? 6 : 4.5, borderPaint);

      // Vertical guideline for hovered point
      if (isHovered) {
        final guidePaint = Paint()
          ..color = AppColors.primary.withOpacity(0.25)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(reportedOffsets[i].dx, topPadding),
          Offset(reportedOffsets[i].dx, topPadding + chartHeight),
          guidePaint,
        );
      }
    }
  }

  void _drawCurvedLine(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;

    final linePath = Path();
    linePath.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final cx = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.points != points;
  }
}
