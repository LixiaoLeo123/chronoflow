import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/domain.dart';
import '../../providers.dart';
import '../pomodoro/pomodoro_controller.dart';

const _liveBlockId = 'chronoflow-live-timer';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  final GlobalKey _clockKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedAccountProvider).value;
    if (account == null) return const SizedBox.shrink();
    final activities =
        ref.watch(activitiesProvider(account.id)).value ?? const <Activity>[];
    final blocks =
        (ref.watch(timeBlocksProvider(account.id)).value ?? const <TimeBlock>[])
            .where((block) => !block.deleted)
            .toList();
    final timer = ref.watch(pomodoroProvider(account.id));
    final liveBlock = _liveBlock(timer, account.id, activities);
    final displayBlocks = [
      ...blocks,
      if (liveBlock != null) liveBlock,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('24-hour clock')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBlock(account.id),
        icon: const Icon(Icons.add),
        label: const Text('New event'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(
              constraints.maxWidth, math.min(constraints.maxHeight, 520.0));
          return Center(
            child: SizedBox(
              width: side,
              height: side,
              child: GestureDetector(
                onTapUp: (details) =>
                    _openBlockAt(details.localPosition, displayBlocks),
                child: CustomPaint(
                  key: _clockKey,
                  painter: _ClockPainter(
                    blocks: displayBlocks,
                    activities: activities,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The live recording of the running focus timer: sand is laid at the real
  /// current time while the focus timer runs, so the arc spans [run start, now]
  /// and grows in real time. Pausing ends the run (it was saved as a block), so
  /// there is no live arc while paused or on a break.
  TimeBlock? _liveBlock(
      PomodoroState timer, String accountId, List<Activity> activities) {
    if (!timer.running || timer.kind != BlockKind.focus) return null;
    final startedAt = timer.startedAt;
    if (startedAt == null) return null;
    final activityId = timer.activityId;
    if (activityId == null) return null;
    if (!activities
        .any((item) => item.id == activityId && !item.deleted && !item.archived)) {
      return null;
    }
    final controller = ref.read(pomodoroProvider(accountId).notifier);
    final runStart = controller.liveAnchorStart ?? startedAt;
    final now = DateTime.now();
    if (!now.isAfter(runStart)) return null;
    return TimeBlock(
      id: _liveBlockId,
      accountId: '',
      activityId: activityId,
      kind: BlockKind.focus,
      start: runStart,
      end: now,
      status: BlockStatus.active,
      deleted: false,
      createdAt: startedAt,
      updatedAt: now,
    );
  }

  void _openBlockAt(Offset position, List<TimeBlock> blocks) {
    final found = _blockAt(position, blocks);
    if (found == null) return;
    _openEditor(found);
  }

  /// Finds the block whose arc covers the tapped spot. The clock is two rings:
  /// inner = 00:00–12:00, outer = 12:00–24:00.
  TimeBlock? _blockAt(Offset position, List<TimeBlock> blocks) {
    final renderBox = _clockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 8;
    final innerRadius = outerRadius * 0.58;
    final band = outerRadius - innerRadius;
    final stroke = band * 0.34;
    final distance = (position - center).distance;
    if (distance > outerRadius + stroke + 10 ||
        distance < innerRadius - stroke - 10) {
      return null;
    }
    final isOuter = distance > (innerRadius + outerRadius) / 2;
    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    var fraction = (angle + math.pi / 2) / (2 * math.pi);
    if (fraction < 0) fraction += 1;
    final hour = (isOuter ? 12 : 0) + fraction * 12;
    final now = DateTime.now();
    final tapped = DateTime(now.year, now.month, now.day).add(
      Duration(milliseconds: (hour * Duration.millisecondsPerHour).round()),
    );
    return blocks
        .where((block) =>
            !tapped.isBefore(block.start.toLocal()) &&
            tapped.isBefore(block.end.toLocal()))
        .firstOrNull;
  }

  Future<void> _openEditor(TimeBlock block) async {
    final account = ref.read(selectedAccountProvider).value;
    if (account == null) return;
    if (block.id == _liveBlockId) {
      await _showLiveEditor(account.id);
      return;
    }
    await _showBlockEditor(context: context, accountId: account.id, block: block);
  }

  Future<void> _addBlock(String accountId) =>
      _showBlockEditor(context: context, accountId: accountId, block: null);

  Future<void> _showLiveEditor(String accountId) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Live recording',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
                'This arc records the running focus timer. Deleting it cuts '
                'the recording here — it keeps growing from this moment.'),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext, 'delete'),
                  child: const Text('Delete & keep recording'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  child: const Text('Close'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    if (result != 'delete') return;
    ref.read(pomodoroProvider(accountId).notifier).reanchorLive();
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Live recording cut — the arc keeps growing from now.'),
      ));
    }
  }

  Future<void> _showBlockEditor({
    required BuildContext context,
    required String accountId,
    TimeBlock? block,
  }) async {
    final activities =
        (ref.read(activitiesProvider(accountId)).value ?? const <Activity>[])
            .where((item) => !item.deleted)
            .toList();
    var start = block?.start.toLocal() ?? _defaultStart();
    var end = block?.end.toLocal() ?? start.add(const Duration(minutes: 25));
    var activityId = block?.activityId ?? activities.firstOrNull?.id ?? '';
    var kind = block?.kind ?? BlockKind.focus;
    final saved = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(block == null ? 'New event' : 'Edit event',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: activityId,
                decoration: const InputDecoration(labelText: 'Activity'),
                items: [
                  for (final activity in activities)
                    DropdownMenuItem(
                        value: activity.id, child: Text(activity.name)),
                ],
                onChanged: (String? value) =>
                    setState(() => activityId = value ?? activityId),
              ),
              if (activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Create a thing on the Things tab first.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 12),
              SegmentedButton<BlockKind>(
                segments: const [
                  ButtonSegment(value: BlockKind.focus, label: Text('Focus')),
                  ButtonSegment(
                      value: BlockKind.shortBreak, label: Text('Short')),
                  ButtonSegment(
                      value: BlockKind.longBreak, label: Text('Long')),
                ],
                selected: {kind},
                onSelectionChanged: (value) =>
                    setState(() => kind = value.first),
              ),
              const SizedBox(height: 12),
              Text('Start: ${TimeOfDay.fromDateTime(start).format(context)}'),
              Slider(
                value: _minuteOfDay(start).toDouble(),
                min: 0,
                max: 1435,
                divisions: 287,
                onChanged: (value) => setState(() {
                  final day = DateTime(start.year, start.month, start.day);
                  start = day.add(Duration(minutes: value.round()));
                  if (!end.isAfter(start)) {
                    end = start.add(const Duration(minutes: 5));
                  }
                }),
              ),
              Text('End: ${TimeOfDay.fromDateTime(end).format(context)}'),
              Slider(
                value: _minuteOfDay(end).toDouble(),
                min: 0,
                max: 1440,
                divisions: 288,
                onChanged: (value) => setState(() {
                  final day = DateTime(start.year, start.month, start.day);
                  end = day.add(Duration(minutes: value.round()));
                  if (!end.isAfter(start)) {
                    end = start.add(const Duration(minutes: 5));
                  }
                }),
              ),
              const SizedBox(height: 16),
              Row(children: [
                if (block != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, 'delete'),
                      child: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: activityId.isEmpty
                        ? null
                        : () => Navigator.pop(sheetContext, true),
                    child: const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (saved == 'delete' && block != null) {
      await ref.read(blockRepositoryProvider).delete(accountId, block.id);
      return;
    }
    if (saved != true) return;
    try {
      final newBlock = block == null
          ? TimeBlock(
              id: const Uuid().v7(),
              accountId: accountId,
              activityId: activityId,
              kind: kind,
              start: start.toUtc(),
              end: end.toUtc(),
              status: BlockStatus.completed,
              deleted: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          : block.copyWith(
              activityId: activityId,
              kind: kind,
              start: start.toUtc(),
              end: end.toUtc(),
              deleted: false,
              updatedAt: DateTime.now(),
            );
      await ref.read(blockRepositoryProvider).save(newBlock);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

int _minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

DateTime _defaultStart() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, now.hour + 1);
}

class _ClockPainter extends CustomPainter {
  const _ClockPainter({required this.blocks, required this.activities});

  final List<TimeBlock> blocks;
  final List<Activity> activities;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 8;
    final innerRadius = outerRadius * 0.58;
    final band = outerRadius - innerRadius;
    final strokeWidth = band * 0.34;

    _drawTrack(canvas, center, innerRadius, outerRadius, strokeWidth);
    _drawTicks(canvas, center, innerRadius, outerRadius, strokeWidth);
    _drawLabels(canvas, center, innerRadius, outerRadius);

    for (final block in blocks) {
      _drawBlock(
        canvas,
        center,
        innerRadius,
        outerRadius,
        strokeWidth,
        block,
        _blockColor(block),
        isLive: block.id == _liveBlockId,
      );
    }
  }

  Color _blockColor(TimeBlock block) {
    if (block.kind == BlockKind.focus) {
      final color = activities
          .where((activity) => activity.id == block.activityId)
          .map((activity) => activity.color)
          .firstOrNull;
      return color != null ? Color(color) : const Color(0xFF64748B);
    }
    return const Color(0xFF94A3B8);
  }

  void _drawTrack(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, double strokeWidth) {
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0x3364748B);
    canvas.drawCircle(center, outerRadius, track);
    canvas.drawCircle(center, innerRadius, track);
  }

  void _drawTicks(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, double strokeWidth) {
    final tick = Paint()
      ..color = const Color(0x40A0AEC0)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var hour = 0; hour < 24; hour++) {
      final angle = _hourAngle(hour);
      final radius = hour < 12 ? innerRadius : outerRadius;
      final dir = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + dir * (radius - strokeWidth / 2),
        center + dir * (radius + strokeWidth / 2),
        tick,
      );
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double innerRadius,
      double outerRadius) {
    final band = outerRadius - innerRadius;
    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var hour = 0; hour < 24; hour += 2) {
      final angle = _hourAngle(hour);
      final radius = hour < 12
          ? innerRadius + band * 0.24
          : innerRadius + band * 0.76;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      labelPainter.text = TextSpan(
        text: hour.toString().padLeft(2, '0'),
        style: const TextStyle(color: Color(0xFF8892A6), fontSize: 11),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        point - Offset(labelPainter.width / 2, labelPainter.height / 2),
      );
    }
  }

  void _drawBlock(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    double strokeWidth,
    TimeBlock block,
    Color color, {
    required bool isLive,
  }) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isLive ? strokeWidth + 2 : strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = color;
    var cursor = block.start.toLocal();
    final end = block.end.toLocal();
    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
      _drawSegment(
          canvas, center, innerRadius, outerRadius, cursor, segmentEnd, paint);
      cursor = segmentEnd;
    }
    if (isLive) {
      final angle = _angleFor(end);
      final ring = end.hour < 12 ? innerRadius : outerRadius;
      final head = center + Offset(math.cos(angle), math.sin(angle)) * ring;
      canvas.drawCircle(head, strokeWidth / 2 + 2, Paint()..color = color);
    }
  }

  void _drawSegment(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, DateTime start, DateTime end, Paint paint) {
    for (final piece in _splitAtNoon(start, end)) {
      final inner = piece.$1.hour < 12;
      final radius = inner ? innerRadius : outerRadius;
      final startAngle =
          _fractionOnRing(piece.$1, inner) * 2 * math.pi - math.pi / 2;
      final sweep =
          (_fractionOnRing(piece.$2, inner) - _fractionOnRing(piece.$1, inner)) *
              2 *
              math.pi;
      if (sweep <= 0) continue;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
    }
  }

  List<(DateTime, DateTime)> _splitAtNoon(DateTime start, DateTime end) {
    final day = DateTime(start.year, start.month, start.day);
    final noon = day.add(const Duration(hours: 12));
    if (!start.isBefore(noon) || !end.isAfter(noon)) return [(start, end)];
    return [(start, noon), (noon, end)];
  }

  /// Fraction of the full ring (0..1) a moment occupies. The inner ring runs
  /// 00:00→12:00, the outer ring 12:00→24:00, both starting at the top.
  double _fractionOnRing(DateTime time, bool inner) {
    final minutes = time.hour * 60 + time.minute;
    if (inner) return minutes / 720;
    final m = minutes < 720 ? minutes + 1440 : minutes;
    return (m - 720) / 720;
  }

  double _hourAngle(int hour) {
    final frac = hour < 12 ? hour / 12 : (hour - 12) / 12;
    return frac * 2 * math.pi - math.pi / 2;
  }

  double _angleFor(DateTime time) {
    final inner = time.hour < 12;
    return _fractionOnRing(time, inner) * 2 * math.pi - math.pi / 2;
  }

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) =>
      oldDelegate.blocks != blocks || oldDelegate.activities != activities;
}
