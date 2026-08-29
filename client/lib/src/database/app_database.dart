import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../models/domain.dart';
import 'schema.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Accounts,
  Activities,
  TimeBlocks,
  TimerSettingsTable,
  TimerStates,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Colors are visual cues only; activities may intentionally share one.
        },
        onUpgrade: (Migrator m, from, to) async {
          if (from < 2) {
            await customStatement('DROP INDEX IF EXISTS activities_account_active_color');
          }
          if (from < 3) {
            await m.addColumn(accounts, accounts.role);
          }
        },
      );

  Future<void> upsertAccount(AccountsCompanion entry) =>
      into(accounts).insertOnConflictUpdate(entry);

  Future<Account?> selectedAccount() =>
      (select(accounts)..where((row) => row.selected)).getSingleOrNull();

  Future<List<Account>> allAccounts() =>
      (select(accounts)..orderBy([(row) => OrderingTerm.desc(row.lastUsedAt)]))
          .get();

  Future<void> selectAccount(String accountId) => transaction(() async {
        await (update(accounts)..where((row) => row.selected)).write(
          const AccountsCompanion(selected: Value(false)),
        );
        await (update(accounts)..where((row) => row.id.equals(accountId)))
            .write(
          AccountsCompanion(
              selected: const Value(true), lastUsedAt: Value(DateTime.now())),
        );
      });

  Future<void> clearSelectedAccount() => transaction(() async {
        await (update(accounts)..where((row) => row.selected)).write(
          const AccountsCompanion(selected: Value(false)),
        );
      });

  Future<void> setAccountRole(String accountId, String role) async {
    await (update(accounts)..where((row) => row.id.equals(accountId)))
        .write(AccountsCompanion(role: Value(role)));
  }

  Future<String?> firstActiveActivityId(String accountId) async {
    final row = await (select(activities)
          ..where((row) =>
              row.accountId.equals(accountId) &
              row.deleted.equals(false) &
              row.archived.equals(false))
          ..orderBy([(row) => OrderingTerm.asc(row.name)]))
        .getSingleOrNull();
    return row?.id;
  }

  Future<void> upsertActivity(Activity activity) =>
      into(activities).insertOnConflictUpdate(_activityCompanion(activity));

  Future<void> upsertActivities(List<Activity> values) => batch((batch) {
        batch.insertAllOnConflictUpdate(
            activities, values.map(_activityCompanion));
      });

  ActivitiesCompanion _activityCompanion(Activity value) =>
      ActivitiesCompanion.insert(
        id: value.id,
        accountId: value.accountId,
        name: value.name,
        color: value.color,
        archived: Value(value.archived),
        deleted: Value(value.deleted),
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
      );

  Future<void> upsertTimeBlock(TimeBlock value) =>
      into(timeBlocks).insertOnConflictUpdate(_blockCompanion(value));

  Future<void> upsertTimeBlocks(List<TimeBlock> values) => batch((batch) {
        batch.insertAllOnConflictUpdate(
            timeBlocks, values.map(_blockCompanion));
      });

  TimeBlocksCompanion _blockCompanion(TimeBlock value) =>
      TimeBlocksCompanion.insert(
        id: value.id,
        accountId: value.accountId,
        activityId: value.activityId,
        kind: value.kind.name,
        start: value.start,
        end: value.end,
        status: value.status.name,
        deleted: Value(value.deleted),
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
      );

  Future<TimerSettings> settingsFor(String accountId) async {
    final row = await (select(timerSettingsTable)
          ..where((item) => item.accountId.equals(accountId)))
        .getSingleOrNull();
    if (row == null) return TimerSettings.defaults;
    return TimerSettings(
      focusMinutes: row.focusMinutes,
      shortBreakMinutes: row.shortBreakMinutes,
      longBreakMinutes: row.longBreakMinutes,
      roundsBeforeLongBreak: row.roundsBeforeLongBreak,
      autoStartBreaks: row.autoStartBreaks,
      autoStartFocus: row.autoStartFocus,
    );
  }

  Future<void> saveSettings(String accountId, TimerSettings value) async {
    await into(timerSettingsTable).insertOnConflictUpdate(
      TimerSettingsTableCompanion.insert(
        accountId: accountId,
        focusMinutes: Value(value.focusMinutes),
        shortBreakMinutes: Value(value.shortBreakMinutes),
        longBreakMinutes: Value(value.longBreakMinutes),
        roundsBeforeLongBreak: Value(value.roundsBeforeLongBreak),
        autoStartBreaks: Value(value.autoStartBreaks),
        autoStartFocus: Value(value.autoStartFocus),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<PersistedTimerState?> timerState(String accountId) async {
    final row = await (select(timerStates)
          ..where((item) => item.accountId.equals(accountId)))
        .getSingleOrNull();
    if (row == null) return null;
    return PersistedTimerState(
      activityId: row.activityId,
      kind: BlockKind.values.byName(row.kind),
      phaseIndex: row.phaseIndex,
      startedAt: row.startedAt,
      endsAt: row.endsAt,
      paused: row.paused,
      remainingMs: row.remainingMs,
      updatedAt: row.updatedAt,
    );
  }

  Future<void> saveTimerState(
      String accountId, PersistedTimerState state) async {
    await into(timerStates).insertOnConflictUpdate(
      TimerStatesCompanion.insert(
        accountId: accountId,
        activityId: Value(state.activityId),
        kind: state.kind.name,
        phaseIndex: Value(state.phaseIndex),
        startedAt: Value(state.startedAt),
        endsAt: Value(state.endsAt),
        paused: Value(state.paused),
        remainingMs: state.remainingMs,
        updatedAt: state.updatedAt,
      ),
    );
  }

  Future<void> clearTimerState(String accountId) =>
      (delete(timerStates)..where((row) => row.accountId.equals(accountId)))
          .go();

  Future<void> closeDatabase() => close();
}

LazyDatabase _open() =>
    LazyDatabase(() async => NativeDatabase.createInBackground(
          File(_databasePath()),
        ));

String _databasePath() {
  if (Platform.isLinux) {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/.local/share/chronoflow/chronoflow.sqlite';
  }
  return 'chronoflow.sqlite';
}
