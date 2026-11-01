import 'package:flutter/material.dart';

class AppSpacing {
  // Spacing values
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Semantic paddings
  static const EdgeInsets page = EdgeInsets.all(24.0);
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets card = EdgeInsets.all(20.0);
  static const EdgeInsets cardHeader = EdgeInsets.only(left: 20.0, right: 20.0, top: 18.0, bottom: 12.0);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0);
  static const EdgeInsets buttonSmall = EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0);
  static const EdgeInsets input = EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0);
  static const EdgeInsets badge = EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0);
  static const EdgeInsets tableCell = EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);
}
