import 'package:flutter/painting.dart';

import 'tokens.dart';

/// Type scale from DESIGN.md §3.
///
/// "Hargreaves speaks in Caslon italic; the household's records are typed in
/// Courier."
abstract final class HsText {
  /// Libre Caslon Text is a variable font, so the weight is applied as a
  /// `wght` variation as well as a [FontWeight].
  static TextStyle caslon(
    double size, {
    FontWeight weight = FontWeight.w400,
    bool italic = false,
    double? height,
    Color color = HsColors.ink,
  }) {
    return TextStyle(
      fontFamily: HsFonts.serif,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      height: height,
      color: color,
    );
  }

  /// Courier Prime. [tracking] is letter-spacing in em.
  static TextStyle courier(
    double size, {
    bool bold = false,
    double tracking = 0,
    double? height,
    Color color = HsColors.ink,
  }) {
    return TextStyle(
      fontFamily: HsFonts.mono,
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      letterSpacing: size * tracking,
      height: height,
      color: color,
    );
  }

  static final display = caslon(34, weight: FontWeight.w700, height: 1.05);
  static final h1 = caslon(30, weight: FontWeight.w700, height: 1.15);
  static final h2 = caslon(26, weight: FontWeight.w700, height: 1.25);
  static final bigNumber = caslon(40, weight: FontWeight.w700, height: 1.05);
  static final voice = caslon(17, italic: true, height: 1.45);
  static final voiceLarge = caslon(18, italic: true, height: 1.5);
  static final body = caslon(16, height: 1.5);
  static final small = caslon(13, italic: true, height: 1.4);

  static final numberXL = courier(40, bold: true, height: 1.0);
  static final numberL = courier(28, bold: true, height: 1.0);
  static final unit = courier(14);
  static final button = courier(16, bold: true, tracking: 0.08);
  static final chip = courier(13, bold: true, tracking: 0.04);
  static final eyebrow = courier(12, tracking: 0.14);
  static final stamp = courier(13, bold: true, tracking: 0.08, height: 1.1);
  static final time = courier(12);
}
