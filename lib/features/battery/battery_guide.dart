import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../copy/text.dart';

/// Explains battery optimisation and opens the app's settings page.
Future<void> showBatteryGuide(BuildContext context, WidgetRef ref) async {
  final h = Hargreaves.of(ref.read(profileProvider));
  final go = await showHsDialog(
    context,
    title: BatteryText.title,
    body: '${h.batteryExplain}\n\n${BatteryText.steps}',
    confirm: BatteryText.openSettings,
    cancel: BatteryText.neverMind,
  );
  if (go) await ref.read(batteryProvider).openSettings();
}

/// A note on Today while Android may hold reminders back.
class BatteryNote extends ConsumerWidget {
  const BatteryNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final exempt = ref.watch(batteryExemptProvider).value ?? true;
    if (exempt || p.batteryNoteDismissed) return const SizedBox.shrink();
    final h = Hargreaves.of(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DashedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(h.batteryNote, style: HsText.caslon(15, italic: true)),
            Wrap(
              spacing: 16,
              children: [
                InkLink(
                  text: BatteryText.showMe,
                  onTap: () => showBatteryGuide(context, ref),
                ),
                InkLink(
                  text: BatteryText.neverMind,
                  onTap: () => ref
                      .read(profileProvider.notifier)
                      .update((x) => x.copyWith(batteryNoteDismissed: true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The battery row in Standing Instructions.
class BatteryRow extends ConsumerWidget {
  const BatteryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exempt = ref.watch(batteryExemptProvider).value ?? true;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HsColors.rule)),
      ),
      child: InstructionRow(
        label: BatteryText.title,
        value: exempt ? BatteryText.exempt : BatteryText.restricts,
        onTap: () => showBatteryGuide(context, ref),
      ),
    );
  }
}
