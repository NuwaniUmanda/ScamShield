import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class ShieldLogoIcon extends StatelessWidget {
  final double size;
  final Color shieldColor;
  final Color checkColor;
  final bool withBackground;
  final Color? backgroundColor;

  const ShieldLogoIcon({
    super.key,
    this.size = 28,
    this.shieldColor = AppColors.primary,
    this.checkColor = AppColors.primary,
    this.withBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = CustomPaint(
      size: Size(size, size),
      painter: _ShieldLogoPainter(
        color: shieldColor,
        checkColor: checkColor,
      ),
    );

    if (!withBackground) return iconWidget;

    return Container(
      width: size + 14,
      height: size + 14,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: iconWidget),
    );
  }
}

class _ShieldLogoPainter extends CustomPainter {
  final Color color;
  final Color checkColor;

  _ShieldLogoPainter({
    required this.color,
    required this.checkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Shield path
    final path = Path();
    path.moveTo(w * 0.5, h * 0.08);
    // Top right curve
    path.quadraticBezierTo(w * 0.85, h * 0.08, w * 0.88, h * 0.35);
    // Bottom right to tip
    path.cubicTo(w * 0.88, h * 0.70, w * 0.58, h * 0.90, w * 0.5, h * 0.95);
    // Bottom left to tip
    path.cubicTo(w * 0.42, h * 0.90, w * 0.12, h * 0.70, w * 0.12, h * 0.35);
    // Top left curve
    path.quadraticBezierTo(w * 0.15, h * 0.08, w * 0.5, h * 0.08);
    path.close();

    canvas.drawPath(path, shieldPaint);

    // Inner Checkmark
    final checkPaint = Paint()
      ..color = checkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final checkPath = Path();
    checkPath.moveTo(w * 0.32, h * 0.50);
    checkPath.lineTo(w * 0.45, h * 0.63);
    checkPath.lineTo(w * 0.68, h * 0.38);

    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _ShieldLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.checkColor != checkColor;
  }
}

class AppLogo extends StatelessWidget {
  final double iconSize;
  final bool isVertical;
  final Color textColor;
  final Color subtitleColor;
  final bool showSubtitle;
  final String? customSubtitle;
  final bool withIconCard;

  const AppLogo({
    super.key,
    this.iconSize = 24,
    this.isVertical = false,
    this.textColor = Colors.white,
    this.subtitleColor = AppColors.sidebarTextInactive,
    this.showSubtitle = true,
    this.customSubtitle,
    this.withIconCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = ShieldLogoIcon(
      size: iconSize,
      shieldColor: withIconCard ? AppColors.primary : textColor,
      checkColor: withIconCard ? AppColors.primary : textColor,
      withBackground: withIconCard,
    );

    final titleWidget = Text(
      'ScamShield',
      style: TextStyle(
        fontSize: isVertical ? (iconSize * 0.55).clamp(24.0, 36.0) : 18,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.4,
      ),
    );

    final sub = customSubtitle ?? (isVertical ? 'AI Powered Scam Detection' : 'AI & Web3 Defense');
    final subtitleWidget = Text(
      sub,
      style: TextStyle(
        fontSize: isVertical ? 15 : 11,
        fontWeight: isVertical ? FontWeight.w500 : FontWeight.w500,
        color: subtitleColor,
      ),
    );

    if (isVertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(60), width: 1.5),
            ),
            child: ShieldLogoIcon(
              size: iconSize,
              shieldColor: Colors.white,
              checkColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          titleWidget,
          if (showSubtitle) ...[
            const SizedBox(height: 6),
            subtitleWidget,
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ScamShield',
                style: TextStyle(
                  fontSize: isVertical ? (iconSize * 0.55).clamp(24.0, 36.0) : 17,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    fontSize: isVertical ? 15 : 11,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
