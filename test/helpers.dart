import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hydrate_sir/app/app.dart';
import 'package:hydrate_sir/app/providers.dart';
import 'package:hydrate_sir/app/reminders.dart';
import 'package:hydrate_sir/core/profile.dart';
import 'package:hydrate_sir/data/database.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:hydrate_sir/features/updates/update_controller.dart';
import 'package:hydrate_sir/services/battery.dart';
import 'package:hydrate_sir/services/updates.dart';
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

  /// Ids of reminders currently in the shade.
  final showing = <int>{};

  @override
  Future<bool> isShowing(int id) async => showing.contains(id);

  @override
  Future<void> dismiss(int id) async => dismissed.add(id);

  final rehearsals = <Duration>[];

  @override
  Future<void> rehearse(
    Profile profile, {
    Duration delay = Duration.zero,
  }) async => rehearsals.add(delay);
}

class FakeBattery extends Battery {
  FakeBattery();

  bool exempt = true;
  int opened = 0;

  @override
  Future<bool> isExempt() async => exempt;

  @override
  Future<void> openSettings() async => opened++;
}

class FakeUpdateService extends UpdateService {
  ReleaseInfo? published;
  bool offline = false;
  bool mayInstall = true;
  bool badChecksum = false;
  int checks = 0;
  int settingsOpened = 0;
  final installs = <(String, String?)>[];

  @override
  Future<AppVersion> installed() async => const AppVersion('1.0.0', 1);

  @override
  Future<ReleaseInfo?> latest() async {
    checks++;
    if (offline) throw const SocketException('offline');
    return published;
  }

  @override
  Future<String?> checksum(Uri url) async => 'a' * 64;

  @override
  Future<String> download(
    ReleaseInfo release,
    void Function(double) onProgress,
  ) async {
    onProgress(0.5);
    onProgress(1);
    return '/cache/${release.version}.apk';
  }

  @override
  Future<bool> canInstall() async => mayInstall;

  @override
  Future<void> openInstallSettings() async => settingsOpened++;

  @override
  Future<void> install(String path, {String? sha256}) async {
    if (badChecksum) {
      throw PlatformException(code: 'checksum', message: 'mismatch');
    }
    installs.add((path, sha256));
  }
}

class Harness {
  Harness._(this.prefs, this.db, this.notifications, this.now);

  final battery = FakeBattery();
  final updates = FakeUpdateService();

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

  /// Unmounts the app. The in-memory database needs no closing, and
  /// closing it inside the fake test clock can wait forever on its I/O.
  Future<void> dispose(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    // Let Drift's stream clean-up timers run.
    await tester.pump(const Duration(seconds: 1));
  }

  Widget app({NotificationResponse? launch}) => ProviderScope(
    overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      databaseProvider.overrideWithValue(db),
      notificationsProvider.overrideWithValue(notifications),
      batteryProvider.overrideWithValue(battery),
      updateServiceProvider.overrideWithValue(updates),
      clockProvider.overrideWithValue(() => now),
      nowProvider.overrideWith((ref) => Stream.value(now)),
    ],
    child: HydrateSirApp(launch: launch),
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
