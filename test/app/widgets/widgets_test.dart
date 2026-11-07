import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/app/theme/theme.dart';
import 'package:hydrate_sir/app/widgets/widgets.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildTheme(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('GlassSlot', () {
    for (final state in GlassState.values) {
      testWidgets('announces time and ${state.name}', (tester) async {
        await tester.pumpWidget(_host(GlassSlot(time: '07:00', state: state)));
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('07:00, ${state.name}'), findsOneWidget);
      });
    }

    testWidgets('overdue shows a mark, not colour alone', (tester) async {
      await tester.pumpWidget(
        _host(const GlassSlot(time: '13:49', state: GlassState.overdue)),
      );
      expect(find.text('!'), findsOneWidget);
    });
  });

  group('ChoiceChips', () {
    testWidgets('reports taps and marks the selected option', (tester) async {
      String? picked;
      await tester.pumpWidget(
        _host(
          ChoiceChips<String>(
            options: const [ChipOption('a', 'Sir'), ChipOption('b', 'Madam')],
            selected: 'a',
            onChanged: (v) => picked = v,
          ),
        ),
      );
      await tester.tap(find.text('MADAM'));
      expect(picked, 'b');

      expect(
        tester.getSemantics(find.text('SIR')),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('wraps into rows when columns is set', (tester) async {
      await tester.pumpWidget(
        _host(
          ChoiceChips<int>(
            options: [
              for (final n in [150, 200, 250, 300]) ChipOption(n, '$n'),
            ],
            selected: 250,
            columns: 2,
            onChanged: (_) {},
          ),
        ),
      );
      final first = tester.getTopLeft(find.text('150'));
      final third = tester.getTopLeft(find.text('250'));
      expect(third.dy, greaterThan(first.dy));
    });
  });

  group('InkStepper', () {
    testWidgets('steps up and down, and disables at limits', (tester) async {
      var v = 70;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => InkStepper(
              value: '$v',
              unit: 'kg',
              semanticName: 'weight',
              onDecrement: () => setState(() => v--),
              onIncrement: v < 71 ? () => setState(() => v++) : null,
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('Increase weight'));
      await tester.pump();
      expect(v, 71);

      await tester.tap(find.bySemanticsLabel('Increase weight'));
      await tester.pump();
      expect(v, 71, reason: 'button is disabled at the limit');

      await tester.tap(find.bySemanticsLabel('Decrease weight'));
      await tester.pump();
      expect(v, 70);
    });
  });

  group('ToggleRow', () {
    testWidgets('whole row toggles and exposes toggled state', (tester) async {
      var on = false;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) => ToggleRow(
              label: 'A chime with each reminder',
              hint: 'A discreet sound',
              value: on,
              onChanged: (v) => setState(() => on = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ToggleRow));
      await tester.pumpAndSettle();
      expect(on, isTrue);
      expect(
        tester.getSemantics(find.byType(ToggleRow)),
        isSemantics(isToggled: true),
      );
    });
  });

  group('Stamp', () {
    testWidgets('is decorative and hidden from screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_host(const Stamp('5 of 12 taken')));
      await tester.pumpAndSettle();
      expect(find.text('5 OF 12 TAKEN'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('TAKEN')), findsNothing);
      handle.dispose();
    });
  });

  group('ProgressRule', () {
    testWidgets('clamps above 100 percent', (tester) async {
      await tester.pumpWidget(_host(const ProgressRule(fraction: 1.4)));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel("100 percent of the day's water taken"),
        findsOneWidget,
      );
    });
  });

  group('InkButton', () {
    testWidgets('typed in capitals and disabled without a callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const InkButton(label: 'Very well, proceed', onPressed: null)),
      );
      expect(find.text('VERY WELL, PROCEED'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(InkButton)),
        isSemantics(isEnabled: false),
      );
    });
  });

  testWidgets('touch targets meet the Android guideline', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        Column(
          children: [
            InkStepper(
              value: '70',
              semanticName: 'weight',
              onDecrement: () {},
              onIncrement: () {},
            ),
            InkLink(text: 'I had a different amount', onTap: () {}),
          ],
        ),
      ),
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });
}
