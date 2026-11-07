import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/hydration.dart';
import '../data/database.dart';
import '../data/intake_repository.dart';
import '../data/profile_store.dart';
import 'notifications.dart';

/// Handles reminder buttons pressed without opening the app. Runs in its own
/// isolate, so it opens its own handles to preferences and the database.
@pragma('vm:entry-point')
Future<void> onBackgroundReminderResponse(NotificationResponse r) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final db = AppDatabase();
  try {
    await handleReminderAction(
      response: r,
      store: ProfileStore(prefs),
      repo: IntakeRepository(db),
      notifications: Notifications(),
      now: DateTime.now(),
    );
  } finally {
    await db.close();
  }
}

/// Shared by the background handler and the running app.
Future<void> handleReminderAction({
  required NotificationResponse response,
  required ProfileStore store,
  required IntakeRepository repo,
  required Notifications notifications,
  required DateTime now,
}) async {
  await Notifications.initTimeZones();
  final profile = store.load();
  final slot = ReminderPayload.decode(response.payload)?.slot ?? 0;
  switch (response.actionId) {
    case ReminderAction.thankYou:
      await repo.add(profile.glassSizeMl, now);
      final (start, end) = householdDayRange(now, profile.dayBoundaryMinutes);
      final total = await repo.totalBetween(start, end);
      await notifications.replan(
        profile: profile,
        now: now,
        takenToday: total ~/ profile.glassSizeMl,
      );
    case ReminderAction.snooze:
      await notifications.snooze(profile: profile, slot: slot, now: now);
    case ReminderAction.notNow:
      await notifications.cancelFollowUp(slot);
  }
}
