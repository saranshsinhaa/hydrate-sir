import 'package:flutter/material.dart';

import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/text.dart';

/// Amounts offered for "I had a different amount" (DESIGN.md §6).
const presetAmounts = [150, 250, 330, 500, 750];

/// Asks how much the user drank. Returns millilitres, or null if dismissed.
Future<int?> showAmountSheet(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AmountSheet(),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet();

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  int? _preset;
  final _custom = TextEditingController();

  int? get _amount {
    final typed = int.tryParse(_custom.text.trim());
    if (typed != null) return typed > 0 && typed <= 3000 ? typed : null;
    return _preset;
  }

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        HsSpace.side,
        22,
        HsSpace.side,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            Text(TodayText.sheetTitle, style: HsText.h2),
            ChoiceChips<int>(
              options: [
                for (final a in presetAmounts)
                  ChipOption(a, '$a', semanticLabel: '$a millilitres'),
              ],
              selected: _custom.text.isEmpty ? _preset : null,
              onChanged: (v) => setState(() {
                _preset = v;
                _custom.clear();
              }),
            ),
            TextField(
              controller: _custom,
              keyboardType: TextInputType.number,
              style: HsText.courier(18, bold: true),
              decoration: const InputDecoration(
                hintText: TodayText.custom,
                suffixText: 'ml',
              ),
              onChanged: (_) => setState(() {}),
            ),
            InkButton(
              label: _amount == null
                  ? TodayText.record
                  : '${TodayText.record} · $_amount ml',
              onPressed: _amount == null
                  ? null
                  : () => Navigator.of(context).pop(_amount),
            ),
          ],
        ),
      ),
    );
  }
}
