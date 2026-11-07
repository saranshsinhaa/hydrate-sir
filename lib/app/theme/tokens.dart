import 'package:flutter/painting.dart';

/// Colour tokens from DESIGN.md §2. Flat colours only.
abstract final class HsColors {
  static const paper = Color(0xFFE9E1CC);
  static const label = Color(0xFFF7F2E4);
  static const ink = Color(0xFF1F3B2D);
  static const inkDeep = Color(0xFF16291F);
  static const stamp = Color(0xFFA3271F);
  static const rule = Color(0xFFCFC5AA);

  /// Decorative only. Never for text.
  static const sage = Color(0xFF7C8F80);

  /// Illustrations only.
  static const water = Color(0xFFA9C2B3);
}

abstract final class HsFonts {
  static const serif = 'LibreCaslon';
  static const mono = 'CourierPrime';
}

/// Spacing scale from DESIGN.md §4.
abstract final class HsSpace {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 22;
  static const double xxl = 26;

  /// Horizontal screen padding.
  static const double side = 20;

  /// Minimum touch target.
  static const double target = 48;
}

/// Border widths from DESIGN.md §4.
abstract final class HsStroke {
  static const double interactive = 1.5;
  static const double outer = 2;
  static const double inner = 1;
}
