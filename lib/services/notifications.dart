import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../copy/hargreaves.dart';
import '../core/profile.dart';
import 'reminder_plan.dart';

/// Notification button ids.
abstract final class ReminderAction {
  static const thankYou = 'thank_you';
  static const snooze = 'snooze';
  static const notNow = 'not_now';
}

/// What a reminder carries so a tap or button knows which glass it was.
class ReminderPayload {
  const ReminderPayload({required this.slot, required this.door});

  final int slot;

  /// Shown as a full-screen reminder.
  final bool door;

  String encode() => jsonEncode({'slot': slot, 'door': door});

  static ReminderPayload? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return ReminderPayload(
        slot: j['slot'] is int ? j['slot']! as int : 0,
        door: j['door'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Thin wrapper over the platform notification plugin.
class Notifications {
  Notifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  static bool _tzReady = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  static Future<void> initTimeZones() async {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Unknown zone: fall back to UTC offsets via DateTime.
    }
    _tzReady = true;
  }

  Future<void> init({
    DidReceiveNotificationResponseCallback? onResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) async {
    await initTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_bowtie'),
      ),
      onDidReceiveNotificationResponse: onResponse,
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    for (final c in Channels.all) {
      await _android?.createNotificationChannel(c);
    }
  }

  /// The response that launched the app, if a reminder did.
  Future<NotificationResponse?> launchResponse() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true ? d!.notificationResponse : null;
  }

  Future<bool> enabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  Future<bool> canBePunctual() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  Future<bool> requestPunctuality() async =>
      await _android?.requestExactAlarmsPermission() ?? false;

  Future<bool> requestFullScreen() async =>
      await _android?.requestFullScreenIntentPermission() ?? false;

  /// Replaces every scheduled reminder with a fresh plan. Reminders already
  /// on screen are left alone.
  Future<int> replan({
    required Profile profile,
    required DateTime now,
    required int takenToday,
  }) async {
    await _plugin.cancelAllPendingNotifications();
    if (!profile.onboarded) return 0;
    final exact = await canBePunctual();
    final plan = planReminders(
      profile: profile,
      now: now,
      takenToday: takenToday,
    );
    for (final r in plan) {
      await _schedule(profile, r, exact: exact);
    }
    return plan.length;
  }

  /// "In 15 minutes": one more try, and no follow-up for this glass.
  Future<void> snooze({
    required Profile profile,
    required int slot,
    required DateTime now,
  }) async {
    await cancelFollowUp(slot);
    final h = Hargreaves.of(profile);
    await _schedule(
      profile,
      PlannedReminder(
        id: ReminderIds.snooze,
        at: now.add(const Duration(minutes: followUpDelay)),
        kind: ReminderKind.snooze,
        slot: slot,
        title: h.reminderTitle(profile.glassSizeMl),
        body: 'As promised, ${h.you}. Your glass, once more.',
      ),
      exact: await canBePunctual(),
    );
  }

  Future<void> cancelFollowUp(int slot) =>
      _plugin.cancel(id: ReminderIds.followUp(0, slot));

  Future<void> dismiss(int id) => _plugin.cancel(id: id);

  /// Shows a reminder at once, for trying the styles from Standing
  /// Instructions.
  Future<void> showSample(Profile profile) async {
    final h = Hargreaves.of(profile);
    await _plugin.show(
      id: 9100,
      title: h.reminderTitle(profile.glassSizeMl),
      body: 'A rehearsal, ${h.you}. This is how I shall announce myself.',
      notificationDetails: _details(profile, ReminderKind.glass),
      payload: ReminderPayload(
        slot: 0,
        door: profile.reminderStyle == ReminderStyle.door,
      ).encode(),
    );
  }

  Future<void> _schedule(
    Profile profile,
    PlannedReminder r, {
    required bool exact,
  }) async {
    await _plugin.zonedSchedule(
      id: r.id,
      scheduledDate: tz.TZDateTime.from(r.at, tz.local),
      notificationDetails: _details(profile, r.kind),
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      title: r.title,
      body: r.body,
      payload: ReminderPayload(
        slot: r.slot,
        door:
            profile.reminderStyle == ReminderStyle.door &&
            r.kind != ReminderKind.followUp,
      ).encode(),
    );
  }

  NotificationDetails _details(Profile p, ReminderKind kind) {
    final door =
        p.reminderStyle == ReminderStyle.door && kind != ReminderKind.followUp;
    final channel = Channels.pick(
      door: door,
      chime: p.chime,
      throughSilence: !p.respectSilent,
    );
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: door ? Priority.max : Priority.high,
        playSound: channel.playSound,
        enableVibration: channel.enableVibration,
        audioAttributesUsage: channel.audioAttributesUsage,
        icon: 'ic_stat_bowtie',
        color: const Color(0xFF1F3B2D),
        category: door
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        fullScreenIntent: door,
        visibility: NotificationVisibility.public,
        styleInformation: const DefaultStyleInformation(true, true),
        actions: const [
          AndroidNotificationAction(ReminderAction.thankYou, 'Thank you'),
          AndroidNotificationAction(ReminderAction.snooze, 'In 15 minutes'),
          AndroidNotificationAction(ReminderAction.notNow, 'Not now'),
        ],
      ),
    );
  }
}

/// Notification channels. Sound settings are fixed per channel on Android,
/// so each combination of manners gets its own.
abstract final class Channels {
  static const _desc = "Hargreaves' reminders to take a glass of water";

  static const chime = AndroidNotificationChannel(
    'hargreaves',
    "Hargreaves' reminders",
    description: _desc,
    importance: Importance.high,
  );

  static const chimeThroughSilence = AndroidNotificationChannel(
    'hargreaves_insistent',
    "Hargreaves' reminders (even when silenced)",
    description: _desc,
    importance: Importance.high,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const quiet = AndroidNotificationChannel(
    'hargreaves_quiet',
    "Hargreaves' silent reminders",
    description: _desc,
    importance: Importance.high,
    playSound: false,
    enableVibration: false,
  );

  static const door = AndroidNotificationChannel(
    'hargreaves_door',
    'Hargreaves at the door',
    description: 'Full-screen reminders over the lock screen',
    importance: Importance.max,
    audioAttributesUsage: AudioAttributesUsage.alarm,
  );

  static const all = [chime, chimeThroughSilence, quiet, door];

  @visibleForTesting
  static AndroidNotificationChannel pick({
    required bool door,
    required bool chime,
    required bool throughSilence,
  }) {
    if (!chime) return quiet;
    if (door) return Channels.door;
    return throughSilence ? chimeThroughSilence : Channels.chime;
  }
}

/// Lets a full-screen reminder show over the lock screen, and puts the app
/// away again afterwards.
abstract final class LockScreen {
  static const _channel = MethodChannel('hydrate_sir/lock_screen');

  /// Stop showing over the lock screen and return the user to it.
  static Future<void> release({bool moveToBack = false}) async {
    try {
      await _channel.invokeMethod<void>('release', {'moveToBack': moveToBack});
    } on MissingPluginException {
      // Tests and other platforms.
    }
  }
}
