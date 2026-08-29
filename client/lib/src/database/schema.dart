import 'package:drift/drift.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get username => text()();
  BoolColumn get selected => boolean().withDefault(const Constant(false))();
  TextColumn get syncCursor => text().nullable()();
  DateTimeColumn get lastUsedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ActivityRow')
class Activities extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimeBlockRow')
class TimeBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get activityId => text()();
  TextColumn get kind => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  TextColumn get status => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimerSettingsRow')
class TimerSettingsTable extends Table {
  TextColumn get accountId => text()();
  IntColumn get focusMinutes => integer().withDefault(const Constant(25))();
  IntColumn get shortBreakMinutes => integer().withDefault(const Constant(5))();
  IntColumn get longBreakMinutes => integer().withDefault(const Constant(15))();
  IntColumn get roundsBeforeLongBreak =>
      integer().withDefault(const Constant(4))();
  BoolColumn get autoStartBreaks =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get autoStartFocus =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountId};
}

class TimerStates extends Table {
  TextColumn get accountId => text()();
  TextColumn get activityId => text().nullable()();
  TextColumn get kind => text()();
  IntColumn get phaseIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  BoolColumn get paused => boolean().withDefault(const Constant(true))();
  IntColumn get remainingMs => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {accountId};
}
