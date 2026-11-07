import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/home/home_shell.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/reminder/door_screen.dart';
import '../services/background.dart';
import '../services/notifications.dart';
import 'providers.dart';
import 'reminders.dart';
import 'theme/theme.dart';

class HydrateSirApp extends ConsumerStatefulWidget {
  const HydrateSirApp({
    super.key,
    this.responses = const Stream.empty(),
    this.launch,
  });

  /// Reminder taps while the app is running.
  final Stream<NotificationResponse> responses;

  /// The reminder that launched the app, if any.
  final NotificationResponse? launch;

  @override
  ConsumerState<HydrateSirApp> createState() => _HydrateSirAppState();
}

class _HydrateSirAppState extends ConsumerState<HydrateSirApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<NotificationResponse>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = widget.responses.listen(_onResponse);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.launch != null) _onResponse(widget.launch!);
      ref.read(reminderSyncProvider).schedule();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Glasses may have been logged from a notification meanwhile.
    ref
      ..invalidate(nowProvider)
      ..invalidate(todayEntriesProvider)
      ..invalidate(notificationsEnabledProvider)
      ..invalidate(punctualProvider);
    ref.read(reminderSyncProvider).schedule();
  }

  Future<void> _onResponse(NotificationResponse r) async {
    final payload = ReminderPayload.decode(r.payload);
    if (r.actionId != null) {
      await handleReminderAction(
        response: r,
        store: ref.read(profileStoreProvider),
        repo: ref.read(intakeRepositoryProvider),
        notifications: ref.read(notificationsProvider),
        now: ref.read(clockProvider)(),
      );
      return;
    }
    // Android keeps reporting the reminder that launched the app; only open
    // the door for one that hasn't been answered yet.
    final unanswered =
        payload != null &&
        await ref.read(notificationsProvider).isShowing(payload.id);
    if (unanswered &&
        payload.door &&
        ref.read(profileProvider).onboarded &&
        mounted) {
      await _navigator.currentState?.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => DoorScreen(payload: payload),
        ),
      );
    } else {
      await LockScreen.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider);
    final onboarded = ref.watch(profileProvider.select((p) => p.onboarded));
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Hydrate, Sir',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.light,
      home: onboarded ? const HomeShell() : const WelcomeScreen(),
    );
  }
}
