import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydrate_sir/app/app.dart';
import 'package:hydrate_sir/app/providers.dart';
import 'package:hydrate_sir/app/reminders.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/data/database.dart';
import 'package:hydrate_sir/services/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the app asked of Android instead of calling it.
class FakeNotifications extends Notifications {
  final replans = <({Profile profile, int takenToday})>[];
  final snoozed = <int>[];
  bool allowed = true;
  bool punctual = true;
  int permissionRequests = 0;

  @override
  Future<bool> enabled() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<bool> canBePunctual() async => punctual;

  @override
  Future<bool> requestPunctuality() async => punctual = true;

  @override
  Future<bool> requestFullScreen() async => true;

  @override
  Future<int> replan({
    required Profile profile,
    required DateTime now,
    required int takenToday,
  }) async {
    replans.add((profile: profile, takenToday: takenToday));
    return 0;
  }

  @override
  Future<void> snooze({
    required Profile profile,
    required int slot,
    required DateTime now,
  }) async => snoozed.add(slot);

  @override
  Future<void> cancelFollowUp(int slot) async {}

  final dismissed = <int>[];

  @override
  Future<void> dismiss(int id) async => dismissed.add(id);

  final rehearsals = <Duration>[];

  @override
  Future<void> rehearse(
    Profile profile, {
    Duration delay = Duration.zero,
  }) async => rehearsals.add(delay);
}

class Harness {
  Harness._(this.prefs, this.db, this.notifications, this.now);

  final SharedPreferences prefs;
  final AppDatabase db;
  final FakeNotifications notifications;
  DateTime now;

  static Future<Harness> create({Profile? profile, DateTime? now}) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString('profile.v1', _encode(profile));
    }
    return Harness._(
      prefs,
      AppDatabase(NativeDatabase.memory()),
      FakeNotifications(),
      now ?? DateTime(2026, 11, 7, 9, 30),
    );
  }

  Widget app() => ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationsProvider.overrideWithValue(notifications),
      clockProvider.overrideWithValue(() => now),
      nowProvider.overrideWith((ref) => Stream.value(now)),
    ],
    child: const HydrateSirApp(),
  );
}

String _encode(Profile p) {
  final j = p.toJson();
  final parts = j.entries.map((e) {
    final v = e.value;
    final s = v == null
        ? 'null'
        : v is String
        ? '"$v"'
        : '$v';
    return '"${e.key}":$s';
  });
  return '{${parts.join(',')}}';
}
