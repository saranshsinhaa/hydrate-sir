import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/profile.dart';
import '../services/notifications.dart';
import 'providers.dart';

final notificationsProvider = Provider<Notifications>((ref) => Notifications());

/// Whether the user allows notifications; refreshed when the app resumes.
final notificationsEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationsProvider).enabled(),
);

/// Whether Android lets reminders arrive on the minute.
final punctualProvider = FutureProvider<bool>(
  (ref) => ref.watch(notificationsProvider).canBePunctual(),
);

/// Keeps scheduled reminders in step with the profile and today's glasses.
/// Watch it once from the app root.
final reminderSyncProvider = Provider<ReminderSync>((ref) {
  final sync = ReminderSync(ref);
  ref.listen<Profile>(profileProvider, (_, _) => sync.schedule());
  ref.listen<int>(todayTotalProvider, (_, _) => sync.schedule());
  ref.onDispose(sync.dispose);
  return sync;
});

class ReminderSync {
  ReminderSync(this._ref);

  final Ref _ref;
  Timer? _debounce;

  /// Replans shortly after a burst of changes settles.
  void schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), replanNow);
  }

  Future<void> replanNow() async {
    final profile = _ref.read(profileProvider);
    final total = _ref.read(todayTotalProvider);
    await _ref
        .read(notificationsProvider)
        .replan(
          profile: profile,
          now: _ref.read(clockProvider)(),
          takenToday: total ~/ profile.glassSizeMl,
        );
  }

  void dispose() => _debounce?.cancel();
}
