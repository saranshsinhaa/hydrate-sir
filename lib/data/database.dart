import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// One serving of water the user drank.
class IntakeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amountMl => integer()();
  DateTimeColumn get loggedAt => dateTime()();
}

@DriftDatabase(tables: [IntakeEntries])
class AppDatabase extends _$AppDatabase {
  /// Opens the on-device database. Shared across isolates so notification
  /// actions handled in the background write to the same file safely.
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'hydrate_sir',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
            ),
      );

  @override
  int get schemaVersion => 1;
}
