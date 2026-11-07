import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../copy/text.dart';
import '../../core/format.dart';
import '../../core/hydration.dart';
import '../../core/profile.dart';
import 'onboarding_draft.dart';

/// 4 · The Arrangements (docs/design.md §6).
class ArrangementsScreen extends ConsumerWidget {
  const ArrangementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(onboardingDraftProvider);
    final draft = ref.read(onboardingDraftProvider.notifier);
    return PaperPage(
      step: ArrangementsText.step,
      onBack: () => Navigator.of(context).maybePop(),
      title: ArrangementsText.title,
      primaryLabel: ArrangementsText.accept,
      onPrimary: () => acceptArrangements(context, ref),
      footer: Text(
        ArrangementsText.disclaimer,
        textAlign: TextAlign.center,
        style: HsText.small,
      ),
      children: [ArrangementsForm(profile: p, onChange: draft.update)],
    );
  }
}

/// Saves the particulars, then asks Android for what reminders need, with
/// Hargreaves explaining each request first.
Future<void> acceptArrangements(BuildContext context, WidgetRef ref) async {
  final profile = ref
      .read(onboardingDraftProvider)
      .copyWith(onboarded: true, startedAt: ref.read(clockProvider)());
  final n = ref.read(notificationsProvider);
  final h = Hargreaves.of(profile);
  final nav = Navigator.of(context);

  await showHsDialog(
    context,
    title: 'One small matter, ${h.you}',
    body:
        'With your leave, I shall send a discreet note whenever a glass is '
        'due. Android will ask whether I may.',
    confirm: 'Very well',
  );
  final allowed = await n.requestPermission();
  if (allowed && !await n.canBePunctual() && context.mounted) {
    final ask = await showHsDialog(
      context,
      title: 'On punctuality',
      body:
          'Android keeps a butler waiting unless told otherwise. Should you '
          'allow me to set alarms and reminders, I shall arrive on the minute.',
      confirm: 'Allow it',
      cancel: 'Never mind',
    );
    if (ask) await n.requestPunctuality();
  }
  await ref.read(profileProvider.notifier).set(profile);
  ref.invalidate(notificationsEnabledProvider);
  ref.invalidate(punctualProvider);
  nav.popUntil((r) => r.isFirst);
}

/// Daily amount, glass size and the resulting timetable. Shared with
/// Standing Instructions.
class ArrangementsForm extends StatelessWidget {
  const ArrangementsForm({
    super.key,
    required this.profile,
    required this.onChange,
  });

  final Profile profile;
  final void Function(Profile Function(Profile)) onChange;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final h = Hargreaves.of(p);
    final goal = p.goalMl;
    int? next(int v) {
      final n = v.clamp(Profile.minGoal, Profile.maxGoal);
      return n == p.suggestedMl ? null : n;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        LabelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Eyebrow(
                      '${p.weightKg} kg · ${p.age} yrs · ${p.exertion.name}',
                    ),
                  ),
                  Eyebrow('${hm(p.wakeMinutes)}–${hm(p.sleepMinutes)}'),
                ],
              ),
              const Divider(color: HsColors.ink, height: 8),
              Text(ArrangementsText.propose, style: HsText.voice),
              InkStepper(
                value: spaced(goal),
                unit: CommonText.millilitres,
                semanticName: 'daily amount',
                valueStyle: HsText.numberXL,
                onDecrement: goal > Profile.minGoal
                    ? () => onChange(
                        (x) => x.copyWith(dailyGoalMl: () => next(goal - 50)),
                      )
                    : null,
                onIncrement: goal < Profile.maxGoal
                    ? () => onChange(
                        (x) => x.copyWith(dailyGoalMl: () => next(goal + 50)),
                      )
                    : null,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      h.amendNote(
                        amended: p.goalAmended,
                        suggestedMl: p.suggestedMl,
                      ),
                      style: HsText.small,
                    ),
                  ),
                  if (p.goalAmended)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Stamp(ArrangementsText.asYouWish, angle: 8),
                    ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(ArrangementsText.glassSize, style: HsText.body),
            ChoiceChips<int>(
              options: [
                for (final s in Profile.glassSizes)
                  ChipOption(s, '$s', semanticLabel: '$s millilitres'),
              ],
              selected: p.glassSizeMl,
              onChanged: (v) => onChange((x) => x.copyWith(glassSizeMl: v)),
            ),
          ],
        ),
        Semantics(
          container: true,
          child: Text(
            'I SHALL BRING ${p.glassCount} GLASSES OF ${p.glassSizeMl} ml, '
            'ROUGHLY EVERY ${gap(p.intervalMinutes).toUpperCase()}, FROM '
            '${hm(p.wakeMinutes)} UNTIL ${hm(p.lastGlassMinutes)}.',
            style: HsText.courier(14, bold: true, tracking: 0.02, height: 1.5),
          ),
        ),
        _Timetable(times: p.glassTimes),
      ],
    );
  }
}

class _Timetable extends StatelessWidget {
  const _Timetable({required this.times});

  final List<int> times;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 4 * 6) / 5;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in times)
              SizedBox(
                width: w,
                child: Text('· ${hm(t)}', style: HsText.courier(14)),
              ),
          ],
        );
      },
    );
  }
}
