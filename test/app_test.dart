import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/features/reminder/door_screen.dart';
import 'package:hydrate_sir/services/notifications.dart';
import 'package:hydrate_sir/services/updates.dart';

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
    // Set up at 09:30: the 07:00 and 08:22 glasses are not held against Ada.
    expect(
      find.text('Your next glass at 09:44, Ada. Do carry on.'),
      findsOneWidget,
    );

    await h.dispose(tester);
  });

  testWidgets('logging and undoing a glass on Today', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);

    expect(find.text('0 OF 12\nTAKEN'), findsOneWidget);
    // 09:30: the 07:00 and 08:22 glasses are overdue.
    expect(find.textContaining('two glasses remain untouched'), findsOneWidget);

    await tapText(tester, "I'VE HAD MY GLASS · 250 ml");
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

    await h.dispose(tester);
  });

  testWidgets('blocked notifications are explained on Today', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    h.notifications.allowed = false;
    await tester.pumpWidget(h.app());
    await settle(tester);
    expect(find.textContaining('I am forbidden to knock'), findsOneWidget);
    await h.dispose(tester);
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

    await h.dispose(tester);
  });

  testWidgets('cellar book greets an empty ledger kindly', (tester) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);
    await tapText(tester, 'Cellar Book');
    expect(find.text('The Cellar Book'), findsOneWidget);
    expect(find.textContaining('awaits its first entry'), findsOneWidget);
    await h.dispose(tester);
  });

  testWidgets('door screen: a rehearsal is labelled, and taking it logs', (
    tester,
  ) async {
    usePhone(tester);
    final h = await Harness.create(profile: const Profile(onboarded: true));
    await tester.pumpWidget(h.app());
    await settle(tester);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    unawaited(
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => const DoorScreen(
            payload: ReminderPayload(slot: 0, door: true, rehearsal: true),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('A REHEARSAL · 250 ml'), findsOneWidget);
    expect(find.text('Your 250 ml, sir.'), findsOneWidget);
    expect(find.text('A CURIOSITY'), findsOneWidget);

    await tester.tap(find.text("I'VE HAD MY GLASS"));
    await letDatabaseWork(tester);
    await settle(tester);
    final rows = await tester.runAsync(
      () => h.db.select(h.db.intakeEntries).get(),
    );
    expect(rows, hasLength(1));
    expect(find.byType(DoorScreen), findsNothing);
    await h.dispose(tester);
  });

  group('launched by a full-screen reminder', () {
    NotificationResponse launch(int id) => NotificationResponse(
      notificationResponseType: NotificationResponseType.selectedNotification,
      id: id,
      payload: ReminderPayload(slot: 2, door: true, id: id).encode(),
    );

    testWidgets('opens the door for an unanswered reminder', (tester) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      h.notifications.showing.add(1002);
      await tester.pumpWidget(h.app(launch: launch(1002)));
      await settle(tester);
      expect(find.byType(DoorScreen), findsOneWidget);
      expect(find.text('GLASS 3 OF 12 · 250 ml'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('stays shut once the reminder was answered', (tester) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      await tester.pumpWidget(h.app(launch: launch(1002)));
      await settle(tester);
      expect(find.byType(DoorScreen), findsNothing);
      expect(find.text('TAKEN TODAY'), findsOneWidget);
      await h.dispose(tester);
    });
  });

  group('battery warden', () {
    testWidgets('Today explains and leads to the settings', (tester) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      h.battery.exempt = false;
      await tester.pumpWidget(h.app());
      await settle(tester);
      expect(find.textContaining('battery warden'), findsOneWidget);
      await tapText(tester, 'Show me how');
      expect(find.textContaining('set it to Unrestricted'), findsOneWidget);
      await tapText(tester, 'OPEN THE SETTINGS');
      expect(h.battery.opened, 1);
      await h.dispose(tester);
    });

    testWidgets('never mind puts the note away for good', (tester) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      h.battery.exempt = false;
      await tester.pumpWidget(h.app());
      await settle(tester);
      await tapText(tester, 'Never mind');
      expect(find.textContaining('battery warden who'), findsNothing);
      expect(
        h.prefs.getString('profile.v1'),
        contains('"batteryNoteDismissed":true'),
      );
      await h.dispose(tester);
    });

    testWidgets('no note when the phone already leaves Hargreaves be', (
      tester,
    ) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      await tester.pumpWidget(h.app());
      await settle(tester);
      expect(find.textContaining('battery warden who'), findsNothing);
      await h.dispose(tester);
    });
  });

  group('new editions', () {
    testWidgets('Today announces a new edition found on opening', (
      tester,
    ) async {
      usePhone(tester);
      final h = await Harness.create(profile: const Profile(onboarded: true));
      h.updates.published = ReleaseInfo(
        version: '1.1.0',
        apkUrl: Uri.parse('https://example.test/a.apk'),
        sizeBytes: 1,
      );
      await tester.pumpWidget(h.app());
      await settle(tester);
      expect(find.textContaining('A new edition of myself'), findsOneWidget);
      await tapText(tester, 'Later');
      expect(find.textContaining('A new edition of myself'), findsNothing);
      await h.dispose(tester);
    });

    testWidgets('Instructions can enquire by hand', (tester) async {
      usePhone(tester);
      final h = await Harness.create(
        profile: const Profile(onboarded: true, lookForUpdates: false),
      );
      await tester.pumpWidget(h.app());
      await settle(tester);
      expect(h.updates.checks, 0, reason: 'automatic checks are off');
      await tapText(tester, 'Instructions');
      await tapText(tester, 'Enquire now');
      expect(
        find.text('You have the latest edition, sir: v1.0.0.'),
        findsOneWidget,
      );
      await h.dispose(tester);
    });
  });
}
