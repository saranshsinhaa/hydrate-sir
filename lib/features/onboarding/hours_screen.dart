import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../copy/text.dart';
import '../../core/format.dart';
import '../../core/profile.dart';
import 'arrangements_screen.dart';
import 'onboarding_draft.dart';

/// 3 · Your Hours (docs/design.md §6).
class HoursScreen extends ConsumerWidget {
  const HoursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(onboardingDraftProvider);
    final draft = ref.read(onboardingDraftProvider.notifier);
    final h = Hargreaves.of(p);
    return PaperPage(
      step: HoursText.step,
      onBack: () => Navigator.of(context).maybePop(),
      title: HoursText.title,
      voice: 'When do you rise, ${h.you}, and when do you retire?',
      primaryLabel: CommonText.continueOn,
      onPrimary: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ArrangementsScreen()),
      ),
      children: [
        HoursForm(profile: p, onChange: draft.update),
        const SizedBox(height: 20),
        const Eyebrow(HoursText.glance),
        const SizedBox(height: 8),
        DayBar(wake: p.wakeMinutes, sleep: p.sleepMinutes),
        const SizedBox(height: 14),
        _Legend(
          swatch: const _Swatch.ink(),
          text:
              'I attend to you, ${hm(p.wakeMinutes)} – '
              '${hm(p.sleepMinutes - 60)}',
        ),
        const _Legend(swatch: _Swatch.sage(), text: HoursText.quiet),
        const _Legend(swatch: _Swatch.hatched(), text: HoursText.sleep),
        const SizedBox(height: 14),
        Text(
          '${Hargreaves.wakingHours(p.sleepMinutes - p.wakeMinutes)}. '
          '${HoursText.silence}',
          style: HsText.voice,
        ),
      ],
    );
  }
}

/// Rise and retire steppers, shared with Standing Instructions.
class HoursForm extends StatelessWidget {
  const HoursForm({super.key, required this.profile, required this.onChange});

  final Profile profile;
  final void Function(Profile Function(Profile)) onChange;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    const step = 15;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        LabelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              const Eyebrow(HoursText.rise),
              InkStepper(
                value: hm(p.wakeMinutes),
                semanticName: 'rising time',
                valueStyle: HsText.courier(34, bold: true, height: 1),
                onDecrement: p.wakeMinutes - step >= Profile.earliestWake
                    ? () => onChange(
                        (x) => x.copyWith(wakeMinutes: x.wakeMinutes - step),
                      )
                    : null,
                onIncrement:
                    p.sleepMinutes - (p.wakeMinutes + step) >= Profile.minAwake
                    ? () => onChange(
                        (x) => x.copyWith(wakeMinutes: x.wakeMinutes + step),
                      )
                    : null,
              ),
            ],
          ),
        ),
        LabelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 6,
            children: [
              const Eyebrow(HoursText.retire),
              InkStepper(
                value: hm(p.sleepMinutes),
                semanticName: 'retiring time',
                valueStyle: HsText.courier(34, bold: true, height: 1),
                onDecrement:
                    (p.sleepMinutes - step) - p.wakeMinutes >= Profile.minAwake
                    ? () => onChange(
                        (x) => x.copyWith(sleepMinutes: x.sleepMinutes - step),
                      )
                    : null,
                onIncrement: p.sleepMinutes + step <= Profile.latestSleep
                    ? () => onChange(
                        (x) => x.copyWith(sleepMinutes: x.sleepMinutes + step),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 24-hour bar: hatched sleep, ink reminder window, sage quiet hour.
class DayBar extends StatelessWidget {
  const DayBar({super.key, required this.wake, required this.sleep});

  final int wake;
  final int sleep;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          SizedBox(
            height: 26,
            child: CustomPaint(painter: _DayBarPainter(wake, sleep)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in ['00', '06', '12', '18', '24'])
                Text(t, style: HsText.time),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayBarPainter extends CustomPainter {
  _DayBarPainter(this.wake, this.sleep);

  final int wake;
  final int sleep;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;

    // Sleep everywhere, then paint the waking hours over it.
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawRect(rect, Paint()..color = HsColors.label);
    final hatch = Paint()
      ..color = HsColors.ink
      ..strokeWidth = 1;
    for (var i = -h; i < w; i += 4) {
      canvas.drawLine(Offset(i, h), Offset(i + h, 0), hatch);
    }
    canvas.restore();

    // Draws [from, to) in minutes, wrapping past midnight.
    void span(int from, int to, Color c) {
      if (to <= from) return;
      final p = Paint()..color = c;
      void draw(int a, int b) =>
          canvas.drawRect(Rect.fromLTRB(a / 1440 * w, 0, b / 1440 * w, h), p);
      final s = from % 1440, e = s + (to - from);
      if (e <= 1440) {
        draw(s, e);
      } else {
        draw(s, 1440);
        draw(0, e - 1440);
      }
    }

    span(wake, sleep - 60, HsColors.ink);
    span(sleep - 60, sleep, HsColors.sage);
    canvas.drawRect(
      rect.deflate(0.75),
      Paint()
        ..color = HsColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DayBarPainter old) =>
      old.wake != wake || old.sleep != sleep;
}

enum _SwatchKind { ink, sage, hatched }

class _Swatch extends StatelessWidget {
  const _Swatch.ink() : kind = _SwatchKind.ink;
  const _Swatch.sage() : kind = _SwatchKind.sage;
  const _Swatch.hatched() : kind = _SwatchKind.hatched;

  final _SwatchKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 12,
      decoration: BoxDecoration(
        color: switch (kind) {
          _SwatchKind.ink => HsColors.ink,
          _SwatchKind.sage => HsColors.sage,
          _SwatchKind.hatched => HsColors.label,
        },
        border: Border.all(color: HsColors.ink),
      ),
      child: kind == _SwatchKind.hatched
          ? CustomPaint(painter: _DayBarPainter(0, 0))
          : null,
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.text});

  final Widget swatch;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        spacing: 10,
        children: [
          swatch,
          Expanded(child: Text(text, style: HsText.caslon(14))),
        ],
      ),
    );
  }
}
