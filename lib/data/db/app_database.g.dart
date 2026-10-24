// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horizonMonthsMeta = const VerificationMeta(
    'horizonMonths',
  );
  @override
  late final GeneratedColumn<int> horizonMonths = GeneratedColumn<int>(
    'horizon_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyTargetSecondsMeta =
      const VerificationMeta('dailyTargetSeconds');
  @override
  late final GeneratedColumn<int> dailyTargetSeconds = GeneratedColumn<int>(
    'daily_target_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeWeekdaysMaskMeta =
      const VerificationMeta('activeWeekdaysMask');
  @override
  late final GeneratedColumn<int> activeWeekdaysMask = GeneratedColumn<int>(
    'active_weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    horizonMonths,
    dailyTargetSeconds,
    activeWeekdaysMask,
    startDate,
    reminderMinutes,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('horizon_months')) {
      context.handle(
        _horizonMonthsMeta,
        horizonMonths.isAcceptableOrUnknown(
          data['horizon_months']!,
          _horizonMonthsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_horizonMonthsMeta);
    }
    if (data.containsKey('daily_target_seconds')) {
      context.handle(
        _dailyTargetSecondsMeta,
        dailyTargetSeconds.isAcceptableOrUnknown(
          data['daily_target_seconds']!,
          _dailyTargetSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyTargetSecondsMeta);
    }
    if (data.containsKey('active_weekdays_mask')) {
      context.handle(
        _activeWeekdaysMaskMeta,
        activeWeekdaysMask.isAcceptableOrUnknown(
          data['active_weekdays_mask']!,
          _activeWeekdaysMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activeWeekdaysMaskMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      horizonMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}horizon_months'],
      )!,
      dailyTargetSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_target_seconds'],
      )!,
      activeWeekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_weekdays_mask'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final int id;
  final String title;
  final int horizonMonths;
  final int dailyTargetSeconds;

  /// Bitmask of active weekdays: bit (weekday - 1), Monday = 1.
  final int activeWeekdaysMask;

  /// ISO local date `yyyy-MM-dd`.
  final String startDate;

  /// Daily reminder, in minutes after local midnight. Null when off.
  final int? reminderMinutes;

  /// Order of the Shelf's pages, lowest first.
  final int position;
  const GoalRow({
    required this.id,
    required this.title,
    required this.horizonMonths,
    required this.dailyTargetSeconds,
    required this.activeWeekdaysMask,
    required this.startDate,
    this.reminderMinutes,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['horizon_months'] = Variable<int>(horizonMonths);
    map['daily_target_seconds'] = Variable<int>(dailyTargetSeconds);
    map['active_weekdays_mask'] = Variable<int>(activeWeekdaysMask);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || reminderMinutes != null) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      title: Value(title),
      horizonMonths: Value(horizonMonths),
      dailyTargetSeconds: Value(dailyTargetSeconds),
      activeWeekdaysMask: Value(activeWeekdaysMask),
      startDate: Value(startDate),
      reminderMinutes: reminderMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutes),
      position: Value(position),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      horizonMonths: serializer.fromJson<int>(json['horizonMonths']),
      dailyTargetSeconds: serializer.fromJson<int>(json['dailyTargetSeconds']),
      activeWeekdaysMask: serializer.fromJson<int>(json['activeWeekdaysMask']),
      startDate: serializer.fromJson<String>(json['startDate']),
      reminderMinutes: serializer.fromJson<int?>(json['reminderMinutes']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'horizonMonths': serializer.toJson<int>(horizonMonths),
      'dailyTargetSeconds': serializer.toJson<int>(dailyTargetSeconds),
      'activeWeekdaysMask': serializer.toJson<int>(activeWeekdaysMask),
      'startDate': serializer.toJson<String>(startDate),
      'reminderMinutes': serializer.toJson<int?>(reminderMinutes),
      'position': serializer.toJson<int>(position),
    };
  }

  GoalRow copyWith({
    int? id,
    String? title,
    int? horizonMonths,
    int? dailyTargetSeconds,
    int? activeWeekdaysMask,
    String? startDate,
    Value<int?> reminderMinutes = const Value.absent(),
    int? position,
  }) => GoalRow(
    id: id ?? this.id,
    title: title ?? this.title,
    horizonMonths: horizonMonths ?? this.horizonMonths,
    dailyTargetSeconds: dailyTargetSeconds ?? this.dailyTargetSeconds,
    activeWeekdaysMask: activeWeekdaysMask ?? this.activeWeekdaysMask,
    startDate: startDate ?? this.startDate,
    reminderMinutes: reminderMinutes.present
        ? reminderMinutes.value
        : this.reminderMinutes,
    position: position ?? this.position,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      horizonMonths: data.horizonMonths.present
          ? data.horizonMonths.value
          : this.horizonMonths,
      dailyTargetSeconds: data.dailyTargetSeconds.present
          ? data.dailyTargetSeconds.value
          : this.dailyTargetSeconds,
      activeWeekdaysMask: data.activeWeekdaysMask.present
          ? data.activeWeekdaysMask.value
          : this.activeWeekdaysMask,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('horizonMonths: $horizonMonths, ')
          ..write('dailyTargetSeconds: $dailyTargetSeconds, ')
          ..write('activeWeekdaysMask: $activeWeekdaysMask, ')
          ..write('startDate: $startDate, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    horizonMonths,
    dailyTargetSeconds,
    activeWeekdaysMask,
    startDate,
    reminderMinutes,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.horizonMonths == this.horizonMonths &&
          other.dailyTargetSeconds == this.dailyTargetSeconds &&
          other.activeWeekdaysMask == this.activeWeekdaysMask &&
          other.startDate == this.startDate &&
          other.reminderMinutes == this.reminderMinutes &&
          other.position == this.position);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> horizonMonths;
  final Value<int> dailyTargetSeconds;
  final Value<int> activeWeekdaysMask;
  final Value<String> startDate;
  final Value<int?> reminderMinutes;
  final Value<int> position;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.horizonMonths = const Value.absent(),
    this.dailyTargetSeconds = const Value.absent(),
    this.activeWeekdaysMask = const Value.absent(),
    this.startDate = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.position = const Value.absent(),
  });
  GoalsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required int horizonMonths,
    required int dailyTargetSeconds,
    required int activeWeekdaysMask,
    required String startDate,
    this.reminderMinutes = const Value.absent(),
    this.position = const Value.absent(),
  }) : title = Value(title),
       horizonMonths = Value(horizonMonths),
       dailyTargetSeconds = Value(dailyTargetSeconds),
       activeWeekdaysMask = Value(activeWeekdaysMask),
       startDate = Value(startDate);
  static Insertable<GoalRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? horizonMonths,
    Expression<int>? dailyTargetSeconds,
    Expression<int>? activeWeekdaysMask,
    Expression<String>? startDate,
    Expression<int>? reminderMinutes,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (horizonMonths != null) 'horizon_months': horizonMonths,
      if (dailyTargetSeconds != null)
        'daily_target_seconds': dailyTargetSeconds,
      if (activeWeekdaysMask != null)
        'active_weekdays_mask': activeWeekdaysMask,
      if (startDate != null) 'start_date': startDate,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (position != null) 'position': position,
    });
  }

  GoalsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? horizonMonths,
    Value<int>? dailyTargetSeconds,
    Value<int>? activeWeekdaysMask,
    Value<String>? startDate,
    Value<int?>? reminderMinutes,
    Value<int>? position,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      horizonMonths: horizonMonths ?? this.horizonMonths,
      dailyTargetSeconds: dailyTargetSeconds ?? this.dailyTargetSeconds,
      activeWeekdaysMask: activeWeekdaysMask ?? this.activeWeekdaysMask,
      startDate: startDate ?? this.startDate,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (horizonMonths.present) {
      map['horizon_months'] = Variable<int>(horizonMonths.value);
    }
    if (dailyTargetSeconds.present) {
      map['daily_target_seconds'] = Variable<int>(dailyTargetSeconds.value);
    }
    if (activeWeekdaysMask.present) {
      map['active_weekdays_mask'] = Variable<int>(activeWeekdaysMask.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('horizonMonths: $horizonMonths, ')
          ..write('dailyTargetSeconds: $dailyTargetSeconds, ')
          ..write('activeWeekdaysMask: $activeWeekdaysMask, ')
          ..write('startDate: $startDate, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DailyLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSecondsMeta = const VerificationMeta(
    'totalSeconds',
  );
  @override
  late final GeneratedColumn<int> totalSeconds = GeneratedColumn<int>(
    'total_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [goalId, date, totalSeconds, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('total_seconds')) {
      context.handle(
        _totalSecondsMeta,
        totalSeconds.isAcceptableOrUnknown(
          data['total_seconds']!,
          _totalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalSecondsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {goalId, date};
  @override
  DailyLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyLogRow(
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      totalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_seconds'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }
}

class DailyLogRow extends DataClass implements Insertable<DailyLogRow> {
  final int goalId;

  /// ISO local date `yyyy-MM-dd`.
  final String date;
  final int totalSeconds;

  /// [DayStatus] name, stored for convenience; always recomputable.
  final String status;
  const DailyLogRow({
    required this.goalId,
    required this.date,
    required this.totalSeconds,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['goal_id'] = Variable<int>(goalId);
    map['date'] = Variable<String>(date);
    map['total_seconds'] = Variable<int>(totalSeconds);
    map['status'] = Variable<String>(status);
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      goalId: Value(goalId),
      date: Value(date),
      totalSeconds: Value(totalSeconds),
      status: Value(status),
    );
  }

  factory DailyLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyLogRow(
      goalId: serializer.fromJson<int>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      totalSeconds: serializer.fromJson<int>(json['totalSeconds']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'goalId': serializer.toJson<int>(goalId),
      'date': serializer.toJson<String>(date),
      'totalSeconds': serializer.toJson<int>(totalSeconds),
      'status': serializer.toJson<String>(status),
    };
  }

  DailyLogRow copyWith({
    int? goalId,
    String? date,
    int? totalSeconds,
    String? status,
  }) => DailyLogRow(
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    status: status ?? this.status,
  );
  DailyLogRow copyWithCompanion(DailyLogsCompanion data) {
    return DailyLogRow(
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      totalSeconds: data.totalSeconds.present
          ? data.totalSeconds.value
          : this.totalSeconds,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogRow(')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(goalId, date, totalSeconds, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyLogRow &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.totalSeconds == this.totalSeconds &&
          other.status == this.status);
}

class DailyLogsCompanion extends UpdateCompanion<DailyLogRow> {
  final Value<int> goalId;
  final Value<String> date;
  final Value<int> totalSeconds;
  final Value<String> status;
  final Value<int> rowid;
  const DailyLogsCompanion({
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.totalSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    required int goalId,
    required String date,
    required int totalSeconds,
    required String status,
    this.rowid = const Value.absent(),
  }) : goalId = Value(goalId),
       date = Value(date),
       totalSeconds = Value(totalSeconds),
       status = Value(status);
  static Insertable<DailyLogRow> custom({
    Expression<int>? goalId,
    Expression<String>? date,
    Expression<int>? totalSeconds,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (totalSeconds != null) 'total_seconds': totalSeconds,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyLogsCompanion copyWith({
    Value<int>? goalId,
    Value<String>? date,
    Value<int>? totalSeconds,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return DailyLogsCompanion(
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (totalSeconds.present) {
      map['total_seconds'] = Variable<int>(totalSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('totalSeconds: $totalSeconds, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActiveSessionsTable extends ActiveSessions
    with TableInfo<$ActiveSessionsTable, ActiveSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActiveSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<int> goalId = GeneratedColumn<int>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseSecondsMeta = const VerificationMeta(
    'baseSeconds',
  );
  @override
  late final GeneratedColumn<int> baseSeconds = GeneratedColumn<int>(
    'base_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentStartedAtMsMeta =
      const VerificationMeta('segmentStartedAtMs');
  @override
  late final GeneratedColumn<int> segmentStartedAtMs = GeneratedColumn<int>(
    'segment_started_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accumulatedSecondsMeta =
      const VerificationMeta('accumulatedSeconds');
  @override
  late final GeneratedColumn<int> accumulatedSeconds = GeneratedColumn<int>(
    'accumulated_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _safetyNetFiredMeta = const VerificationMeta(
    'safetyNetFired',
  );
  @override
  late final GeneratedColumn<bool> safetyNetFired = GeneratedColumn<bool>(
    'safety_net_fired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("safety_net_fired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _targetFiredMeta = const VerificationMeta(
    'targetFired',
  );
  @override
  late final GeneratedColumn<bool> targetFired = GeneratedColumn<bool>(
    'target_fired',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("target_fired" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    date,
    baseSeconds,
    segmentStartedAtMs,
    accumulatedSeconds,
    safetyNetFired,
    targetFired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'active_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActiveSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('base_seconds')) {
      context.handle(
        _baseSecondsMeta,
        baseSeconds.isAcceptableOrUnknown(
          data['base_seconds']!,
          _baseSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_baseSecondsMeta);
    }
    if (data.containsKey('segment_started_at_ms')) {
      context.handle(
        _segmentStartedAtMsMeta,
        segmentStartedAtMs.isAcceptableOrUnknown(
          data['segment_started_at_ms']!,
          _segmentStartedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('accumulated_seconds')) {
      context.handle(
        _accumulatedSecondsMeta,
        accumulatedSeconds.isAcceptableOrUnknown(
          data['accumulated_seconds']!,
          _accumulatedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accumulatedSecondsMeta);
    }
    if (data.containsKey('safety_net_fired')) {
      context.handle(
        _safetyNetFiredMeta,
        safetyNetFired.isAcceptableOrUnknown(
          data['safety_net_fired']!,
          _safetyNetFiredMeta,
        ),
      );
    }
    if (data.containsKey('target_fired')) {
      context.handle(
        _targetFiredMeta,
        targetFired.isAcceptableOrUnknown(
          data['target_fired']!,
          _targetFiredMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActiveSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActiveSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      baseSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_seconds'],
      )!,
      segmentStartedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment_started_at_ms'],
      ),
      accumulatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accumulated_seconds'],
      )!,
      safetyNetFired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}safety_net_fired'],
      )!,
      targetFired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}target_fired'],
      )!,
    );
  }

  @override
  $ActiveSessionsTable createAlias(String alias) {
    return $ActiveSessionsTable(attachedDatabase, alias);
  }
}

class ActiveSessionRow extends DataClass
    implements Insertable<ActiveSessionRow> {
  final int id;
  final int goalId;
  final String date;
  final int baseSeconds;

  /// UTC epoch milliseconds, null while paused.
  final int? segmentStartedAtMs;
  final int accumulatedSeconds;
  final bool safetyNetFired;
  final bool targetFired;
  const ActiveSessionRow({
    required this.id,
    required this.goalId,
    required this.date,
    required this.baseSeconds,
    this.segmentStartedAtMs,
    required this.accumulatedSeconds,
    required this.safetyNetFired,
    required this.targetFired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['goal_id'] = Variable<int>(goalId);
    map['date'] = Variable<String>(date);
    map['base_seconds'] = Variable<int>(baseSeconds);
    if (!nullToAbsent || segmentStartedAtMs != null) {
      map['segment_started_at_ms'] = Variable<int>(segmentStartedAtMs);
    }
    map['accumulated_seconds'] = Variable<int>(accumulatedSeconds);
    map['safety_net_fired'] = Variable<bool>(safetyNetFired);
    map['target_fired'] = Variable<bool>(targetFired);
    return map;
  }

  ActiveSessionsCompanion toCompanion(bool nullToAbsent) {
    return ActiveSessionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      date: Value(date),
      baseSeconds: Value(baseSeconds),
      segmentStartedAtMs: segmentStartedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(segmentStartedAtMs),
      accumulatedSeconds: Value(accumulatedSeconds),
      safetyNetFired: Value(safetyNetFired),
      targetFired: Value(targetFired),
    );
  }

  factory ActiveSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActiveSessionRow(
      id: serializer.fromJson<int>(json['id']),
      goalId: serializer.fromJson<int>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      baseSeconds: serializer.fromJson<int>(json['baseSeconds']),
      segmentStartedAtMs: serializer.fromJson<int?>(json['segmentStartedAtMs']),
      accumulatedSeconds: serializer.fromJson<int>(json['accumulatedSeconds']),
      safetyNetFired: serializer.fromJson<bool>(json['safetyNetFired']),
      targetFired: serializer.fromJson<bool>(json['targetFired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'goalId': serializer.toJson<int>(goalId),
      'date': serializer.toJson<String>(date),
      'baseSeconds': serializer.toJson<int>(baseSeconds),
      'segmentStartedAtMs': serializer.toJson<int?>(segmentStartedAtMs),
      'accumulatedSeconds': serializer.toJson<int>(accumulatedSeconds),
      'safetyNetFired': serializer.toJson<bool>(safetyNetFired),
      'targetFired': serializer.toJson<bool>(targetFired),
    };
  }

  ActiveSessionRow copyWith({
    int? id,
    int? goalId,
    String? date,
    int? baseSeconds,
    Value<int?> segmentStartedAtMs = const Value.absent(),
    int? accumulatedSeconds,
    bool? safetyNetFired,
    bool? targetFired,
  }) => ActiveSessionRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    baseSeconds: baseSeconds ?? this.baseSeconds,
    segmentStartedAtMs: segmentStartedAtMs.present
        ? segmentStartedAtMs.value
        : this.segmentStartedAtMs,
    accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    safetyNetFired: safetyNetFired ?? this.safetyNetFired,
    targetFired: targetFired ?? this.targetFired,
  );
  ActiveSessionRow copyWithCompanion(ActiveSessionsCompanion data) {
    return ActiveSessionRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      baseSeconds: data.baseSeconds.present
          ? data.baseSeconds.value
          : this.baseSeconds,
      segmentStartedAtMs: data.segmentStartedAtMs.present
          ? data.segmentStartedAtMs.value
          : this.segmentStartedAtMs,
      accumulatedSeconds: data.accumulatedSeconds.present
          ? data.accumulatedSeconds.value
          : this.accumulatedSeconds,
      safetyNetFired: data.safetyNetFired.present
          ? data.safetyNetFired.value
          : this.safetyNetFired,
      targetFired: data.targetFired.present
          ? data.targetFired.value
          : this.targetFired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('baseSeconds: $baseSeconds, ')
          ..write('segmentStartedAtMs: $segmentStartedAtMs, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('safetyNetFired: $safetyNetFired, ')
          ..write('targetFired: $targetFired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    date,
    baseSeconds,
    segmentStartedAtMs,
    accumulatedSeconds,
    safetyNetFired,
    targetFired,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActiveSessionRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.baseSeconds == this.baseSeconds &&
          other.segmentStartedAtMs == this.segmentStartedAtMs &&
          other.accumulatedSeconds == this.accumulatedSeconds &&
          other.safetyNetFired == this.safetyNetFired &&
          other.targetFired == this.targetFired);
}

class ActiveSessionsCompanion extends UpdateCompanion<ActiveSessionRow> {
  final Value<int> id;
  final Value<int> goalId;
  final Value<String> date;
  final Value<int> baseSeconds;
  final Value<int?> segmentStartedAtMs;
  final Value<int> accumulatedSeconds;
  final Value<bool> safetyNetFired;
  final Value<bool> targetFired;
  const ActiveSessionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.baseSeconds = const Value.absent(),
    this.segmentStartedAtMs = const Value.absent(),
    this.accumulatedSeconds = const Value.absent(),
    this.safetyNetFired = const Value.absent(),
    this.targetFired = const Value.absent(),
  });
  ActiveSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int goalId,
    required String date,
    required int baseSeconds,
    this.segmentStartedAtMs = const Value.absent(),
    required int accumulatedSeconds,
    this.safetyNetFired = const Value.absent(),
    this.targetFired = const Value.absent(),
  }) : goalId = Value(goalId),
       date = Value(date),
       baseSeconds = Value(baseSeconds),
       accumulatedSeconds = Value(accumulatedSeconds);
  static Insertable<ActiveSessionRow> custom({
    Expression<int>? id,
    Expression<int>? goalId,
    Expression<String>? date,
    Expression<int>? baseSeconds,
    Expression<int>? segmentStartedAtMs,
    Expression<int>? accumulatedSeconds,
    Expression<bool>? safetyNetFired,
    Expression<bool>? targetFired,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (baseSeconds != null) 'base_seconds': baseSeconds,
      if (segmentStartedAtMs != null)
        'segment_started_at_ms': segmentStartedAtMs,
      if (accumulatedSeconds != null) 'accumulated_seconds': accumulatedSeconds,
      if (safetyNetFired != null) 'safety_net_fired': safetyNetFired,
      if (targetFired != null) 'target_fired': targetFired,
    });
  }

  ActiveSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? goalId,
    Value<String>? date,
    Value<int>? baseSeconds,
    Value<int?>? segmentStartedAtMs,
    Value<int>? accumulatedSeconds,
    Value<bool>? safetyNetFired,
    Value<bool>? targetFired,
  }) {
    return ActiveSessionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      baseSeconds: baseSeconds ?? this.baseSeconds,
      segmentStartedAtMs: segmentStartedAtMs ?? this.segmentStartedAtMs,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      safetyNetFired: safetyNetFired ?? this.safetyNetFired,
      targetFired: targetFired ?? this.targetFired,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<int>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (baseSeconds.present) {
      map['base_seconds'] = Variable<int>(baseSeconds.value);
    }
    if (segmentStartedAtMs.present) {
      map['segment_started_at_ms'] = Variable<int>(segmentStartedAtMs.value);
    }
    if (accumulatedSeconds.present) {
      map['accumulated_seconds'] = Variable<int>(accumulatedSeconds.value);
    }
    if (safetyNetFired.present) {
      map['safety_net_fired'] = Variable<bool>(safetyNetFired.value);
    }
    if (targetFired.present) {
      map['target_fired'] = Variable<bool>(targetFired.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActiveSessionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('baseSeconds: $baseSeconds, ')
          ..write('segmentStartedAtMs: $segmentStartedAtMs, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('safetyNetFired: $safetyNetFired, ')
          ..write('targetFired: $targetFired')
          ..write(')'))
        .toString();
  }
}

class $LocalAccountsTable extends LocalAccounts
    with TableInfo<$LocalAccountsTable, LocalAccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _saltMeta = const VerificationMeta('salt');
  @override
  late final GeneratedColumn<String> salt = GeneratedColumn<String>(
    'salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [email, passwordHash, salt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('salt')) {
      context.handle(
        _saltMeta,
        salt.isAcceptableOrUnknown(data['salt']!, _saltMeta),
      );
    } else if (isInserting) {
      context.missing(_saltMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {email};
  @override
  LocalAccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAccountRow(
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      salt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt'],
      )!,
    );
  }

  @override
  $LocalAccountsTable createAlias(String alias) {
    return $LocalAccountsTable(attachedDatabase, alias);
  }
}

class LocalAccountRow extends DataClass implements Insertable<LocalAccountRow> {
  final String email;
  final String passwordHash;
  final String salt;
  const LocalAccountRow({
    required this.email,
    required this.passwordHash,
    required this.salt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['salt'] = Variable<String>(salt);
    return map;
  }

  LocalAccountsCompanion toCompanion(bool nullToAbsent) {
    return LocalAccountsCompanion(
      email: Value(email),
      passwordHash: Value(passwordHash),
      salt: Value(salt),
    );
  }

  factory LocalAccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAccountRow(
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      salt: serializer.fromJson<String>(json['salt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'salt': serializer.toJson<String>(salt),
    };
  }

  LocalAccountRow copyWith({
    String? email,
    String? passwordHash,
    String? salt,
  }) => LocalAccountRow(
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    salt: salt ?? this.salt,
  );
  LocalAccountRow copyWithCompanion(LocalAccountsCompanion data) {
    return LocalAccountRow(
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      salt: data.salt.present ? data.salt.value : this.salt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountRow(')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(email, passwordHash, salt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAccountRow &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.salt == this.salt);
}

class LocalAccountsCompanion extends UpdateCompanion<LocalAccountRow> {
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<String> salt;
  final Value<int> rowid;
  const LocalAccountsCompanion({
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.salt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAccountsCompanion.insert({
    required String email,
    required String passwordHash,
    required String salt,
    this.rowid = const Value.absent(),
  }) : email = Value(email),
       passwordHash = Value(passwordHash),
       salt = Value(salt);
  static Insertable<LocalAccountRow> custom({
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<String>? salt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (salt != null) 'salt': salt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAccountsCompanion copyWith({
    Value<String>? email,
    Value<String>? passwordHash,
    Value<String>? salt,
    Value<int>? rowid,
  }) {
    return LocalAccountsCompanion(
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (salt.present) {
      map['salt'] = Variable<String>(salt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAccountsCompanion(')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('salt: $salt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, PreferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<PreferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PreferenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PreferenceRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class PreferenceRow extends DataClass implements Insertable<PreferenceRow> {
  final String key;
  final String value;
  const PreferenceRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory PreferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PreferenceRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PreferenceRow copyWith({String? key, String? value}) =>
      PreferenceRow(key: key ?? this.key, value: value ?? this.value);
  PreferenceRow copyWithCompanion(PreferencesCompanion data) {
    return PreferenceRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PreferenceRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PreferenceRow &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<PreferenceRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PreferenceRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $ActiveSessionsTable activeSessions = $ActiveSessionsTable(this);
  late final $LocalAccountsTable localAccounts = $LocalAccountsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    dailyLogs,
    activeSessions,
    localAccounts,
    preferences,
  ];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  required String title,
  required int horizonMonths,
  required int dailyTargetSeconds,
  required int activeWeekdaysMask,
  required String startDate,
  Value<int?> reminderMinutes,
  Value<int> position,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<int> horizonMonths,
  Value<int> dailyTargetSeconds,
  Value<int> activeWeekdaysMask,
  Value<String> startDate,
  Value<int?> reminderMinutes,
  Value<int> position,
});

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyTargetSeconds => $composableBuilder(
    column: $table.dailyTargetSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeWeekdaysMask => $composableBuilder(
    column: $table.activeWeekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyTargetSeconds => $composableBuilder(
    column: $table.dailyTargetSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeWeekdaysMask => $composableBuilder(
    column: $table.activeWeekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get horizonMonths => $composableBuilder(
    column: $table.horizonMonths,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyTargetSeconds => $composableBuilder(
    column: $table.dailyTargetSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeWeekdaysMask => $composableBuilder(
    column: $table.activeWeekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
          GoalRow,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> horizonMonths = const Value.absent(),
                Value<int> dailyTargetSeconds = const Value.absent(),
                Value<int> activeWeekdaysMask = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<int?> reminderMinutes = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                title: title,
                horizonMonths: horizonMonths,
                dailyTargetSeconds: dailyTargetSeconds,
                activeWeekdaysMask: activeWeekdaysMask,
                startDate: startDate,
                reminderMinutes: reminderMinutes,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required int horizonMonths,
                required int dailyTargetSeconds,
                required int activeWeekdaysMask,
                required String startDate,
                Value<int?> reminderMinutes = const Value.absent(),
                Value<int> position = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                title: title,
                horizonMonths: horizonMonths,
                dailyTargetSeconds: dailyTargetSeconds,
                activeWeekdaysMask: activeWeekdaysMask,
                startDate: startDate,
                reminderMinutes: reminderMinutes,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalRow>(table),
                  BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, BaseReferences<_$AppDatabase, $GoalsTable, GoalRow>),
      GoalRow,
      PrefetchHooks Function()
    >;
typedef $$DailyLogsTableCreateCompanionBuilder = DailyLogsCompanion Function({
  required int goalId,
  required String date,
  required int totalSeconds,
  required String status,
  Value<int> rowid,
});
typedef $$DailyLogsTableUpdateCompanionBuilder = DailyLogsCompanion Function({
  Value<int> goalId,
  Value<String> date,
  Value<int> totalSeconds,
  Value<String> status,
  Value<int> rowid,
});

class $$DailyLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get totalSeconds => $composableBuilder(
    column: $table.totalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$DailyLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyLogsTable,
          DailyLogRow,
          $$DailyLogsTableFilterComposer,
          $$DailyLogsTableOrderingComposer,
          $$DailyLogsTableAnnotationComposer,
          $$DailyLogsTableCreateCompanionBuilder,
          $$DailyLogsTableUpdateCompanionBuilder,
          (
            DailyLogRow,
            BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>,
          ),
          DailyLogRow,
          PrefetchHooks Function()
        > {
  $$DailyLogsTableTableManager(_$AppDatabase db, $DailyLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> totalSeconds = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion(
                goalId: goalId,
                date: date,
                totalSeconds: totalSeconds,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int goalId,
                required String date,
                required int totalSeconds,
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => DailyLogsCompanion.insert(
                goalId: goalId,
                date: date,
                totalSeconds: totalSeconds,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyLogsTable, DailyLogRow>(table),
                  BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyLogsTable,
      DailyLogRow,
      $$DailyLogsTableFilterComposer,
      $$DailyLogsTableOrderingComposer,
      $$DailyLogsTableAnnotationComposer,
      $$DailyLogsTableCreateCompanionBuilder,
      $$DailyLogsTableUpdateCompanionBuilder,
      (
        DailyLogRow,
        BaseReferences<_$AppDatabase, $DailyLogsTable, DailyLogRow>,
      ),
      DailyLogRow,
      PrefetchHooks Function()
    >;
typedef $$ActiveSessionsTableCreateCompanionBuilder =
    ActiveSessionsCompanion Function({
      Value<int> id,
      required int goalId,
      required String date,
      required int baseSeconds,
      Value<int?> segmentStartedAtMs,
      required int accumulatedSeconds,
      Value<bool> safetyNetFired,
      Value<bool> targetFired,
    });
typedef $$ActiveSessionsTableUpdateCompanionBuilder =
    ActiveSessionsCompanion Function({
      Value<int> id,
      Value<int> goalId,
      Value<String> date,
      Value<int> baseSeconds,
      Value<int?> segmentStartedAtMs,
      Value<int> accumulatedSeconds,
      Value<bool> safetyNetFired,
      Value<bool> targetFired,
    });

class $$ActiveSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTable> {
  $$ActiveSessionsTableFilterComposer({
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

  ColumnFilters<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseSeconds => $composableBuilder(
    column: $table.baseSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segmentStartedAtMs => $composableBuilder(
    column: $table.segmentStartedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get safetyNetFired => $composableBuilder(
    column: $table.safetyNetFired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get targetFired => $composableBuilder(
    column: $table.targetFired,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActiveSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTable> {
  $$ActiveSessionsTableOrderingComposer({
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

  ColumnOrderings<int> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseSeconds => $composableBuilder(
    column: $table.baseSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segmentStartedAtMs => $composableBuilder(
    column: $table.segmentStartedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get safetyNetFired => $composableBuilder(
    column: $table.safetyNetFired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get targetFired => $composableBuilder(
    column: $table.targetFired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActiveSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActiveSessionsTable> {
  $$ActiveSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get baseSeconds => $composableBuilder(
    column: $table.baseSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get segmentStartedAtMs => $composableBuilder(
    column: $table.segmentStartedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get safetyNetFired => $composableBuilder(
    column: $table.safetyNetFired,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get targetFired => $composableBuilder(
    column: $table.targetFired,
    builder: (column) => column,
  );
}

class $$ActiveSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActiveSessionsTable,
          ActiveSessionRow,
          $$ActiveSessionsTableFilterComposer,
          $$ActiveSessionsTableOrderingComposer,
          $$ActiveSessionsTableAnnotationComposer,
          $$ActiveSessionsTableCreateCompanionBuilder,
          $$ActiveSessionsTableUpdateCompanionBuilder,
          (
            ActiveSessionRow,
            BaseReferences<
              _$AppDatabase,
              $ActiveSessionsTable,
              ActiveSessionRow
            >,
          ),
          ActiveSessionRow,
          PrefetchHooks Function()
        > {
  $$ActiveSessionsTableTableManager(
    _$AppDatabase db,
    $ActiveSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActiveSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActiveSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActiveSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> baseSeconds = const Value.absent(),
                Value<int?> segmentStartedAtMs = const Value.absent(),
                Value<int> accumulatedSeconds = const Value.absent(),
                Value<bool> safetyNetFired = const Value.absent(),
                Value<bool> targetFired = const Value.absent(),
              }) => ActiveSessionsCompanion(
                id: id,
                goalId: goalId,
                date: date,
                baseSeconds: baseSeconds,
                segmentStartedAtMs: segmentStartedAtMs,
                accumulatedSeconds: accumulatedSeconds,
                safetyNetFired: safetyNetFired,
                targetFired: targetFired,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int goalId,
                required String date,
                required int baseSeconds,
                Value<int?> segmentStartedAtMs = const Value.absent(),
                required int accumulatedSeconds,
                Value<bool> safetyNetFired = const Value.absent(),
                Value<bool> targetFired = const Value.absent(),
              }) => ActiveSessionsCompanion.insert(
                id: id,
                goalId: goalId,
                date: date,
                baseSeconds: baseSeconds,
                segmentStartedAtMs: segmentStartedAtMs,
                accumulatedSeconds: accumulatedSeconds,
                safetyNetFired: safetyNetFired,
                targetFired: targetFired,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ActiveSessionsTable, ActiveSessionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ActiveSessionsTable,
                    ActiveSessionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActiveSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActiveSessionsTable,
      ActiveSessionRow,
      $$ActiveSessionsTableFilterComposer,
      $$ActiveSessionsTableOrderingComposer,
      $$ActiveSessionsTableAnnotationComposer,
      $$ActiveSessionsTableCreateCompanionBuilder,
      $$ActiveSessionsTableUpdateCompanionBuilder,
      (
        ActiveSessionRow,
        BaseReferences<_$AppDatabase, $ActiveSessionsTable, ActiveSessionRow>,
      ),
      ActiveSessionRow,
      PrefetchHooks Function()
    >;
typedef $$LocalAccountsTableCreateCompanionBuilder =
    LocalAccountsCompanion Function({
      required String email,
      required String passwordHash,
      required String salt,
      Value<int> rowid,
    });
typedef $$LocalAccountsTableUpdateCompanionBuilder =
    LocalAccountsCompanion Function({
      Value<String> email,
      Value<String> passwordHash,
      Value<String> salt,
      Value<int> rowid,
    });

class $$LocalAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get salt => $composableBuilder(
    column: $table.salt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAccountsTable> {
  $$LocalAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get salt =>
      $composableBuilder(column: $table.salt, builder: (column) => column);
}

class $$LocalAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAccountsTable,
          LocalAccountRow,
          $$LocalAccountsTableFilterComposer,
          $$LocalAccountsTableOrderingComposer,
          $$LocalAccountsTableAnnotationComposer,
          $$LocalAccountsTableCreateCompanionBuilder,
          $$LocalAccountsTableUpdateCompanionBuilder,
          (
            LocalAccountRow,
            BaseReferences<_$AppDatabase, $LocalAccountsTable, LocalAccountRow>,
          ),
          LocalAccountRow,
          PrefetchHooks Function()
        > {
  $$LocalAccountsTableTableManager(_$AppDatabase db, $LocalAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> salt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion(
                email: email,
                passwordHash: passwordHash,
                salt: salt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String email,
                required String passwordHash,
                required String salt,
                Value<int> rowid = const Value.absent(),
              }) => LocalAccountsCompanion.insert(
                email: email,
                passwordHash: passwordHash,
                salt: salt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAccountsTable, LocalAccountRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAccountsTable,
                    LocalAccountRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAccountsTable,
      LocalAccountRow,
      $$LocalAccountsTableFilterComposer,
      $$LocalAccountsTableOrderingComposer,
      $$LocalAccountsTableAnnotationComposer,
      $$LocalAccountsTableCreateCompanionBuilder,
      $$LocalAccountsTableUpdateCompanionBuilder,
      (
        LocalAccountRow,
        BaseReferences<_$AppDatabase, $LocalAccountsTable, LocalAccountRow>,
      ),
      LocalAccountRow,
      PrefetchHooks Function()
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          PreferenceRow,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            PreferenceRow,
            BaseReferences<_$AppDatabase, $PreferencesTable, PreferenceRow>,
          ),
          PreferenceRow,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, PreferenceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PreferencesTable,
                    PreferenceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      PreferenceRow,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        PreferenceRow,
        BaseReferences<_$AppDatabase, $PreferencesTable, PreferenceRow>,
      ),
      PreferenceRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$DailyLogsTableTableManager get dailyLogs =>
      $$DailyLogsTableTableManager(_db, _db.dailyLogs);
  $$ActiveSessionsTableTableManager get activeSessions =>
      $$ActiveSessionsTableTableManager(_db, _db.activeSessions);
  $$LocalAccountsTableTableManager get localAccounts =>
      $$LocalAccountsTableTableManager(_db, _db.localAccounts);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
