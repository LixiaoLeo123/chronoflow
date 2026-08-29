import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

import '../features/pomodoro/pomodoro_controller.dart';
import '../models/domain.dart';

/// Draws the mini clock in the system tray: the same progress ring as the
/// Pomodoro page, coloured differently for focus / short break / long break.
///
/// The icon is rendered to a PNG at runtime so the ring can show progress.
/// If rendering fails (e.g. in a sandboxed environment), it falls back to the
/// bundled static per-kind icons so the tray never silently disappears.
class SessionTrayController {
  SessionTrayController();

  bool _visible = false;
  BlockKind? _lastKind;
  bool _lastRunning = false;
  int _lastPercent = -1;
  bool _dynamicFailed = false;

  Future<void> update(PomodoroState state) async {
    if (!Platform.isLinux) return;
    final full = state.settings.durationFor(state.kind);
    final progress = full.inMilliseconds == 0
        ? 0.0
        : (1 - state.remaining.inMilliseconds / full.inMilliseconds)
            .clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    // Re-render the icon only when something visually meaningful changed, so
    // the panel icon does not flicker on every second tick.
    if (!_visible ||
        _lastKind != state.kind ||
        _lastRunning != state.running ||
        _lastPercent != percent) {
      _lastKind = state.kind;
      _lastRunning = state.running;
      _lastPercent = percent;
      try {
        final bytes = _dynamicFailed
            ? null
            : await _renderRing(state.kind, progress);
        if (bytes != null) {
          final file = File('${Directory.systemTemp.path}/chronoflow_tray.png');
          await file.writeAsBytes(bytes);
          await trayManager.setIcon(file.path);
        } else {
          await trayManager.setIcon(_assetFor(state.kind));
        }
      } catch (_) {
        _dynamicFailed = true;
        try {
          await trayManager.setIcon(_assetFor(state.kind));
        } catch (_) {
          // Give up quietly; keep the previous icon on transient failures.
        }
      }
      _visible = true;
    }

    // setIcon above creates the indicator; only then is a tooltip safe.
    await trayManager.setToolTip(
      state.running
          ? 'Chronoflow — ${_label(state.kind)} ${_remaining(state.remaining)}'
          : 'Chronoflow — paused ${_remaining(state.remaining)}',
    );
  }

  Future<void> dispose() async {
    if (!Platform.isLinux || !_visible) return;
    await trayManager.destroy();
  }
}

String _assetFor(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'assets/tray/tray_focus.png',
      BlockKind.shortBreak => 'assets/tray/tray_break.png',
      BlockKind.longBreak => 'assets/tray/tray_long.png',
    };

Future<Uint8List?> _renderRing(BlockKind kind, double progress) async {
  const size = 128.0;
  const stroke = 12.0;
  const center = Offset(size / 2, size / 2);
  const radius = size / 2 - stroke / 2 - 3;
  final color = _kindColor(kind);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  // A clearly visible track so the idle (0%) ring is still easy to spot.
  final track = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..color = color.withValues(alpha: 0.5);
  canvas.drawCircle(center, radius, track);

  if (progress > 0.004) {
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      progress * 2 * math.pi,
      false,
      arc,
    );
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData?.buffer.asUint8List();
}

Color _kindColor(BlockKind kind) => switch (kind) {
      BlockKind.focus => const Color(0xFF3080F0),
      BlockKind.shortBreak => const Color(0xFF90A0B0),
      BlockKind.longBreak => const Color(0xFF20D0B0),
    };

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
