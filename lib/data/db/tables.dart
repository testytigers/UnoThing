import 'package:drift/drift.dart';

/// A goal (habit) and its pact. Free members keep one; Pro members up to
/// `maxProGoals`.
@DataClassName('GoalRow')
class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 60)();
  IntColumn get horizonMonths => integer()();
  IntColumn get dailyTargetSeconds => integer()();

  /// Bitmask of active weekdays: bit (weekday - 1), Monday = 1.
  IntColumn get activeWeekdaysMask => integer()();

  /// ISO local date `yyyy-MM-dd`.
  TextColumn get startDate => text()();

  /// Daily reminder, in minutes after local midnight. Null when off.
  IntColumn get reminderMinutes => integer().nullable()();

  /// Order of the Shelf's pages, lowest first.
  IntColumn get position => integer().withDefault(const Constant(0))();
}

/// One row per goal and local calendar date.
@DataClassName('DailyLogRow')
class DailyLogs extends Table {
  IntColumn get goalId => integer()();

  /// ISO local date `yyyy-MM-dd`.
  TextColumn get date => text()();
  IntColumn get totalSeconds => integer()();

  /// [DayStatus] name, stored for convenience; always recomputable.
  TextColumn get status => text()();

  @override
  Set<Column> get primaryKey => {goalId, date};
}

/// The running or paused stopwatch session. At most one row (id = 1): one
/// goal pours at a time.
@DataClassName('ActiveSessionRow')
class ActiveSessions extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get goalId => integer()();
  TextColumn get date => text()();
  IntColumn get baseSeconds => integer()();

  /// UTC epoch milliseconds, null while paused.
  IntColumn get segmentStartedAtMs => integer().nullable()();
  IntColumn get accumulatedSeconds => integer()();
  BoolColumn get safetyNetFired =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get targetFired => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local-only accounts (open decision D3). No server.
@DataClassName('LocalAccountRow')
class LocalAccounts extends Table {
  TextColumn get email => text()();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();

  @override
  Set<Column> get primaryKey => {email};
}

/// Small app-wide settings as key/value text (reminder switches, the Shelf's
/// last page, the Pro preview).
@DataClassName('PreferenceRow')
class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
