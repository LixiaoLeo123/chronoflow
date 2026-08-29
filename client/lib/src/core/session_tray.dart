import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../features/pomodoro/pomodoro_controller.dart';
import '../models/domain.dart';

class SessionTrayController {
  SessionTrayController();

  bool _visible = false;

  Future<void> update(PomodoroState state) async {
    if (!Platform.isLinux) return;
    final asset = switch (state.kind) {
      BlockKind.focus => 'assets/tray/tray_focus.png',
      BlockKind.shortBreak => 'assets/tray/tray_break.png',
      BlockKind.longBreak => 'assets/tray/tray_long.png',
    };
    await trayManager.setIcon(asset);
    await trayManager.setToolTip(
      state.running
          ? 'Chronoflow — ${_label(state.kind)} ${_remaining(state.remaining)}'
          : 'Chronoflow — paused ${_remaining(state.remaining)}',
    );
    _visible = true;
  }

  Future<void> dispose() async {
    if (!Platform.isLinux || !_visible) return;
    await trayManager.destroy();
  }
}

String _label(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'Focus',
      BlockKind.shortBreak => 'Break',
      BlockKind.longBreak => 'Long break',
    };

String _remaining(Duration duration) {
  final minutes = duration.inMinutes.clamp(0, 999).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
