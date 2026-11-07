import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'surfaces.dart';

enum GlassState { upcoming, taken, overdue }

/// One glass in the day's row (docs/design.md §5.3).
class GlassSlot extends StatelessWidget {
  const GlassSlot({
    super.key,
    required this.time,
    required this.state,
    this.diameter = 44,
  });

  /// "HH:mm".
  final String time;
  final GlassState state;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final d = hsMotion(context, const Duration(milliseconds: 150));
    final overdue = state == GlassState.overdue;
    final taken = state == GlassState.taken;
    return Semantics(
      label: '$time, ${state.name}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          AnimatedContainer(
            duration: d,
            width: diameter,
            height: diameter,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: taken ? HsColors.ink : Colors.transparent,
              border: Border.all(
                color: overdue ? HsColors.stamp : HsColors.ink,
                width: overdue ? 2 : HsStroke.interactive,
              ),
            ),
            child: switch (state) {
              GlassState.taken => TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: hsMotion(context, const Duration(milliseconds: 200)),
                builder: (context, t, _) =>
                    CustomPaint(painter: _CheckPainter(t)),
              ),
              GlassState.overdue => Center(
                child: Text(
                  '!',
                  style: HsText.courier(
                    diameter * 0.45,
                    bold: true,
                    color: HsColors.stamp,
                  ),
                ),
              ),
              GlassState.upcoming => null,
            },
          ),
          Text(
            time,
            style: HsText.time.copyWith(
              color: overdue ? HsColors.stamp : HsColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A check mark that draws itself as [progress] goes 0 → 1.
class _CheckPainter extends CustomPainter {
  _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.3, w * 0.52)
      ..lineTo(w * 0.44, w * 0.66)
      ..lineTo(w * 0.71, w * 0.37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = HsColors.label
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}
