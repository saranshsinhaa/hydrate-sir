import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';

/// The double-ruled label card (DESIGN.md §5.1).
class LabelCard extends StatelessWidget {
  const LabelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HsColors.label,
        border: Border.all(color: HsColors.ink, width: HsStroke.outer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: HsColors.ink, width: HsStroke.inner),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A box with a 1 px dashed ink border, used for Hargreaves' estimates.
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.color = HsColors.ink,
    this.fill = HsColors.label,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(color: color, fill: fill),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({required this.color, required this.fill});

  final Color color;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = fill);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rect = (Offset.zero & size).deflate(0.5);
    _dashLine(canvas, rect.topLeft, rect.topRight, paint);
    _dashLine(canvas, rect.topRight, rect.bottomRight, paint);
    _dashLine(canvas, rect.bottomRight, rect.bottomLeft, paint);
    _dashLine(canvas, rect.bottomLeft, rect.topLeft, paint);
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.fill != fill;
}

/// Draws a dashed line from [a] to [b]: 4 px dash, 3 px gap.
void _dashLine(Canvas canvas, Offset a, Offset b, Paint paint) {
  const dash = 4.0, gap = 3.0;
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  var d = 0.0;
  while (d < total) {
    final end = math.min(d + dash, total);
    canvas.drawLine(a + dir * d, a + dir * end, paint);
    d += dash + gap;
  }
}

/// A horizontal dashed rule, used for ledger lines and the goal line.
class DashedRule extends StatelessWidget {
  const DashedRule({super.key, this.color = HsColors.rule, this.thickness = 1});

  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: thickness,
      width: double.infinity,
      child: CustomPaint(
        painter: _DashedLinePainter(color: color, thickness: thickness),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color, required this.thickness});

  final Color color;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    _dashLine(
      canvas,
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = color
        ..strokeWidth = thickness,
    );
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color || old.thickness != thickness;
}

/// Thin progress bar at the foot of the Today card (DESIGN.md §5.10).
class ProgressRule extends StatelessWidget {
  const ProgressRule({super.key, required this.fraction});

  /// Taken / goal. Clamped to 0..1.
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    return Semantics(
      label: '${(f * 100).round()} percent of the day\'s water taken',
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          border: Border.all(color: HsColors.ink, width: 1),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: _motion(context, const Duration(milliseconds: 200)),
            widthFactor: f,
            heightFactor: 1,
            child: const ColoredBox(color: HsColors.ink),
          ),
        ),
      ),
    );
  }
}

/// A 4-point star between two ink rules (DESIGN.md §5.12).
class Ornament extends StatelessWidget {
  const Ornament({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        child: const Row(
          children: [
            Expanded(child: Divider(color: HsColors.ink, thickness: 1)),
            SizedBox(width: 10),
            CustomPaint(size: Size(14, 14), painter: _StarPainter()),
            SizedBox(width: 10),
            Expanded(child: Divider(color: HsColors.ink, thickness: 1)),
          ],
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 14;
    final path = Path()
      ..moveTo(7 * s, 0)
      ..lineTo(8.6 * s, 5.4 * s)
      ..lineTo(14 * s, 7 * s)
      ..lineTo(8.6 * s, 8.6 * s)
      ..lineTo(7 * s, 14 * s)
      ..lineTo(5.4 * s, 8.6 * s)
      ..lineTo(0, 7 * s)
      ..lineTo(5.4 * s, 5.4 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = HsColors.stamp);
  }

  @override
  bool shouldRepaint(_StarPainter old) => false;
}

/// Small uppercase Courier label for sections ("ABOUT YOU").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = HsColors.ink});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: HsText.eyebrow.copyWith(color: color),
    );
  }
}

/// A rubber stamp (DESIGN.md §5.2). Decorative: excluded from semantics.
/// Re-stamps (scale and settle) whenever [text] changes.
class Stamp extends StatelessWidget {
  const Stamp(this.text, {super.key, this.angle = -7, this.fontSize = 13});

  final String text;

  /// Rotation in degrees.
  final double angle;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: HsColors.stamp, width: 2.2),
      ),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: HsText.stamp.copyWith(fontSize: fontSize, color: HsColors.stamp),
      ),
    );
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(text),
        tween: Tween(begin: 0, end: 1),
        duration: _motion(context, const Duration(milliseconds: 180)),
        curve: Curves.easeOutBack,
        builder: (context, t, child) {
          final scale = 1.15 - 0.15 * t;
          final settle = (1 - t) * 2;
          return Transform.rotate(
            angle: (angle + settle) * math.pi / 180,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: label,
      ),
    );
  }
}

/// Zero duration when the user asked the system to reduce motion.
Duration _motion(BuildContext context, Duration d) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : d;

/// Public helper for other widgets.
Duration hsMotion(BuildContext context, Duration d) => _motion(context, d);
