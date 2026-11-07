import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/hydration.dart';
import '../core/profile.dart';
import '../data/database.dart';
import '../data/intake_repository.dart';
import '../data/profile_store.dart';

/// Overridden in `main()` once preferences are loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final intakeRepositoryProvider = Provider<IntakeRepository>(
  (ref) => IntakeRepository(ref.watch(databaseProvider)),
);

final profileStoreProvider = Provider<ProfileStore>(
  (ref) => ProfileStore(ref.watch(sharedPrefsProvider)),
);

/// Injectable clock so tests control time.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// The current time, refreshed every 20 seconds so glasses turn overdue
/// without user action.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock();
  yield* Stream.periodic(const Duration(seconds: 20), (_) => clock());
});

DateTime _now(Ref ref) =>
    ref.watch(nowProvider).value ?? ref.read(clockProvider)();

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() => ref.watch(profileStoreProvider).load();

  Future<void> set(Profile p) async {
    state = p;
    await ref.read(profileStoreProvider).save(p);
  }

  Future<void> update(Profile Function(Profile) change) => set(change(state));
}

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(
  ProfileNotifier.new,
);

/// The household day currently in progress.
final householdDayProvider = Provider<DateTime>((ref) {
  final boundary = ref.watch(
    profileProvider.select((p) => p.dayBoundaryMinutes),
  );
  return householdDay(_now(ref), boundary);
});

final todayEntriesProvider = StreamProvider<List<IntakeEntry>>((ref) {
  final boundary = ref.watch(
    profileProvider.select((p) => p.dayBoundaryMinutes),
  );
  final day = ref.watch(householdDayProvider);
  final start = day.add(Duration(minutes: boundary));
  return ref
      .watch(intakeRepositoryProvider)
      .watchBetween(start, start.add(const Duration(days: 1)));
});

final todayTotalProvider = Provider<int>((ref) {
  final entries = ref.watch(todayEntriesProvider).value ?? const [];
  return entries.fold(0, (sum, e) => sum + e.amountMl);
});

final dayStatusProvider = Provider<DayStatus>((ref) {
  final p = ref.watch(profileProvider);
  final start = p.startedAt;
  final startedToday =
      start != null &&
      householdDay(start, p.dayBoundaryMinutes) ==
          ref.watch(householdDayProvider);
  return DayStatus(
    times: p.glassTimes,
    totalMl: ref.watch(todayTotalProvider),
    goalMl: p.goalMl,
    glassSizeMl: p.glassSizeMl,
    nowMinutes: householdMinutes(_now(ref), p.dayBoundaryMinutes),
    sleepMinutes: p.sleepMinutes,
    startMinutes: startedToday
        ? householdMinutes(start, p.dayBoundaryMinutes)
        : 0,
  );
});

/// Logging and undoing glasses from the UI.
class IntakeActions {
  IntakeActions(this._ref);

  final Ref _ref;

  Future<void> log(int amountMl) async {
    final now = _ref.read(clockProvider)();
    await _ref.read(intakeRepositoryProvider).add(amountMl, now);
  }

  Future<bool> undo() {
    final boundary = _ref.read(profileProvider).dayBoundaryMinutes;
    final (start, end) = householdDayRange(
      _ref.read(clockProvider)(),
      boundary,
    );
    return _ref.read(intakeRepositoryProvider).undoLast(start, end);
  }
}

final intakeActionsProvider = Provider<IntakeActions>(IntakeActions.new);
