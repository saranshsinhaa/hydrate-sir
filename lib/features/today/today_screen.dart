import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../battery/battery_guide.dart';
import 'amount_sheet.dart';

/// 5 · Today (DESIGN.md §6).
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final s = ref.watch(dayStatusProvider);
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final day = ref.watch(householdDayProvider);
    final h = Hargreaves.of(p);
    final enabled = ref.watch(notificationsEnabledProvider).value ?? true;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(HsSpace.side, 26, HsSpace.side, 22),
        children: [
          Semantics(
            header: true,
            child: Text(h.salutation(now), style: HsText.h1),
          ),
          const SizedBox(height: 4),
          Eyebrow(eyebrowDate(day)),
          const SizedBox(height: 18),
          if (!enabled) ...[
            _BlockedNote(address: h.you),
            const SizedBox(height: 14),
          ] else
            const BatteryNote(),
          _TodayCard(profile: p, status: s),
          const SizedBox(height: 18),
          Text(h.todayLine(s), style: HsText.voiceLarge),
          const SizedBox(height: 4),
          Text(TodayText.signature, style: HsText.courier(12)),
          const SizedBox(height: 18),
          _GlassGrid(status: s),
          const SizedBox(height: 20),
          Row(
            spacing: 10,
            children: [
              InkOutlineButton(
                semanticLabel: TodayText.undo,
                onPressed: s.totalMl > 0 ? () => _undo(context, ref) : null,
                child: UndoGlyph(
                  color: s.totalMl > 0 ? HsColors.ink : HsColors.rule,
                ),
              ),
              Expanded(
                child: InkButton(
                  caps: false,
                  label: "I'VE HAD MY GLASS · ${p.glassSizeMl} ml",
                  onPressed: () => _log(ref, p.glassSizeMl),
                ),
              ),
            ],
          ),
          Center(
            child: InkLink(
              text: TodayText.differentAmount,
              onTap: () async {
                final amount = await showAmountSheet(context);
                if (amount != null) await _log(ref, amount);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _log(WidgetRef ref, int ml) async {
    await HapticFeedback.lightImpact();
    await ref.read(intakeActionsProvider).log(ml);
  }

  Future<void> _undo(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await ref.read(intakeActionsProvider).undo();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(done ? TodayText.undone : TodayText.nothingToUndo),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.profile, required this.status});

  final Profile profile;
  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return LabelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Expanded(child: Eyebrow(TodayText.atService)),
              Eyebrow(TodayText.hargreaves),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: HsColors.ink),
              ),
            ),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: 'HYDRATE, ',
                    children: [
                      TextSpan(
                        text: 'Sir',
                        style: HsText.caslon(22, italic: true),
                      ),
                    ],
                  ),
                  style: HsText.caslon(22, weight: FontWeight.w700),
                ),
                Text(
                  Hargreaves.regimen(profile.glassSizeMl, s.glassCount),
                  textAlign: TextAlign.center,
                  style: HsText.small,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  label:
                      'Taken today: ${s.totalMl} of ${s.goalMl} millilitres, '
                      '${s.taken} of ${s.glassCount} glasses',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      const Eyebrow(TodayText.takenToday),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: spaced(s.totalMl),
                            children: [
                              TextSpan(
                                text: ' / ${ml(s.goalMl)}',
                                style: HsText.courier(15),
                              ),
                            ],
                          ),
                          style: HsText.bigNumber,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Stamp(
                s.allTaken
                    ? TodayText.allServed
                    : '${s.taken} of ${s.glassCount}\ntaken',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressRule(fraction: s.fraction),
        ],
      ),
    );
  }
}

class _GlassGrid extends StatelessWidget {
  const _GlassGrid({required this.status});

  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    final slots = status.slots;
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 6;
        final w = c.maxWidth / cols;
        return Wrap(
          runSpacing: 12,
          children: [
            for (var i = 0; i < slots.length; i++)
              SizedBox(
                width: w,
                child: GlassSlot(
                  time: hm(status.times[i]),
                  state: switch (slots[i]) {
                    SlotState.taken => GlassState.taken,
                    SlotState.overdue => GlassState.overdue,
                    SlotState.upcoming => GlassState.upcoming,
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Shown when notifications are blocked, with a way to put it right.
class _BlockedNote extends ConsumerWidget {
  const _BlockedNote({required this.address});

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashedBox(
      color: HsColors.stamp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'I am forbidden to knock, $address. Android is withholding my '
            'notes, so I cannot remind you.',
            style: HsText.caslon(15, italic: true),
          ),
          InkLink(
            text: 'Grant me leave',
            onTap: () async {
              await ref.read(notificationsProvider).requestPermission();
              ref.invalidate(notificationsEnabledProvider);
            },
          ),
        ],
      ),
    );
  }
}
