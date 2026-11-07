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
  // Reminders must never keep the household from opening: if Android
  // refuses something here, carry on and log it.
  NotificationResponse? launch;
  try {
    await notifications.init(
      onResponse: responses.add,
      onBackgroundResponse: onBackgroundReminderResponse,
    );
    launch = await notifications.launchResponse();
  } catch (e, s) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'hydrate_sir',
        context: ErrorDescription('while setting up reminders'),
      ),
    );
  }

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
