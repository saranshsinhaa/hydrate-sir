import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/profile.dart';

import 'helpers.dart';

/// The design's reference phone: 390 × 844.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

Future<void> tapText(WidgetTester tester, String text) =>
    tapFinder(tester, find.text(text));

Future<void> tapFinder(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).hitTestable().first,
    );
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await settle(tester);
}

/// Drift runs real I/O; give it a moment outside the fake clock.
Future<void> letDatabaseWork(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('first visit: particulars to arrangements to Today', (
    tester,
  ) async {
    usePhone(tester);
    final h = await Harness.create();
    await tester.pumpWidget(h.app());
    await settle(tester);

    expect(find.text('VERY WELL, PROCEED'), findsOneWidget);
    await tapText(tester, 'VERY WELL, PROCEED');

    // A Few Particulars: the estimate follows the answers.
    expect(find.text('2 800 ml'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Increase weight'));
    await settle(tester);
    expect(find.text('2 850 ml'), findsOneWidget);

    // By name needs a name before continuing.
    await tapText(tester, 'BY NAME');
    await tester.enterText(find.byType(TextField), 'Ada');
    await settle(tester);
    expect(find.text('If I may be so bold, Ada.'), findsOneWidget);
    await tapText(tester, 'CONTINUE');

    // Your Hours.
    expect(find.text('Your Hours'), findsOneWidget);
    await tapText(tester, 'CONTINUE');

    // The Arrangements: amending the amount stamps it.
    expect(find.text('The Arrangements'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Increase daily amount'));
    await settle(tester);
    expect(find.text('AS YOU WISH'), findsOneWidget);
    await tapText(tester, 'THAT WILL DO NICELY');

    // Hargreaves explains before Android asks.
    expect(find.text('One small matter, Ada'), findsOneWidget);
    await tapText(tester, 'VERY WELL');
    expect(h.notifications.permissionRequests, 1);

    // Today.
    expect(find.text('Good morning, Ada.'), findsOneWidget);
    expect(find.text('TAKEN TODAY'), findsOneWidget);
    expect(h.prefs.getString('profile.v1'), contains('"onboarded":true'));
    expect(h.prefs.getString('profile.v1'), contains('"dailyGoalMl":2900'));

    await h.db.close();
  });

  testWidgets('logging and undoing a glass on Today', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);

    expect(find.text('0 OF 12\nTAKEN'), findsOneWidget);
    // 09:30: the 07:00 and 08:22 glasses are overdue.
    expect(find.textContaining('two glasses remain untouched'), findsOneWidget);

    await tapText(tester, "I'VE HAD MY GLASS · 250 ML");
    await letDatabaseWork(tester);
    await settle(tester);
    final total = await tester.runAsync(
      () => h.db.select(h.db.intakeEntries).get(),
    );
    expect(total, hasLength(1), reason: 'glass written to the book');
    expect(find.text('1 OF 12\nTAKEN'), findsOneWidget);
    expect(
      find.text('Your 08:22 glass is poured and waiting, sir.'),
      findsOneWidget,
    );

    await tapFinder(tester, find.bySemanticsLabel('Undo the last glass'));
    await letDatabaseWork(tester);
    await settle(tester);
    expect(find.text('0 OF 12\nTAKEN'), findsOneWidget);

    await h.db.close();
  });

  testWidgets('blocked notifications are explained on Today', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    h.notifications.allowed = false;
    await tester.pumpWidget(h.app());
    await settle(tester);
    expect(find.textContaining('I am forbidden to knock'), findsOneWidget);
    await h.db.close();
  });

  testWidgets('standing instructions change manners and reminder style', (
    tester,
  ) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);

    await tapText(tester, 'Instructions');
    expect(find.text('Standing Instructions'), findsOneWidget);

    await tapText(tester, 'AT THE DOOR');
    expect(h.prefs.getString('profile.v1'), contains('"reminderStyle":"door"'));

    await tapText(tester, 'A chime with each reminder');
    expect(h.prefs.getString('profile.v1'), contains('"chime":false'));

    await h.db.close();
  });

  testWidgets('cellar book greets an empty ledger kindly', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);
    await tapText(tester, 'Cellar Book');
    expect(find.text('The Cellar Book'), findsOneWidget);
    expect(find.textContaining('awaits its first entry'), findsOneWidget);
    await h.db.close();
  });
}
