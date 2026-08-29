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
class SessionTrayController {
  SessionTrayController();

  bool _visible = false;
  BlockKind? _lastKind;
  bool _lastRunning = false;
  int _lastPercent = -1;

  Future<void> update(PomodoroState state) async {
    if (!Platform.isLinux) return;
    final full = state.settings.durationFor(state.kind);
    final progress = full.inMilliseconds == 0
        ? 0.0
        : (1 - state.remaining.inMilliseconds / full.inMilliseconds)
            .clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    await trayManager.setToolTip(
      state.running
          ? 'Chronoflow — ${_label(state.kind)} ${_remaining(state.remaining)}'
          : 'Chronoflow — paused ${_remaining(state.remaining)}',
    );

    // Re-render the icon only when something visually meaningful changed, so
    // the panel icon does not flicker on every second tick.
    if (_visible &&
        _lastKind == state.kind &&
        _lastRunning == state.running &&
        _lastPercent == percent) {
      return;
    }
    _lastKind = state.kind;
    _lastRunning = state.running;
    _lastPercent = percent;
    try {
      final file = File('${Directory.systemTemp.path}/chronoflow_tray.png');
      await file.writeAsBytes(await _renderRing(state.kind, progress));
      await trayManager.setIcon(file.path);
    } catch (_) {
      // Keep the previous icon on transient failures (e.g. sandboxed FS).
    }
    _visible = true;
  }

  Future<void> dispose() async {
    if (!Platform.isLinux || !_visible) return;
    await trayManager.destroy();
  }
}

Future<Uint8List> _renderRing(BlockKind kind, double progress) async {
  const size = 128.0;
  const stroke = 13.0;
  const center = Offset(size / 2, size / 2);
  const radius = size / 2 - stroke / 2 - 4;
  final color = _kindColor(kind);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final track = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..color = color.withValues(alpha: 0.22);
  canvas.drawCircle(center, radius, track);

  if (progress > 0.002) {
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
    final headAngle = -math.pi / 2 + progress * 2 * math.pi;
    final head = center +
        Offset(math.cos(headAngle), math.sin(headAngle)) * radius;
    canvas.drawCircle(head, stroke / 2 + 1.5, Paint()..color = color);
  }

  final picture = recorder.endRecording();
  final image = picture.toImageSync(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
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
