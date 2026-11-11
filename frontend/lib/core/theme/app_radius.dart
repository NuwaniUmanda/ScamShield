import 'package:flutter/material.dart';

class AppRadius {
  // Radius values
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0;

  // BorderRadius objects
  static final BorderRadius card = BorderRadius.circular(lg);
  static final BorderRadius button = BorderRadius.circular(md);
  static final BorderRadius input = BorderRadius.circular(md);
  static final BorderRadius badge = BorderRadius.circular(20.0);
  static final BorderRadius chip = BorderRadius.circular(sm);
  static final BorderRadius pill = BorderRadius.circular(full);
}
