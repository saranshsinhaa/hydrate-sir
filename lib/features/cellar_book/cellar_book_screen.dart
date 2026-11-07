import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../core/format.dart';
import '../../core/hydration.dart';
import '../../core/ledger.dart';

enum LedgerRange { week, month }

final ledgerRangeProvider = NotifierProvider<_RangeNotifier, LedgerRange>(
  _RangeNotifier.new,
);

class _RangeNotifier extends Notifier<LedgerRange> {
  @override
  LedgerRange build() => LedgerRange.week;

  void set(LedgerRange r) => state = r;
}

/// Daily totals for the chosen range, oldest first, ending today.
final ledgerTotalsProvider = StreamProvider<Map<DateTime, int>>((ref) {
  final range = ref.watch(ledgerRangeProvider);
  final today = ref.watch(householdDayProvider);
  final boundary = ref.watch(
    profileProvider.select((p) => p.dayBoundaryMinutes),
  );
  final days = range == LedgerRange.week ? 7 : 30;
  return ref
      .watch(intakeRepositoryProvider)
      .watchDailyTotals(
        firstDay: DateTime(today.year, today.month, today.day - (days - 1)),
        days: days,
        boundaryMinutes: boundary,
      );
});

/// 7 · The Cellar Book (DESIGN.md §6).
class CellarBookScreen extends ConsumerWidget {
  const CellarBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final range = ref.watch(ledgerRangeProvider);
    final totals = ref.watch(ledgerTotalsProvider).value ?? const {};
    final entries = totals.entries.toList();
    final complete = entries.isEmpty
        ? entries
        : entries.sublist(0, entries.length - 1);
    final goal = p.goalMl;
    final stats = ledgerStats([for (final e in complete) e.value], goal);
    final worst = stats.worstIndex == null
        ? null
        : dayName(complete[stats.worstIndex!].key);
    final h = Hargreaves.of(p);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(HsSpace.side, 26, HsSpace.side, 22),
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('The Cellar Book', style: HsText.h1),
                ),
              ),
              InkSegments<LedgerRange>(
                options: const [
                  ChipOption(LedgerRange.week, 'Week'),
                  ChipOption(LedgerRange.month, 'Month'),
                ],
                selected: range,
                onChanged: ref.read(ledgerRangeProvider.notifier).set,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            h.cellarRemark(
              month: range == LedgerRange.month,
              metRatio: stats.metRatio,
              worstDay: worst,
            ),
            style: HsText.voice,
          ),
          const SizedBox(height: 16),
          LabelCard(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
            child: _Chart(
              entries: entries,
              goal: goal,
              month: range == LedgerRange.month,
            ),
          ),
          const SizedBox(height: 8),
          const _ChartLegend(),
          const SizedBox(height: 16),
          _Stats(stats: stats),
          const SizedBox(height: 20),
          const Eyebrow('Recent days'),
          const SizedBox(height: 4),
          for (final e in entries.reversed.take(7))
            _DayRow(
              day: e.key,
              ml: e.value,
              goal: goal,
              glassMl: p.glassSizeMl,
              glasses: p.glassCount,
            ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({
    required this.entries,
    required this.goal,
    required this.month,
  });

  final List<MapEntry<DateTime, int>> entries;
  final int goal;
  final bool month;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<int>(0, (m, e) => e.value > m ? e.value : m);
    final top = [
      goal * 1.18,
      maxValue.toDouble(),
    ].reduce((a, b) => a > b ? a : b);
    final met = entries.where((e) => e.value >= goal).length;
    return Semantics(
      label:
          '${entries.length} days charted; the agreed amount was met on $met.',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarsPainter(
                values: [for (final e in entries) e.value],
                goal: goal,
                top: top,
                gap: month ? 2 : 10,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < entries.length; i++)
                Expanded(
                  child: Text(
                    _axisLabel(entries, i),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                    style: HsText.courier(11),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _axisLabel(List<MapEntry<DateTime, int>> e, int i) {
    final d = e[i].key;
    if (!month) return dayInitial(d);
    if (i == 0 || d.day == 1) return monthShort(d);
    return '';
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.values,
    required this.goal,
    required this.top,
    required this.gap,
  });

  final List<int> values;
  final int goal;
  final double top;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final w = size.width, h = size.height;
    final barW = (w - gap * (values.length - 1)) / values.length;
    final ink = Paint()
      ..color = HsColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = HsColors.ink;
    final hatch = Paint()
      ..color = HsColors.ink
      ..strokeWidth = 1;

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final left = i * (barW + gap);
      final barH = (v / top).clamp(0.0, 1.0) * h;
      final r = Rect.fromLTWH(left, h - barH, barW, barH);
      if (v >= goal) {
        canvas.drawRect(r, fill);
      } else {
        canvas.save();
        canvas.clipRect(r);
        for (var x = r.left - r.height; x < r.right; x += 4) {
          canvas.drawLine(
            Offset(x, r.bottom),
            Offset(x + r.height, r.top),
            hatch,
          );
        }
        canvas.restore();
      }
      canvas.drawPath(
        Path()
          ..moveTo(r.left, r.bottom)
          ..lineTo(r.left, r.top)
          ..lineTo(r.right, r.top)
          ..lineTo(r.right, r.bottom),
        ink,
      );
    }

    // Axis.
    canvas.drawLine(Offset(0, h), Offset(w, h), ink);

    // Goal line, dashed, with its label.
    final gy = h - (goal / top) * h;
    final dash = Paint()
      ..color = HsColors.stamp
      ..strokeWidth = 1.5;
    for (var x = 0.0; x < w; x += 7) {
      canvas.drawLine(Offset(x, gy), Offset((x + 4).clamp(0, w), gy), dash);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: 'AGREED ${spaced(goal)}',
        style: HsText.courier(11, bold: true, color: HsColors.stamp),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelRect = Rect.fromLTWH(
      w - tp.width - 6,
      gy - tp.height - 4,
      tp.width + 6,
      tp.height + 2,
    );
    canvas.drawRect(labelRect, Paint()..color = HsColors.label);
    tp.paint(canvas, Offset(w - tp.width - 3, gy - tp.height - 3));
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.values != values || old.goal != goal || old.gap != gap;
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = HsColors.ink
      ..strokeWidth = 1;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 4) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter old) => false;
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    Widget swatch({required bool solid}) => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: solid ? HsColors.ink : HsColors.label,
        border: Border.all(color: HsColors.ink),
      ),
      child: solid ? null : const CustomPaint(painter: _HatchPainter()),
    );
    return ExcludeSemantics(
      child: Row(
        spacing: 6,
        children: [
          swatch(solid: true),
          Text('Goal met', style: HsText.courier(11)),
          const SizedBox(width: 10),
          swatch(solid: false),
          Text('Fell short', style: HsText.courier(11)),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.stats});

  final LedgerStats stats;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, {bool first = false}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            left: first
                ? BorderSide.none
                : const BorderSide(color: HsColors.ink),
          ),
        ),
        child: Semantics(
          label: '$label: $value',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Eyebrow(label),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: HsText.courier(20, bold: true)),
              ),
            ],
          ),
        ),
      ),
    );
    final s = stats;
    return Container(
      decoration: const BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: HsColors.ink)),
      ),
      child: Row(
        children: [
          cell(
            'Daily avg',
            s.days == 0 ? '—' : '${(s.averageMl / 1000).toStringAsFixed(2)} L',
            first: true,
          ),
          cell('Days met', '${s.metDays} of ${s.days}'),
          cell('Best run', '${s.bestRun} ${s.bestRun == 1 ? 'day' : 'days'}'),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.ml,
    required this.goal,
    required this.glassMl,
    required this.glasses,
  });

  final DateTime day;
  final int ml;
  final int goal;
  final int glassMl;
  final int glasses;

  @override
  Widget build(BuildContext context) {
    final met = ml >= goal;
    final taken = (ml ~/ glassMl).clamp(0, glasses);
    return Semantics(
      label:
          '${proseDate(day)}: $ml millilitres, $taken of $glasses glasses'
          '${met ? ', goal met' : ''}',
      excludeSemantics: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(eyebrowDate(day), style: HsText.courier(13)),
                ),
                Text('$taken / $glasses', style: HsText.courier(13)),
                SizedBox(
                  width: 64,
                  child: met
                      ? const Center(child: Stamp('Met', fontSize: 10))
                      : null,
                ),
                SizedBox(
                  width: 62,
                  child: Text(
                    spaced(ml),
                    textAlign: TextAlign.right,
                    style: HsText.courier(15, bold: true),
                  ),
                ),
              ],
            ),
          ),
          const DashedRule(),
        ],
      ),
    );
  }
}
