import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../copy/text.dart';
import '../../core/format.dart';
import '../../core/hydration.dart';
import '../../core/profile.dart';
import 'hours_screen.dart';
import 'onboarding_draft.dart';

/// 2 · A Few Particulars (docs/design.md §6).
class ParticularsScreen extends ConsumerWidget {
  const ParticularsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(onboardingDraftProvider);
    final draft = ref.read(onboardingDraftProvider.notifier);
    final h = Hargreaves.of(p);
    final needsName = p.address == Address.name && p.name.trim().isEmpty;

    return PaperPage(
      step: ParticularsText.step,
      onBack: () => Navigator.of(context).maybePop(),
      title: ParticularsText.title,
      voice: 'If I may be so bold, ${h.you}.',
      primaryLabel: CommonText.continueOn,
      onPrimary: needsName
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HoursScreen()),
            ),
      children: [
        const Divider(color: HsColors.ink, thickness: 1, height: 1),
        ParticularsForm(profile: p, onChange: draft.update),
        const SizedBox(height: 16),
        DashedBox(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  ParticularsText.estimate,
                  style: HsText.caslon(15, italic: true),
                ),
              ),
              Text(ml(p.suggestedMl), style: HsText.courier(20, bold: true)),
            ],
          ),
        ),
      ],
    );
  }
}

/// The questions about the user, shared with Standing Instructions.
class ParticularsForm extends StatelessWidget {
  const ParticularsForm({
    super.key,
    required this.profile,
    required this.onChange,
  });

  final Profile profile;
  final void Function(Profile Function(Profile)) onChange;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionBlock(
          question: ParticularsText.address,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              ChoiceChips<Address>(
                options: const [
                  ChipOption(Address.sir, ParticularsText.sir),
                  ChipOption(Address.madam, ParticularsText.madam),
                  ChipOption(Address.name, ParticularsText.byName),
                ],
                selected: p.address,
                onChanged: (v) => onChange((x) => x.copyWith(address: v)),
              ),
              if (p.address == Address.name)
                _NameField(
                  initial: p.name,
                  onChanged: (v) => onChange((x) => x.copyWith(name: v)),
                ),
            ],
          ),
        ),
        QuestionBlock(
          child: InkStepper(
            label: ParticularsText.weight,
            value: '${p.weightKg}',
            unit: 'kg',
            semanticName: 'weight',
            onDecrement: p.weightKg > Profile.minWeight
                ? () => onChange((x) => x.copyWith(weightKg: x.weightKg - 1))
                : null,
            onIncrement: p.weightKg < Profile.maxWeight
                ? () => onChange((x) => x.copyWith(weightKg: x.weightKg + 1))
                : null,
          ),
        ),
        QuestionBlock(
          child: InkStepper(
            label: ParticularsText.age,
            value: '${p.age}',
            unit: 'years',
            semanticName: 'age',
            onDecrement: p.age > Profile.minAge
                ? () => onChange((x) => x.copyWith(age: x.age - 1))
                : null,
            onIncrement: p.age < Profile.maxAge
                ? () => onChange((x) => x.copyWith(age: x.age + 1))
                : null,
          ),
        ),
        QuestionBlock(
          question: ParticularsText.exertion,
          child: ChoiceChips<Exertion>(
            options: const [
              ChipOption(Exertion.leisurely, ParticularsText.leisurely),
              ChipOption(Exertion.moderate, ParticularsText.moderate),
              ChipOption(Exertion.vigorous, ParticularsText.vigorous),
            ],
            selected: p.exertion,
            onChanged: (v) => onChange((x) => x.copyWith(exertion: v)),
          ),
        ),
        QuestionBlock(
          question: ParticularsText.climate,
          child: ChoiceChips<Climate>(
            options: const [
              ChipOption(Climate.temperate, ParticularsText.temperate),
              ChipOption(Climate.warm, ParticularsText.warm),
            ],
            selected: p.climate,
            onChanged: (v) => onChange((x) => x.copyWith(climate: v)),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({required this.initial, required this.onChanged});

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.initial.isEmpty,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      onSubmitted: (_) => FocusScope.of(context).unfocus(),
      maxLength: 24,
      style: HsText.body,
      decoration: const InputDecoration(
        hintText: ParticularsText.nameHint,
        counterText: '',
      ),
      onChanged: widget.onChanged,
    );
  }
}
