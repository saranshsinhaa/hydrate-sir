import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../core/format.dart';
import '../../core/hydration.dart';
import '../../core/profile.dart';
import '../battery/battery_guide.dart';
import '../onboarding/arrangements_screen.dart';
import '../updates/update_widgets.dart';
import '../onboarding/hours_screen.dart';
import '../onboarding/particulars_screen.dart';

/// Set by CI from the release tag.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// 8 · Standing Instructions (docs/design.md §6).
class InstructionsScreen extends ConsumerWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final h = Hargreaves.of(p);
    final punctual = ref.watch(punctualProvider).value ?? false;
    final notifier = ref.read(profileProvider.notifier);

    Future<void> edit(
      Widget Function(Profile, void Function(Profile Function(Profile))) form,
    ) => _editInSheet(context, ref, form);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(HsSpace.side, 26, HsSpace.side, 22),
        children: [
          Semantics(
            header: true,
            child: Text('Standing Instructions', style: HsText.h1),
          ),
          const SizedBox(height: 4),
          Text(
            'Amend anything you please, ${h.you}. I shall adjust accordingly.',
            style: HsText.voice,
          ),
          const _Section('About you'),
          InstructionRow(
            label: 'Address me as',
            value: switch (p.address) {
              Address.sir => 'Sir',
              Address.madam => 'Madam',
              Address.name => h.you,
            },
            onTap: () =>
                edit((d, c) => ParticularsForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'Weight',
            value: '${p.weightKg} kg',
            onTap: () =>
                edit((d, c) => ParticularsForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'Age',
            value: '${p.age} years',
            onTap: () =>
                edit((d, c) => ParticularsForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'Daily exertion',
            value: capitalise(p.exertion.name),
            onTap: () =>
                edit((d, c) => ParticularsForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'Climate',
            value: p.climate == Climate.warm ? 'Rather warm' : 'Temperate',
            onTap: () =>
                edit((d, c) => ParticularsForm(profile: d, onChange: c)),
          ),
          const _Section('Your hours'),
          InstructionRow(
            label: 'You rise at',
            value: hm(p.wakeMinutes),
            onTap: () => edit((d, c) => HoursForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'You retire at',
            value: hm(p.sleepMinutes),
            onTap: () => edit((d, c) => HoursForm(profile: d, onChange: c)),
          ),
          const _Section('The arrangements'),
          InstructionRow(
            label: 'Water each day',
            value: ml(p.goalMl),
            onTap: () =>
                edit((d, c) => ArrangementsForm(profile: d, onChange: c)),
          ),
          InstructionRow(
            label: 'Size of each glass',
            value: '${p.glassSizeMl} ml',
            onTap: () =>
                edit((d, c) => ArrangementsForm(profile: d, onChange: c)),
          ),
          const _Section('Manners'),
          Text('How I announce myself', style: HsText.body),
          const SizedBox(height: 8),
          ChoiceChips<ReminderStyle>(
            options: const [
              ChipOption(ReminderStyle.note, 'A discreet note'),
              ChipOption(ReminderStyle.door, 'At the door'),
            ],
            selected: p.reminderStyle,
            onChanged: (v) async {
              if (v == ReminderStyle.door) {
                await ref.read(notificationsProvider).requestFullScreen();
              }
              await notifier.update((x) => x.copyWith(reminderStyle: v));
            },
          ),
          const SizedBox(height: 6),
          Text(
            p.reminderStyle == ReminderStyle.door
                ? 'I shall present myself in full, even over the locked '
                      'screen, until you answer.'
                : 'A quiet note among your notifications.',
            style: HsText.small,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkLink(
              text: 'Rehearse it now',
              onTap: () => _rehearse(context, ref, p),
            ),
          ),
          ToggleRow(
            label: 'A chime with each reminder',
            hint: 'A discreet sound and a buzz',
            value: p.chime,
            onChanged: (v) => notifier.update((x) => x.copyWith(chime: v)),
          ),
          ToggleRow(
            label: 'Ask again if I am ignored',
            hint: 'Once more, politely, after 15 minutes',
            value: p.askAgain,
            onChanged: (v) => notifier.update((x) => x.copyWith(askAgain: v)),
          ),
          ToggleRow(
            label: 'Respect the silent switch',
            hint: 'I shall not chime when the phone is silenced',
            value: p.respectSilent,
            onChanged: (v) =>
                notifier.update((x) => x.copyWith(respectSilent: v)),
          ),
          const BatteryRow(),
          InstructionRow(
            label: 'Punctuality',
            value: punctual ? 'On the minute' : 'Within a few minutes',
            onTap: punctual
                ? null
                : () async {
                    await ref.read(notificationsProvider).requestPunctuality();
                    ref.invalidate(punctualProvider);
                  },
          ),
          const UpdateHeading(),
          const UpdateSection(),
          const SizedBox(height: 26),
          Center(
            child: InkLink.destructive(
              text: 'Burn the Cellar Book (erase all records)',
              onTap: () async {
                final burn = await showHsDialog(
                  context,
                  title: 'The Cellar Book',
                  body: h.burnQuestion(),
                  confirm: 'Burn it',
                  cancel: 'On second thought',
                  destructive: true,
                );
                if (burn) await ref.read(intakeRepositoryProvider).eraseAll();
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            appVersion == 'dev'
                ? 'Hydrate, Sir · Hargreaves, butler'
                : 'Hydrate, Sir v$appVersion · Hargreaves, butler',
            textAlign: TextAlign.center,
            style: HsText.courier(12),
          ),
        ],
      ),
    );
  }
}

Future<void> _rehearse(BuildContext context, WidgetRef ref, Profile p) async {
  final door = p.reminderStyle == ReminderStyle.door;
  final messenger = ScaffoldMessenger.of(context);
  await ref
      .read(notificationsProvider)
      .rehearse(p, delay: door ? const Duration(seconds: 10) : Duration.zero);
  if (!door) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'I shall knock in ten seconds, ${Hargreaves.of(p).you}. Do lock '
          'the screen to see me as you would.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
}

/// Edits a copy of the profile in a sheet; saves on "Very good".
Future<void> _editInSheet(
  BuildContext context,
  WidgetRef ref,
  Widget Function(Profile, void Function(Profile Function(Profile))) form,
) async {
  final before = ref.read(profileProvider);
  final edited = await showModalBottomSheet<Profile>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditSheet(initial: before, form: form),
  );
  if (edited == null || !context.mounted) return;
  var result = edited;
  final suggestionMoved = edited.suggestedMl != before.suggestedMl;
  if (before.goalAmended && suggestionMoved && edited.goalAmended) {
    final revise = await showHsDialog(
      context,
      title: 'The daily amount',
      body: Hargreaves.of(edited).reviseGoalQuestion(
        suggested: edited.suggestedMl,
        current: edited.goalMl,
      ),
      confirm: 'Revise it to ${ml(edited.suggestedMl)}',
      cancel: 'Keep ${ml(edited.goalMl)}',
    );
    if (revise) result = edited.copyWith(dailyGoalMl: () => null);
  }
  await ref.read(profileProvider.notifier).set(result);
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.initial, required this.form});

  final Profile initial;
  final Widget Function(Profile, void Function(Profile Function(Profile))) form;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late Profile _draft = widget.initial;

  @override
  Widget build(BuildContext context) {
    final needsName =
        _draft.address == Address.name && _draft.name.trim().isEmpty;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scroll) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(
                  HsSpace.side,
                  20,
                  HsSpace.side,
                  12,
                ),
                children: [
                  widget.form(
                    _draft,
                    (change) => setState(() => _draft = change(_draft)),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  HsSpace.side,
                  4,
                  HsSpace.side,
                  12,
                ),
                child: InkButton(
                  label: 'Very good',
                  onPressed: needsName
                      ? null
                      : () => Navigator.of(context).pop(_draft),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: HsColors.ink)),
        ),
        child: Eyebrow(title),
      ),
    );
  }
}
