import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A glass of water on a silver tray (docs/design.md §5.12), drawn on a
/// 220 × 150 grid and scaled to fit.
class TrayIllustration extends StatelessWidget {
  const TrayIllustration({super.key, this.width = 220, this.onDark = false});

  final double width;

  /// Draw in label colour for dark backdrops.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'A glass of water on a silver tray',
      child: CustomPaint(
        size: Size(width, width * 150 / 220),
        painter: _TrayPainter(onDark: onDark),
      ),
    );
  }
}

class _TrayPainter extends CustomPainter {
  _TrayPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 220);
    final ink = onDark ? HsColors.label : HsColors.ink;
    final surface = onDark ? HsColors.inkDeep : HsColors.label;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = surface;

    // Glass.
    final glass = Path()
      ..moveTo(88, 22)
      ..lineTo(132, 22)
      ..lineTo(126, 114)
      ..lineTo(94, 114)
      ..close();
    canvas.drawPath(glass, fill);
    final water = Path()
      ..moveTo(91, 58)
      ..lineTo(129, 58)
      ..lineTo(125.4, 114)
      ..lineTo(94.6, 114)
      ..close();
    canvas.drawPath(water, Paint()..color = HsColors.water);
    canvas.drawLine(const Offset(91, 58), const Offset(129, 58), stroke);
    canvas.drawPath(glass, stroke);
    canvas.drawLine(
      const Offset(100, 34),
      const Offset(100, 94),
      Paint()
        ..color = ink.withValues(alpha: 0.6)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );

    // Tray.
    final tray = Rect.fromCenter(
      center: const Offset(110, 122),
      width: 184,
      height: 28,
    );
    canvas.drawOval(tray, fill);
    canvas.drawOval(tray, stroke);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(110, 119), width: 156, height: 18),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(18, 122)
        ..cubicTo(8, 122, 6, 112, 14, 110)
        ..moveTo(202, 122)
        ..cubicTo(212, 122, 214, 112, 206, 110),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(72, 132)
        ..lineTo(66, 144)
        ..moveTo(148, 132)
        ..lineTo(154, 144)
        ..moveTo(60, 144)
        ..lineTo(72, 144)
        ..moveTo(148, 144)
        ..lineTo(160, 144),
      stroke,
    );

    // Sparkle.
    canvas.drawPath(
      Path()
        ..moveTo(150, 18)
        ..lineTo(154, 10)
        ..moveTo(160, 26)
        ..lineTo(168, 22)
        ..moveTo(156, 8)
        ..lineTo(158, 2),
      Paint()
        ..color = onDark ? HsColors.label : HsColors.stamp
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_TrayPainter old) => old.onDark != onDark;
}

/// Hargreaves' bow tie, the app mark (14 × 10 grid).
class BowTie extends StatelessWidget {
  const BowTie({super.key, this.width = 14, this.color = HsColors.ink});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, width * 10 / 14),
        painter: _BowTiePainter(color),
      ),
    );
  }
}

class _BowTiePainter extends CustomPainter {
  _BowTiePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 14);
    final paint = Paint()..color = color;
    canvas.drawPath(
      Path()
        ..moveTo(0, 1.5)
        ..lineTo(5.5, 4)
        ..lineTo(5.5, 6)
        ..lineTo(0, 8.5)
        ..close()
        ..moveTo(14, 1.5)
        ..lineTo(8.5, 4)
        ..lineTo(8.5, 6)
        ..lineTo(14, 8.5)
        ..close(),
      paint,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(5.2, 3.4, 8.8, 6.6, const Radius.circular(0.8)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_BowTiePainter old) => old.color != color;
}

/// Undo arrow, line-drawn.
class UndoGlyph extends StatelessWidget {
  const UndoGlyph({super.key, this.size = 24, this.color = HsColors.ink});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _UndoPainter(color));
  }
}

class _UndoPainter extends CustomPainter {
  _UndoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    canvas.drawPath(
      Path()
        ..moveTo(9, 5)
        ..lineTo(4, 10)
        ..lineTo(9, 15)
        ..moveTo(4, 10)
        ..lineTo(14, 10)
        ..cubicTo(17.9, 10, 20, 12.5, 20, 15.5)
        ..cubicTo(20, 18.5, 17.9, 20, 14, 20)
        ..lineTo(11, 20),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_UndoPainter old) => old.color != color;
}
