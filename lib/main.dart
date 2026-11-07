import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'app/reminders.dart';
import 'services/background.dart';
import 'services/notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final notifications = Notifications();
  final responses = StreamController<NotificationResponse>.broadcast();
  await notifications.init(
    onResponse: responses.add,
    onBackgroundResponse: onBackgroundReminderResponse,
  );
  final launch = await notifications.launchResponse();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        notificationsProvider.overrideWithValue(notifications),
      ],
      child: HydrateSirApp(responses: responses.stream, launch: launch),
    ),
  );
}
