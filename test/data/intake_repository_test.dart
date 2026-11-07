import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrate_sir/data/database.dart';
import 'package:hydrate_sir/data/intake_repository.dart';

void main() {
  late AppDatabase db;
  late IntakeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = IntakeRepository(db);
  });

  tearDown(() => db.close());

  final start = DateTime(2026, 11, 7, 4);
  final end = DateTime(2026, 11, 8, 4);

  test('totals only count entries inside the day', () async {
    await repo.add(250, DateTime(2026, 11, 7, 3, 59)); // previous day
    await repo.add(250, DateTime(2026, 11, 7, 8));
    await repo.add(500, DateTime(2026, 11, 8, 0, 30)); // late, same day
    await repo.add(250, DateTime(2026, 11, 8, 4)); // next day
    expect(await repo.totalBetween(start, end), 750);
  });

  test('undo removes only the latest entry of the day', () async {
    await repo.add(250, DateTime(2026, 11, 7, 8));
    await repo.add(500, DateTime(2026, 11, 7, 9));
    await repo.add(250, DateTime(2026, 11, 8, 9)); // tomorrow, untouched
    expect(await repo.undoLast(start, end), isTrue);
    expect(await repo.totalBetween(start, end), 250);
    expect(await repo.undoLast(start, end), isTrue);
    expect(await repo.undoLast(start, end), isFalse);
    expect(await repo.totalBetween(end, end.add(const Duration(days: 1))), 250);
  });

  test(
    'daily totals group by household day, with empty days as zero',
    () async {
      await repo.add(250, DateTime(2026, 11, 7, 8));
      await repo.add(250, DateTime(2026, 11, 8, 1)); // counts for 7 Nov
      await repo.add(300, DateTime(2026, 11, 9, 12));
      final totals = await repo
          .watchDailyTotals(
            firstDay: DateTime(2026, 11, 6),
            days: 4,
            boundaryMinutes: 240,
          )
          .first;
      expect(totals, {
        DateTime(2026, 11, 6): 0,
        DateTime(2026, 11, 7): 500,
        DateTime(2026, 11, 8): 0,
        DateTime(2026, 11, 9): 300,
      });
    },
  );

  test('erase burns every record', () async {
    await repo.add(250, DateTime(2026, 11, 7, 8));
    await repo.eraseAll();
    expect(await repo.totalBetween(start, end), 0);
  });
}
