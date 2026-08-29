import 'package:collection/collection.dart';

enum BlockKind { focus, shortBreak, longBreak }

enum BlockStatus { active, completed, cancelled }

class Activity {
  const Activity({
    required this.id,
    required this.accountId,
    required this.name,
    required this.color,
    required this.archived,
    required this.deleted,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final String name;
  final int color;
  final bool archived;
  final bool deleted;
  final DateTime updatedAt;
  final DateTime createdAt;

  Activity copyWith({
    String? name,
    int? color,
    bool? archived,
    bool? deleted,
    DateTime? updatedAt,
  }) =>
      Activity(
        id: id,
        accountId: accountId,
        name: name ?? this.name,
        color: color ?? this.color,
        archived: archived ?? this.archived,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'name': name,
        'color': color,
        'archived': archived,
        'deleted': deleted,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Activity fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        name: json['name'] as String,
        color: json['color'] as int,
        archived: json['archived'] as bool,
        deleted: json['deleted'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class TimeBlock {
  const TimeBlock({
    required this.id,
    required this.accountId,
    required this.activityId,
    required this.kind,
    required this.start,
    required this.end,
    required this.status,
    required this.deleted,
    required this.updatedAt,
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final String activityId;
  final BlockKind kind;
  final DateTime start;
  final DateTime end;
  final BlockStatus status;
  final bool deleted;
  final DateTime updatedAt;
  final DateTime createdAt;

  bool get overlaps => !end.isAfter(start);

  TimeBlock copyWith({
    String? activityId,
    BlockKind? kind,
    DateTime? start,
    DateTime? end,
    BlockStatus? status,
    bool? deleted,
    DateTime? updatedAt,
  }) =>
      TimeBlock(
        id: id,
        accountId: accountId,
        activityId: activityId ?? this.activityId,
        kind: kind ?? this.kind,
        start: start ?? this.start,
        end: end ?? this.end,
        status: status ?? this.status,
        deleted: deleted ?? this.deleted,
        updatedAt: updatedAt ?? this.updatedAt,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'activityId': activityId,
        'kind': kind.name,
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
        'status': status.name,
        'deleted': deleted,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  static TimeBlock fromJson(Map<String, dynamic> json) => TimeBlock(
        id: json['id'] as String,
        accountId: json['accountId'] as String,
        activityId: json['activityId'] as String,
        kind: BlockKind.values.byName(json['kind'] as String),
        start: DateTime.parse(json['start'] as String).toUtc(),
        end: DateTime.parse(json['end'] as String).toUtc(),
        status: BlockStatus.values.byName(json['status'] as String),
        deleted: json['deleted'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      );
}

class TimerSettings {
  const TimerSettings({
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.roundsBeforeLongBreak,
    required this.autoStartBreaks,
    required this.autoStartFocus,
  });

  static const defaults = TimerSettings(
    focusMinutes: 25,
    shortBreakMinutes: 5,
    longBreakMinutes: 15,
    roundsBeforeLongBreak: 4,
    autoStartBreaks: true,
    autoStartFocus: false,
  );

  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int roundsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;

  Duration durationFor(BlockKind kind) => switch (kind) {
        BlockKind.focus => Duration(minutes: focusMinutes),
        BlockKind.shortBreak => Duration(minutes: shortBreakMinutes),
        BlockKind.longBreak => Duration(minutes: longBreakMinutes),
      };

  TimerSettings copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? roundsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
  }) =>
      TimerSettings(
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        roundsBeforeLongBreak:
            roundsBeforeLongBreak ?? this.roundsBeforeLongBreak,
        autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
        autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      );
}

class PersistedTimerState {
  const PersistedTimerState({
    required this.activityId,
    required this.kind,
    required this.phaseIndex,
    required this.startedAt,
    required this.endsAt,
    required this.paused,
    required this.remainingMs,
    required this.updatedAt,
  });

  final String? activityId;
  final BlockKind kind;
  final int phaseIndex;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool paused;
  final int remainingMs;
  final DateTime updatedAt;

  bool get isRunning => !paused && endsAt != null;

  PersistedTimerState copyWith({
    String? activityId,
    BlockKind? kind,
    int? phaseIndex,
    DateTime? startedAt,
    DateTime? endsAt,
    bool? paused,
    int? remainingMs,
    DateTime? updatedAt,
  }) =>
      PersistedTimerState(
        activityId: activityId ?? this.activityId,
        kind: kind ?? this.kind,
        phaseIndex: phaseIndex ?? this.phaseIndex,
        startedAt: startedAt ?? this.startedAt,
        endsAt: endsAt ?? this.endsAt,
        paused: paused ?? this.paused,
        remainingMs: remainingMs ?? this.remainingMs,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );
}

class SyncBundle {
  const SyncBundle({
    required this.activities,
    required this.blocks,
    required this.serverTime,
  });

  final List<Activity> activities;
  final List<TimeBlock> blocks;
  final DateTime serverTime;

  static SyncBundle fromJson(Map<String, dynamic> json) => SyncBundle(
        activities: (json['activities'] as List<dynamic>)
            .map((item) => Activity.fromJson(item as Map<String, dynamic>))
            .toList(),
        blocks: (json['timeBlocks'] as List<dynamic>)
            .map((item) => TimeBlock.fromJson(item as Map<String, dynamic>))
            .toList(),
        serverTime: DateTime.parse(json['serverTime'] as String),
      );
}

class ActivityTotal {
  const ActivityTotal({
    required this.activityId,
    required this.name,
    required this.color,
    required this.duration,
    required this.blockCount,
  });

  final String activityId;
  final String name;
  final int color;
  final Duration duration;
  final int blockCount;

  double percentageOf(List<ActivityTotal> all) {
    final totalMs =
        all.fold<int>(0, (sum, item) => sum + item.duration.inMilliseconds);
    if (totalMs == 0) return 0;
    return duration.inMilliseconds / totalMs;
  }
}

Activity? activeActivityById(List<Activity> activities, String? id) =>
    activities
        .firstWhereOrNull((activity) => activity.id == id && !activity.deleted);
