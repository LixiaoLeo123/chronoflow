import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/domain.dart';
import '../../providers.dart';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  String? _selectedId;

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
    final selected =
        blocks.where((block) => block.id == _selectedId).firstOrNull;
    final activeActivities = activities.where((item) => !item.deleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('24-hour clock')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final timeline = AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onTapUp: (details) => _selectAt(details.localPosition, blocks),
              child: CustomPaint(
                painter: _TwoRingClockPainter(
                    blocks: blocks, activities: activities),
              ),
            ),
          );
          final details = selected == null
              ? const Card(
                  margin: EdgeInsets.all(16),
                  child: ListTile(title: Text('Tap a block to edit it')),
                )
              : Card(
                  margin: const EdgeInsets.all(16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Color(
                          _activityColor(activities, selected.activityId)),
                    ),
                    title: Text(_kindLabel(selected.kind)),
                    subtitle: Text(
                      '${TimeOfDay.fromDateTime(selected.start.toLocal()).format(context)}'
                      '–${TimeOfDay.fromDateTime(selected.end.toLocal()).format(context)}',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _editBlock(selected, activeActivities),
                      child: const Text('Edit'),
                    ),
                  ),
                );
          if (!wide) {
            return ListView(children: [timeline, details]);
          }
          return Row(children: [
            Expanded(child: timeline),
            SizedBox(width: 420, child: details),
          ]);
        },
      ),
    );
  }

  void _selectAt(Offset position, List<TimeBlock> blocks) {
    final painterSize = context.size;
    if (painterSize == null) return;
    final center = Offset(painterSize.width / 2, painterSize.height / 2);
    final distance = (position - center).distance;
    final outerRadius = painterSize.shortestSide / 2 - 8;
    final innerRadius = outerRadius * 0.58;
    final isOuter = distance > (outerRadius + innerRadius) / 2;
    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    var fraction = (angle + math.pi / 2) / (2 * math.pi);
    if (fraction < 0) fraction += 1;
    final hour = (isOuter ? 12 : 0) + fraction * 12;
    final now = DateTime.now();
    final tapped = DateTime(now.year, now.month, now.day).add(
      Duration(milliseconds: (hour * Duration.millisecondsPerHour).round()),
    );
    final found = blocks
        .where(
          (block) =>
              !tapped.isBefore(block.start.toLocal()) &&
              tapped.isBefore(block.end.toLocal()),
        )
        .firstOrNull;
    setState(() => _selectedId = found?.id);
  }

  Future<void> _editBlock(TimeBlock block, List<Activity> activities) async {
    ref.read(selectedAccountProvider);
    var start = block.start.toLocal();
    var end = block.end.toLocal();
    var activityId = block.activityId;
    var kind = block.kind;
    final saved = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: activityId,
                decoration: const InputDecoration(labelText: 'Activity'),
                items: [
                  for (final activity in activities)
                    DropdownMenuItem(
                        value: activity.id, child: Text(activity.name)),
                ],
                onChanged: (String? value) =>
                    setState(() => activityId = value ?? block.activityId),
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
                selected: <BlockKind>{kind},
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
                }),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, 'delete'),
                    child: const Text('Delete'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Save'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (saved == 'delete') {
      await ref.read(blockRepositoryProvider).delete(block.accountId, block.id);
      if (mounted) setState(() => _selectedId = null);
      return;
    }
    if (saved != true) return;
    try {
      await ref.read(blockRepositoryProvider).save(
            block.copyWith(
              activityId: activityId,
              kind: kind,
              start: start.toUtc(),
              end: end.toUtc(),
              deleted: false,
              updatedAt: DateTime.now(),
            ),
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}

int _minuteOfDay(DateTime value) => value.hour * 60 + value.minute;

String _kindLabel(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'Focus',
      BlockKind.shortBreak => 'Short break',
      BlockKind.longBreak => 'Long break',
    };

int _activityColor(List<Activity> activities, String id) =>
    activities
        .where((activity) => activity.id == id)
        .map((activity) => activity.color)
        .firstOrNull ??
    0xFF64748B;

class _TwoRingClockPainter extends CustomPainter {
  const _TwoRingClockPainter({required this.blocks, required this.activities});

  final List<TimeBlock> blocks;
  final List<Activity> activities;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 8;
    final innerRadius = outerRadius * 0.58;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x33808080);
    canvas.drawCircle(center, outerRadius, track);
    canvas.drawCircle(center, innerRadius, track);
    canvas.drawCircle(
        center, (outerRadius + innerRadius) / 2, track..strokeWidth = 1);

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var hour = 0; hour < 24; hour += 2) {
      final angle = ((hour % 12) / 12) * 2 * math.pi - math.pi / 2;
      final radius = hour < 12 ? innerRadius : outerRadius;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      labelPainter.text = TextSpan(
        text: hour.toString().padLeft(2, '0'),
        style: const TextStyle(color: Color(0xFF8892A6), fontSize: 11),
      );
      labelPainter.layout();
      labelPainter.paint(canvas,
          point - Offset(labelPainter.width / 2, labelPainter.height / 2));
    }

    for (final block in blocks) {
      final color = activities
              .where((activity) => activity.id == block.activityId)
              .map((activity) => activity.color)
              .firstOrNull ??
          0xFF64748B;
      final paint = Paint()
        ..color = Color(block.kind == BlockKind.focus ? color : 0xFF94A3B8);
      _drawBlockSegments(
          canvas, center, innerRadius, outerRadius, block, paint);
    }
  }

  void _drawBlockSegments(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    TimeBlock block,
    Paint paint,
  ) {
    var cursor = block.start.toLocal();
    final end = block.end.toLocal();
    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
      _drawSegment(
        canvas,
        center,
        innerRadius,
        outerRadius,
        cursor,
        segmentEnd,
        paint,
      );
      cursor = segmentEnd;
    }
  }

  void _drawSegment(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double outerRadius,
    DateTime start,
    DateTime end,
    Paint paint,
  ) {
    for (final piece in _splitAtNoon(start, end)) {
      final inner = piece.$1.hour < 12;
      final radius = inner ? innerRadius : outerRadius;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startFraction = ((piece.$1.hour % 12) * 60 + piece.$1.minute) / 720;
      final endFraction = ((piece.$2.hour % 12) * 60 + piece.$2.minute) / 720;
      final startAngle = startFraction * 2 * math.pi - math.pi / 2;
      final sweep = (endFraction - startFraction) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweep, true, paint);
    }
  }

  List<(DateTime, DateTime)> _splitAtNoon(DateTime start, DateTime end) {
    final day = DateTime(start.year, start.month, start.day);
    final noon = day.add(const Duration(hours: 12));
    if (!start.isBefore(noon) || !end.isAfter(noon)) return [(start, end)];
    return [(start, noon), (noon, end)];
  }

  @override
  bool shouldRepaint(_TwoRingClockPainter oldDelegate) =>
      oldDelegate.blocks != blocks || oldDelegate.activities != activities;
}
