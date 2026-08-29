import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/domain.dart';
import '../../repositories/block_repository.dart';

BlockKind phaseAfterFocus({
  required int completedFocusRounds,
  required int roundsBeforeLongBreak,
}) {
  final round = completedFocusRounds % roundsBeforeLongBreak;
  return round == 0 ? BlockKind.longBreak : BlockKind.shortBreak;
}

class PomodoroState {
  const PomodoroState({
    this.settings = TimerSettings.defaults,
    this.kind = BlockKind.focus,
    this.activityId,
    this.phaseIndex = 0,
    this.remaining = const Duration(minutes: 25),
    this.running = false,
    this.status = 'Ready',
    this.startedAt,
  });

  final TimerSettings settings;
  final BlockKind kind;
  final String? activityId;
  final int phaseIndex;
  final Duration remaining;
  final bool running;
  final String status;
  final DateTime? startedAt;

  PomodoroState copyWith({
    TimerSettings? settings,
    BlockKind? kind,
    String? activityId,
    int? phaseIndex,
    Duration? remaining,
    bool? running,
    String? status,
    DateTime? startedAt,
  }) =>
      PomodoroState(
        settings: settings ?? this.settings,
        kind: kind ?? this.kind,
        activityId: activityId ?? this.activityId,
        phaseIndex: phaseIndex ?? this.phaseIndex,
        remaining: remaining ?? this.remaining,
        running: running ?? this.running,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
      );
}

class PomodoroController extends StateNotifier<PomodoroState> {
  PomodoroController({
    required String accountId,
    required AppDatabase database,
    required BlockRepository blockRepository,
  })  : _accountId = accountId,
        _database = database,
        _blocks = blockRepository,
        super(const PomodoroState()) {
    _restore();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final String _accountId;
  final AppDatabase _database;
  final BlockRepository _blocks;
  late Timer _ticker;
  bool _disposed = false;

  Future<void> _restore() async {
    final settings = await _database.settingsFor(_accountId);
    final persisted = await _database.timerState(_accountId);
    if (_disposed) return;
    if (persisted == null) {
      state = state.copyWith(
        settings: settings,
        remaining: Duration(minutes: settings.focusMinutes),
      );
      return;
    }
    final remaining = persisted.endsAt == null
        ? Duration(milliseconds: persisted.remainingMs)
        : persisted.endsAt!.difference(DateTime.now());
    state = PomodoroState(
      settings: settings,
      kind: persisted.kind,
      activityId: persisted.activityId,
      phaseIndex: persisted.phaseIndex,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      running: persisted.isRunning,
      status: persisted.isRunning ? 'Running' : 'Paused',
    );
    if (remaining.isNegative) await _complete();
  }

  Future<void> selectActivity(String? activityId) async {
    state = state.copyWith(activityId: activityId, status: 'Activity selected');
    await _persist();
  }

  Future<void> start() async {
    if (state.running) return;
    if (state.kind == BlockKind.focus && state.activityId == null) {
      state = state.copyWith(status: 'Choose an activity first');
      return;
    }
    final endsAt = DateTime.now().add(state.remaining);
    state = state.copyWith(running: true, status: 'Running');
    if (state.startedAt == null) {
      state = state.copyWith(startedAt: DateTime.now());
    }
    await _database.saveTimerState(
      _accountId,
      PersistedTimerState(
        activityId: state.activityId,
        kind: state.kind,
        phaseIndex: state.phaseIndex,
        startedAt: state.startedAt ?? DateTime.now(),
        endsAt: endsAt,
        paused: false,
        remainingMs: state.remaining.inMilliseconds,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> pause() async {
    if (!state.running) return;
    state = state.copyWith(running: false, status: 'Paused');
    await _persist();
  }

  Future<void> stop() async {
    state =
        PomodoroState(settings: state.settings, activityId: state.activityId);
    state =
        PomodoroState(settings: state.settings, activityId: state.activityId);
    await _database.clearTimerState(_accountId);
  }

  Future<void> updateSettings(TimerSettings settings) async {
    if (state.running) {
      state = state.copyWith(status: 'Stop the timer before changing settings');
      return;
    }
    state = state.copyWith(
      settings: settings,
      remaining: settings.durationFor(state.kind),
      status: 'Settings saved',
    );
    await _database.saveSettings(_accountId, settings);
  }

  Future<void> _persist() async {
    await _database.saveTimerState(
      _accountId,
      PersistedTimerState(
        activityId: state.activityId,
        kind: state.kind,
        phaseIndex: state.phaseIndex,
        startedAt: state.startedAt,
        endsAt: state.running ? DateTime.now().add(state.remaining) : null,
        paused: !state.running,
        remainingMs: state.remaining.inMilliseconds,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _tick() async {
    if (_disposed || !state.running) return;
    final remaining = state.remaining - const Duration(seconds: 1);
    if (remaining <= Duration.zero) {
      state = state.copyWith(remaining: Duration.zero, running: false);
      await _complete();
      return;
    }
    state = state.copyWith(remaining: remaining);
  }

  Future<void> _complete() async {
    final endedAt = DateTime.now();
    final startedAt = endedAt.subtract(state.settings.durationFor(state.kind));
    if (state.kind == BlockKind.focus && state.activityId != null) {
      await _blocks.save(
        TimeBlock(
          id: const Uuid().v7(),
          accountId: _accountId,
          activityId: state.activityId!,
          kind: BlockKind.focus,
          start: startedAt,
          end: endedAt,
          status: BlockStatus.completed,
          deleted: false,
          createdAt: startedAt,
          updatedAt: endedAt,
        ),
      );
    }
    final nextIndex =
        state.kind == BlockKind.focus ? state.phaseIndex + 1 : state.phaseIndex;
    final nextKind = state.kind == BlockKind.focus
        ? (nextIndex % state.settings.roundsBeforeLongBreak == 0
            ? BlockKind.longBreak
            : BlockKind.shortBreak)
        : BlockKind.focus;
    state = state.copyWith(
      kind: nextKind,
      phaseIndex: nextIndex,
      remaining: state.settings.durationFor(nextKind),
      running: state.kind == BlockKind.focus
          ? state.settings.autoStartBreaks
          : state.settings.autoStartFocus,
      status:
          state.kind == BlockKind.focus ? 'Focus complete' : 'Break complete',
    );
    await _persist();
    if (state.running) await start();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.cancel();
    super.dispose();
  }
}
