import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../models/domain.dart';
import 'phase_notifications.dart';
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
    this.notifications,
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
  final PhaseNotifications? notifications;
  late Timer _ticker;
  bool _disposed = false;

  /// Real wall-clock start of the current focus run (the live arc on the
  /// clock). It is set when a focus run begins, cleared when the run is saved
  /// on pause / stop / completion, and re-anchored to "now" if the user deletes
  /// the live arc so the tape keeps growing from the deletion moment.
  DateTime? _runStart;

  /// The start of the current live recording, or `null` when idle / paused /
  /// on a break (in which case the clock shows no live arc).
  DateTime? get liveAnchorStart => _runStart;

  /// Cuts the live recording at this moment: sand laid before now is discarded
  /// and the clock keeps growing a fresh arc from here.
  void reanchorLive() {
    if (state.kind != BlockKind.focus || state.startedAt == null) return;
    _runStart = DateTime.now();
  }

  /// Saves the current focus run as a block spanning its real wall-clock
  /// [start, end]. A run is one contiguous stretch of running focus: pausing
  /// ends it (creating a gap), resuming starts a new one.
  Future<void> _finalizeRun(DateTime end) async {
    final runStart = _runStart;
    _runStart = null;
    if (state.kind != BlockKind.focus) return;
    final activityId = state.activityId;
    if (runStart == null || activityId == null) return;
    if (!end.isAfter(runStart)) return;
    await _blocks.save(
      TimeBlock(
        id: const Uuid().v7(),
        accountId: _accountId,
        activityId: activityId,
        kind: BlockKind.focus,
        start: runStart,
        end: end,
        status: BlockStatus.completed,
        deleted: false,
        createdAt: runStart,
        updatedAt: end,
      ),
    );
  }

  Future<void> _restore() async {
    final settings = await _database.settingsFor(_accountId);
    final persisted = await _database.timerState(_accountId);
    if (_disposed) return;
    if (persisted == null) {
      final activityId = await _database.firstActiveActivityId(_accountId);
      state = state.copyWith(
        settings: settings,
        activityId: activityId,
        remaining: Duration(minutes: settings.focusMinutes),
      );
      return;
    }
    final remaining = persisted.endsAt == null
        ? Duration(milliseconds: persisted.remainingMs)
        : persisted.endsAt!.difference(DateTime.now());
    // A session killed while running still has an open focus run. Paused
    // sessions have no open run (the run was already saved when it paused).
    _runStart = persisted.isRunning &&
            persisted.kind == BlockKind.focus
        ? (persisted.runStart ?? persisted.startedAt)
        : null;
    state = PomodoroState(
      settings: settings,
      kind: persisted.kind,
      activityId: persisted.activityId,
      phaseIndex: persisted.phaseIndex,
      remaining: remaining.isNegative ? Duration.zero : remaining,
      running: persisted.isRunning,
      status: persisted.isRunning ? 'Running' : 'Paused',
      startedAt: persisted.startedAt,
    );
    if (remaining.isNegative) await _complete();
  }

  Future<void> selectActivity(String? activityId) async {
    state = state.copyWith(activityId: activityId, status: 'Activity selected');
    await _persist();
  }

  Future<void> selectRound(int round) async {
    if (state.running) {
      state = state.copyWith(status: 'Stop the timer to change round');
      return;
    }
    final total = state.settings.roundsBeforeLongBreak;
    final selected = round.clamp(1, total);
    _runStart = null;
    state = state.copyWith(
      phaseIndex: selected - 1,
      kind: BlockKind.focus,
      remaining: state.settings.durationFor(BlockKind.focus),
      startedAt: null,
      status: 'Round $selected selected',
    );
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
    // A focus run starts sprinkling sand now (real clock time). Breaks are
    // never recorded, so they leave no open run.
    _runStart = state.kind == BlockKind.focus ? DateTime.now() : null;
    await _database.saveTimerState(
      _accountId,
      PersistedTimerState(
        activityId: state.activityId,
        kind: state.kind,
        phaseIndex: state.phaseIndex,
        startedAt: state.startedAt ?? DateTime.now(),
        runStart: _runStart,
        endsAt: endsAt,
        paused: false,
        remainingMs: state.remaining.inMilliseconds,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> pause() async {
    if (!state.running) return;
    // Pausing ends the focus run: sand stops here and the stretch [start, now]
    // is saved as its own block, so the pause leaves a visible gap on the clock.
    await _finalizeRun(DateTime.now());
    state = state.copyWith(running: false, status: 'Paused');
    await _persist();
  }

  Future<void> stop() async {
    // A stop/reset stops sprinkling sand: save whatever is still open.
    await _finalizeRun(DateTime.now());
    _runStart = null;
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
        runStart: _runStart,
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
    // A focus session ending (completed or not) saves its last run. Breaks
    // finalize nothing — break time is never recorded.
    await _finalizeRun(endedAt);
    _runStart = null;
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
      startedAt: endedAt,
      running: state.kind == BlockKind.focus
          ? state.settings.autoStartBreaks
          : state.settings.autoStartFocus,
      status:
          state.kind == BlockKind.focus ? 'Focus complete' : 'Break complete',
    );
    await _persist();
    await notifications?.showPhase(nextKind, (nextIndex % state.settings.roundsBeforeLongBreak) + 1);
    if (state.running) await start();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.cancel();
    super.dispose();
  }
}
