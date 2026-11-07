// Renders the README screenshots from the real widgets, with the bundled
// fonts and made-up data, so no personal details ever end up in them.
//
//   flutter test tool/screenshots --update-goldens
//
// Images are written to docs/screenshots/. This folder is not part of the
// normal test run.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/data/intake_repository.dart';
import 'package:hydrate_sir/features/onboarding/particulars_screen.dart';
import 'package:hydrate_sir/features/reminder/door_screen.dart';
import 'package:hydrate_sir/services/notifications.dart';

import '../../test/helpers.dart';

const _out = '../../docs/screenshots';

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final f in files) {
      final bytes = File(f).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await family('LibreCaslon', [
    'assets/fonts/libre-caslon-text/LibreCaslonText-VF.ttf',
    'assets/fonts/libre-caslon-text/LibreCaslonText-Italic-VF.ttf',
  ]);
  await family('CourierPrime', [
    'assets/fonts/courier-prime/CourierPrime-Regular.ttf',
    'assets/fonts/courier-prime/CourierPrime-Bold.ttf',
  ]);
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

/// Saturday 7 November, five past two in the afternoon.
final _now = DateTime(2026, 11, 7, 14, 5);

final _regular = Profile(
  onboarded: true,
  startedAt: DateTime(2026, 10, 20),
  batteryNoteDismissed: true,
);

/// A believable week: Wednesday fell short, the rest were met.
Future<void> _seed(Harness h) async {
  final repo = IntakeRepository(h.db);
  const week = [2750, 3000, 3000, 2000, 3000, 2750];
  for (var d = 0; d < week.length; d++) {
    final glasses = week[d] ~/ 250;
    for (var g = 0; g < glasses; g++) {
      // Between 08:00 and 21:00, well inside the day.
      await repo.add(250, DateTime(2026, 11, 1 + d, 8, g * 65));
    }
  }
  for (var i = 0; i < 5; i++) {
    await repo.add(250, DateTime(2026, 11, 7, 7 + i * 1, 30));
  }
}

Future<Harness> _open(
  WidgetTester tester, {
  Profile? profile,
  bool seed = true,
}) async {
  _phone(tester);
  final h = await Harness.create(profile: profile ?? _regular, now: _now);
  if (seed) await tester.runAsync(() => _seed(h));
  await tester.pumpWidget(h.app());
  await _settle(tester);
  return h;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _shoot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('$_out/$name.png'),
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('welcome', (tester) async {
    final h = await _open(tester, profile: const Profile(), seed: false);
    await _shoot(tester, 'welcome');
    await h.dispose(tester);
  });

  testWidgets('particulars', (tester) async {
    final h = await _open(tester, profile: const Profile(), seed: false);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    // ignore: unawaited_futures
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const ParticularsScreen()),
    );
    await _settle(tester);
    await _shoot(tester, 'particulars');
    await h.dispose(tester);
  });

  testWidgets('today', (tester) async {
    final h = await _open(tester);
    await _shoot(tester, 'today');
    await h.dispose(tester);
  });

  testWidgets('door', (tester) async {
    final h = await _open(tester);
    h.notifications.showing.add(1005);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    // ignore: unawaited_futures
    nav.push(
      MaterialPageRoute<void>(
        builder: (_) => const DoorScreen(
          payload: ReminderPayload(slot: 5, door: true, id: 1005),
        ),
      ),
    );
    await _settle(tester);
    await _shoot(tester, 'door');
    await h.dispose(tester);
  });

  testWidgets('cellar book', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Cellar Book'));
    await _settle(tester);
    await _shoot(tester, 'cellar-book');
    await h.dispose(tester);
  });

  testWidgets('instructions', (tester) async {
    final h = await _open(tester);
    await tester.tap(find.text('Instructions'));
    await _settle(tester);
    await tester.drag(
      find.byType(Scrollable).hitTestable().first,
      const Offset(0, -620),
    );
    await _settle(tester);
    await _shoot(tester, 'instructions');
    await h.dispose(tester);
  });
}
