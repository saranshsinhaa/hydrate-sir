// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $IntakeEntriesTable extends IntakeEntries
    with TableInfo<$IntakeEntriesTable, IntakeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IntakeEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  @override
  late final GeneratedColumn<DateTime> loggedAt = GeneratedColumn<DateTime>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, amountMl, loggedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'intake_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<IntakeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMlMeta);
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IntakeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IntakeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      )!,
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}logged_at'],
      )!,
    );
  }

  @override
  $IntakeEntriesTable createAlias(String alias) {
    return $IntakeEntriesTable(attachedDatabase, alias);
  }
}

class IntakeEntry extends DataClass implements Insertable<IntakeEntry> {
  final int id;
  final int amountMl;
  final DateTime loggedAt;
  const IntakeEntry({
    required this.id,
    required this.amountMl,
    required this.loggedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount_ml'] = Variable<int>(amountMl);
    map['logged_at'] = Variable<DateTime>(loggedAt);
    return map;
  }

  IntakeEntriesCompanion toCompanion(bool nullToAbsent) {
    return IntakeEntriesCompanion(
      id: Value(id),
      amountMl: Value(amountMl),
      loggedAt: Value(loggedAt),
    );
  }

  factory IntakeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IntakeEntry(
      id: serializer.fromJson<int>(json['id']),
      amountMl: serializer.fromJson<int>(json['amountMl']),
      loggedAt: serializer.fromJson<DateTime>(json['loggedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amountMl': serializer.toJson<int>(amountMl),
      'loggedAt': serializer.toJson<DateTime>(loggedAt),
    };
  }

  IntakeEntry copyWith({int? id, int? amountMl, DateTime? loggedAt}) =>
      IntakeEntry(
        id: id ?? this.id,
        amountMl: amountMl ?? this.amountMl,
        loggedAt: loggedAt ?? this.loggedAt,
      );
  IntakeEntry copyWithCompanion(IntakeEntriesCompanion data) {
    return IntakeEntry(
      id: data.id.present ? data.id.value : this.id,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      loggedAt: data.loggedAt.present ? data.loggedAt.value : this.loggedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IntakeEntry(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amountMl, loggedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IntakeEntry &&
          other.id == this.id &&
          other.amountMl == this.amountMl &&
          other.loggedAt == this.loggedAt);
}

class IntakeEntriesCompanion extends UpdateCompanion<IntakeEntry> {
  final Value<int> id;
  final Value<int> amountMl;
  final Value<DateTime> loggedAt;
  const IntakeEntriesCompanion({
    this.id = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.loggedAt = const Value.absent(),
  });
  IntakeEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int amountMl,
    required DateTime loggedAt,
  }) : amountMl = Value(amountMl),
       loggedAt = Value(loggedAt);
  static Insertable<IntakeEntry> custom({
    Expression<int>? id,
    Expression<int>? amountMl,
    Expression<DateTime>? loggedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amountMl != null) 'amount_ml': amountMl,
      if (loggedAt != null) 'logged_at': loggedAt,
    });
  }

  IntakeEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? amountMl,
    Value<DateTime>? loggedAt,
  }) {
    return IntakeEntriesCompanion(
      id: id ?? this.id,
      amountMl: amountMl ?? this.amountMl,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<DateTime>(loggedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IntakeEntriesCompanion(')
          ..write('id: $id, ')
          ..write('amountMl: $amountMl, ')
          ..write('loggedAt: $loggedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $IntakeEntriesTable intakeEntries = $IntakeEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [intakeEntries];
}

typedef $$IntakeEntriesTableCreateCompanionBuilder =
    IntakeEntriesCompanion Function({
      Value<int> id,
      required int amountMl,
      required DateTime loggedAt,
    });
typedef $$IntakeEntriesTableUpdateCompanionBuilder =
    IntakeEntriesCompanion Function({
      Value<int> id,
      Value<int> amountMl,
      Value<DateTime> loggedAt,
    });

class $$IntakeEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$IntakeEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$IntakeEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IntakeEntriesTable> {
  $$IntakeEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);
}

class $$IntakeEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IntakeEntriesTable,
          IntakeEntry,
          $$IntakeEntriesTableFilterComposer,
          $$IntakeEntriesTableOrderingComposer,
          $$IntakeEntriesTableAnnotationComposer,
          $$IntakeEntriesTableCreateCompanionBuilder,
          $$IntakeEntriesTableUpdateCompanionBuilder,
          (
            IntakeEntry,
            BaseReferences<_$AppDatabase, $IntakeEntriesTable, IntakeEntry>,
          ),
          IntakeEntry,
          PrefetchHooks Function()
        > {
  $$IntakeEntriesTableTableManager(_$AppDatabase db, $IntakeEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IntakeEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IntakeEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IntakeEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> amountMl = const Value.absent(),
                Value<DateTime> loggedAt = const Value.absent(),
              }) => IntakeEntriesCompanion(
                id: id,
                amountMl: amountMl,
                loggedAt: loggedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int amountMl,
                required DateTime loggedAt,
              }) => IntakeEntriesCompanion.insert(
                id: id,
                amountMl: amountMl,
                loggedAt: loggedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IntakeEntriesTable, IntakeEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $IntakeEntriesTable,
                    IntakeEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$IntakeEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IntakeEntriesTable,
      IntakeEntry,
      $$IntakeEntriesTableFilterComposer,
      $$IntakeEntriesTableOrderingComposer,
      $$IntakeEntriesTableAnnotationComposer,
      $$IntakeEntriesTableCreateCompanionBuilder,
      $$IntakeEntriesTableUpdateCompanionBuilder,
      (
        IntakeEntry,
        BaseReferences<_$AppDatabase, $IntakeEntriesTable, IntakeEntry>,
      ),
      IntakeEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$IntakeEntriesTableTableManager get intakeEntries =>
      $$IntakeEntriesTableTableManager(_db, _db.intakeEntries);
}
