import 'package:drift/drift.dart';

import '../core/hydration.dart';
import 'database.dart';

/// The household's record of every glass (The Cellar Book).
class IntakeRepository {
  IntakeRepository(this._db);

  final AppDatabase _db;

  Future<void> add(int amountMl, DateTime at) {
    return _db
        .into(_db.intakeEntries)
        .insert(
          IntakeEntriesCompanion.insert(amountMl: amountMl, loggedAt: at),
        );
  }

  /// Removes the most recent entry in [start, end). Returns false when there
  /// was nothing to undo.
  Future<bool> undoLast(DateTime start, DateTime end) async {
    final last =
        await (_db.select(_db.intakeEntries)
              ..where((e) => e.loggedAt.isBetweenValues(start, _before(end)))
              ..orderBy([(e) => OrderingTerm.desc(e.loggedAt)])
              ..limit(1))
            .getSingleOrNull();
    if (last == null) return false;
    await (_db.delete(
      _db.intakeEntries,
    )..where((e) => e.id.equals(last.id))).go();
    return true;
  }

  Stream<List<IntakeEntry>> watchBetween(DateTime start, DateTime end) {
    return (_db.select(_db.intakeEntries)
          ..where((e) => e.loggedAt.isBetweenValues(start, _before(end)))
          ..orderBy([(e) => OrderingTerm.asc(e.loggedAt)]))
        .watch();
  }

  Future<int> totalBetween(DateTime start, DateTime end) async {
    final rows = await (_db.select(
      _db.intakeEntries,
    )..where((e) => e.loggedAt.isBetweenValues(start, _before(end)))).get();
    return rows.fold<int>(0, (sum, e) => sum + e.amountMl);
  }

  /// Totals per household day from [firstDay] for [days] days.
  Stream<Map<DateTime, int>> watchDailyTotals({
    required DateTime firstDay,
    required int days,
    required int boundaryMinutes,
  }) {
    final start = firstDay.add(Duration(minutes: boundaryMinutes));
    final end = start.add(Duration(days: days));
    return watchBetween(start, end).map((rows) {
      final totals = {
        for (var i = 0; i < days; i++) firstDay.add(Duration(days: i)): 0,
      };
      for (final r in rows) {
        final day = householdDay(r.loggedAt, boundaryMinutes);
        totals[day] = (totals[day] ?? 0) + r.amountMl;
      }
      return totals;
    });
  }

  /// Burns the Cellar Book.
  Future<void> eraseAll() => _db.delete(_db.intakeEntries).go();

  static DateTime _before(DateTime end) =>
      end.subtract(const Duration(microseconds: 1));
}
