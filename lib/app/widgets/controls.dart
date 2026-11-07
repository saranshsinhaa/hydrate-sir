import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'surfaces.dart';

/// Primary button: ink fill, typed label, 60 px tall, square (DESIGN.md §5.4).
class InkButton extends StatelessWidget {
  const InkButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? HsColors.ink : HsColors.rule,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            height: 60,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: HsText.button.copyWith(
                color: enabled ? HsColors.label : HsColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square outline button holding an icon or short text.
class InkOutlineButton extends StatelessWidget {
  const InkOutlineButton({
    super.key,
    required this.child,
    required this.semanticLabel,
    required this.onPressed,
    this.size = 60,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        onLongPressStart: onLongPressStart == null
            ? null
            : (_) => onLongPressStart!(),
        onLongPressEnd: onLongPressEnd == null
            ? null
            : (_) => onLongPressEnd!(),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: onPressed == null ? HsColors.rule : HsColors.ink,
                  width: HsStroke.interactive,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined Caslon italic link ("I had a different amount").
class InkLink extends StatelessWidget {
  const InkLink({
    super.key,
    required this.text,
    required this.onTap,
    this.destructive = false,
  });

  /// A destructive link uses the stamp colour and typed capitals
  /// ("BURN THE CELLAR BOOK").
  const InkLink.destructive({
    super.key,
    required this.text,
    required this.onTap,
  }) : destructive = true;

  final String text;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final style = destructive
        ? HsText.courier(13, bold: true, tracking: 0.04, color: HsColors.stamp)
        : HsText.caslon(15, italic: true);
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: HsSpace.target),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              widthFactor: 1,
              child: Text(
                destructive ? text.toUpperCase() : text,
                textAlign: TextAlign.center,
                style: style.copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: style.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One option for [ChoiceChips].
class ChipOption<T> {
  const ChipOption(this.value, this.label, {this.semanticLabel});

  final T value;
  final String label;
  final String? semanticLabel;
}

/// Equal-width square option chips (DESIGN.md §5.5).
class ChoiceChips<T> extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.columns,
    this.height = 48,
  });

  final List<ChipOption<T>> options;
  final T? selected;
  final ValueChanged<T> onChanged;

  /// Defaults to one row holding every option.
  final int? columns;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cols = columns ?? options.length;
    final rows = <Widget>[];
    for (var i = 0; i < options.length; i += cols) {
      final slice = options.sublist(i, (i + cols).clamp(0, options.length));
      rows.add(
        Row(
          children: [
            for (var j = 0; j < cols; j++) ...[
              if (j > 0) const SizedBox(width: 6),
              Expanded(
                child: j < slice.length ? _chip(slice[j]) : const SizedBox(),
              ),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: rows,
    );
  }

  Widget _chip(ChipOption<T> o) {
    final on = o.value == selected;
    return Semantics(
      button: true,
      selected: on,
      inMutuallyExclusiveGroup: true,
      label: o.semanticLabel,
      child: Material(
        color: on ? HsColors.ink : Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(o.value);
          },
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: HsColors.ink,
                width: HsStroke.interactive,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                o.label.toUpperCase(),
                style: HsText.chip.copyWith(
                  color: on ? HsColors.label : HsColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Value with − and + buttons; holding a button repeats (DESIGN.md §5.6).
class InkStepper extends StatelessWidget {
  const InkStepper({
    super.key,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.semanticName,
    this.unit,
    this.valueStyle,
    this.label,
  });

  /// Already formatted, e.g. "70" or "07:00".
  final String value;
  final String? unit;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  /// Used in button labels: "Decrease weight".
  final String semanticName;
  final TextStyle? valueStyle;

  /// Optional Caslon label above the value.
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: semanticName,
            value: unit == null ? value : '$value $unit',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                if (label != null) Text(label!, style: HsText.body),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: value),
                      if (unit != null)
                        TextSpan(text: ' $unit', style: HsText.unit),
                    ],
                  ),
                  style: valueStyle ?? HsText.numberL,
                ),
              ],
            ),
          ),
        ),
        _RepeatButton(
          symbol: '−',
          semanticLabel: 'Decrease $semanticName',
          onStep: onDecrement,
        ),
        const SizedBox(width: 8),
        _RepeatButton(
          symbol: '+',
          semanticLabel: 'Increase $semanticName',
          onStep: onIncrement,
        ),
      ],
    );
  }
}

class _RepeatButton extends StatefulWidget {
  const _RepeatButton({
    required this.symbol,
    required this.semanticLabel,
    required this.onStep,
  });

  final String symbol;
  final String semanticLabel;
  final VoidCallback? onStep;

  @override
  State<_RepeatButton> createState() => _RepeatButtonState();
}

class _RepeatButtonState extends State<_RepeatButton> {
  Timer? _timer;

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (widget.onStep == null) return _stop();
      widget.onStep!();
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkOutlineButton(
      size: HsSpace.target,
      semanticLabel: widget.semanticLabel,
      onPressed: widget.onStep == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onStep!();
            },
      onLongPressStart: widget.onStep == null ? null : _start,
      onLongPressEnd: _stop,
      child: Text(
        widget.symbol,
        style: HsText.caslon(
          24,
          color: widget.onStep == null ? HsColors.rule : HsColors.ink,
        ),
      ),
    );
  }
}

/// Pill toggle (DESIGN.md §5.7).
class InkSwitch extends StatelessWidget {
  const InkSwitch({super.key, required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final d = hsMotion(context, const Duration(milliseconds: 150));
    return AnimatedContainer(
      duration: d,
      width: 46,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? HsColors.ink : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: HsColors.ink, width: HsStroke.interactive),
      ),
      child: AnimatedAlign(
        duration: d,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value ? HsColors.label : HsColors.ink,
          ),
        ),
      ),
    );
  }
}

/// A full-width tappable row with a label, hint and [InkSwitch].
class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: label,
      hint: hint,
      excludeSemantics: true,
      onTap: () => onChanged(!value),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!value);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(label, style: HsText.body),
                      if (hint != null) Text(hint!, style: HsText.small),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkSwitch(value: value),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings row: label left, typed value right, chevron (DESIGN.md §5.8).
class InstructionRow extends StatelessWidget {
  const InstructionRow({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: label,
      value: value,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: HsSpace.target),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: HsColors.rule)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(child: Text(label, style: HsText.body)),
              Text(value, style: HsText.courier(15)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Text('›', style: HsText.courier(18)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Text-only bottom navigation (DESIGN.md §5.9).
class LedgerTabs extends StatelessWidget {
  const LedgerTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onSelect,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: HsColors.paper,
        border: Border(top: BorderSide(color: HsColors.ink)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: i == index,
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: SizedBox(
                      height: 56,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: i == index
                              ? HsText.caslon(
                                  15,
                                  weight: FontWeight.w700,
                                ).copyWith(
                                  decoration: TextDecoration.underline,
                                  decorationColor: HsColors.ink,
                                )
                              : HsText.caslon(15, italic: true),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Joined square segments ("WEEK | MONTH").
class InkSegments<T> extends StatelessWidget {
  const InkSegments({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<ChipOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: HsColors.ink, width: HsStroke.interactive),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final o in options)
            Semantics(
              button: true,
              selected: o.value == selected,
              child: Material(
                color: o.value == selected ? HsColors.ink : Colors.transparent,
                child: InkWell(
                  onTap: () => onChanged(o.value),
                  child: Container(
                    height: 40,
                    constraints: const BoxConstraints(minWidth: 72),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      o.label.toUpperCase(),
                      style: HsText.chip.copyWith(
                        color: o.value == selected
                            ? HsColors.label
                            : HsColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
