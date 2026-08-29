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

class _ClockScreenState extends ConsumerState<ClockScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _clockKey = GlobalKey();
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Set during [build] so gesture handlers can reuse the current blocks.
  List<TimeBlock> _displayBlocks = const [];
  String? _hoveredId;
  bool _dragActive = false;
  Offset? _dragStart;
  Offset? _dragCurrent;
  ({DateTime start, DateTime end})? _dragRange;
  final Stopwatch _dragWatch = Stopwatch();
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
    _displayBlocks = [
      ...blocks,
      if (liveBlock != null) liveBlock,
    ];

    // Pulse the highlight while anything is hovered or selected.
    final highlightActive = _hoveredId != null || _selectedIds.isNotEmpty;
    if (highlightActive && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!highlightActive && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 0;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('24-hour clock')),
      floatingActionButton:
          _selectedIds.isEmpty && !_dragActive
              ? FloatingActionButton.extended(
                  onPressed: () => _addBlock(account.id),
                  icon: const Icon(Icons.add),
                  label: const Text('New event'),
                )
              : null,
      body: Column(
        children: [
          Expanded(child: _dialArea(account.id, _displayBlocks, activities)),
          if (_selectedIds.isNotEmpty && !_dragActive) _selectionBar(context),
        ],
      ),
    );
  }

  Widget _dialArea(String accountId, List<TimeBlock> blocks,
      List<Activity> activities) {
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
            constraints.maxWidth, math.min(constraints.maxHeight, 520.0));
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: MouseRegion(
              onHover: (event) => _onHover(event.localPosition, blocks),
              onExit: (_) => _onHoverExit(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _openBlockAt(details.localPosition, blocks),
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: (_) => _onPanEnd(),
                onPanCancel: _onPanEnd,
                child: CustomPaint(
                  key: _clockKey,
                  painter: _ClockPainter(
                    blocks: blocks,
                    activities: activities,
                    highlightedId: _hoveredId,
                    selectedIds: _selectedIds,
                    dragRange: _dragRange,
                    pulse: _pulseController,
                    darkMode: darkMode,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Live recording ------------------------------------------------------

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

  // --- Pointer handling ----------------------------------------------------

  void _onHover(Offset position, List<TimeBlock> blocks) {
    final id = _blockAt(position, blocks)?.id;
    if (id != _hoveredId) setState(() => _hoveredId = id);
  }

  void _onHoverExit() {
    if (_hoveredId != null) setState(() => _hoveredId = null);
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragCurrent = details.localPosition;
    _dragRange = null;
    _dragWatch
      ..reset()
      ..start();
    final hadSelection = _selectedIds.isNotEmpty;
    _selectedIds = {};
    _dragActive = true;
    if (hadSelection) setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    _dragCurrent = details.localPosition;
    final start = _timeAt(_dragStart!);
    final current = _timeAt(details.localPosition);
    ({DateTime start, DateTime end})? range;
    if (start != null && current != null) {
      var lo = start, hi = current;
      if (hi.isBefore(lo)) (lo, hi) = (hi, lo);
      range = (start: lo, end: hi);
    }
    setState(() {
      _selectedIds = _blocksInRange(range);
      _dragRange = range;
    });
  }

  void _onPanEnd() {
    final start = _dragStart;
    final current = _dragCurrent;
    final wasQuick = _dragWatch.elapsed < const Duration(milliseconds: 400);
    _dragStart = null;
    _dragCurrent = null;
    _dragRange = null;
    _dragWatch.stop();
    _dragActive = false;
    // A quick gesture is a click with a bit of jitter, not a selection drag:
    // fall back to the tap behaviour so clicks always respond.
    if (wasQuick && start != null && current != null) {
      if (_selectedIds.isNotEmpty) _selectedIds = {};
      setState(() {});
      _openBlockAt(current, _displayBlocks);
      return;
    }
    setState(() {});
  }

  void _openBlockAt(Offset position, List<TimeBlock> blocks) {
    if (_selectedIds.isNotEmpty) {
      // Selection mode: tapping a segment toggles it, tapping elsewhere
      // (or the live arc) clears the selection.
      final found = _blockAt(position, blocks);
      if (found != null && found.id != _liveBlockId) {
        setState(() {
          if (!_selectedIds.add(found.id)) _selectedIds.remove(found.id);
        });
      } else {
        _clearSelection();
      }
      return;
    }
    final found = _blockAt(position, blocks);
    if (found == null) return;
    _openEditor(found);
  }

  /// Maps a dial position to a wall-clock time today, or null when the position
  /// is not inside the ring band.
  DateTime? _timeAt(Offset position) {
    final renderBox = _clockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.shortestSide / 2 - 8;
    final innerRadius = outerRadius * 0.58;
    final band = outerRadius - innerRadius;
    final stroke = band * 0.34;
    final distance = (position - center).distance;
    if (distance > outerRadius + stroke + 14 ||
        distance < innerRadius - stroke - 14) {
      return null;
    }
    final isOuter = distance > (innerRadius + outerRadius) / 2;
    final angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    var fraction = (angle + math.pi / 2) / (2 * math.pi);
    if (fraction < 0) fraction += 1;
    final hour = (isOuter ? 12 : 0) + fraction * 12;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(
      Duration(milliseconds: (hour * Duration.millisecondsPerHour).round()),
    );
  }

  /// Finds the block whose arc covers the tapped spot, with a small tolerance
  /// so thin or short segments respond reliably.
  TimeBlock? _blockAt(Offset position, List<TimeBlock> blocks) {
    final tapped = _timeAt(position);
    if (tapped == null) return null;
    TimeBlock? nearest;
    Duration? nearestGap;
    for (final block in blocks) {
      final start = block.start.toLocal();
      final end = block.end.toLocal();
      if (end.isBefore(start)) continue;
      if (!tapped.isBefore(start) && tapped.isBefore(end)) return block;
      final gap = tapped.isBefore(start)
          ? start.difference(tapped)
          : tapped.difference(end);
      if (nearestGap == null || gap < nearestGap) {
        nearestGap = gap;
        nearest = block;
      }
    }
    if (nearestGap == null || nearestGap > const Duration(minutes: 3)) {
      return null;
    }
    return nearest;
  }

  Set<String> _blocksInRange(({DateTime start, DateTime end})? range) {
    if (range == null) return {};
    final account = ref.read(selectedAccountProvider).value;
    if (account == null) return {};
    final blocks =
        (ref.read(timeBlocksProvider(account.id)).value ?? const <TimeBlock>[])
            .where((block) => !block.deleted);
    return blocks
        .where((block) =>
            block.start.toLocal().isBefore(range.end) &&
            block.end.toLocal().isAfter(range.start))
        .map((block) => block.id)
        .toSet();
  }

  void _clearSelection() => setState(() => _selectedIds = {});

  Future<void> _deleteSelection() async {
    final account = ref.read(selectedAccountProvider).value;
    if (account == null || _selectedIds.isEmpty) return;
    final repository = ref.read(blockRepositoryProvider);
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await repository.delete(account.id, id);
    }
    if (mounted) setState(() => _selectedIds = {});
  }

  Widget _selectionBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Icon(Icons.select_all, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text('${_selectedIds.length} segment(s) selected'),
              const Spacer(),
              TextButton(
                onPressed: _clearSelection,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _deleteSelection,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Editors -------------------------------------------------------------

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
  const _ClockPainter({
    required this.blocks,
    required this.activities,
    this.highlightedId,
    this.selectedIds = const {},
    this.dragRange,
    this.pulse,
    required this.darkMode,
  }) : super(repaint: pulse);

  final List<TimeBlock> blocks;
  final List<Activity> activities;
  final String? highlightedId;
  final Set<String> selectedIds;
  final ({DateTime start, DateTime end})? dragRange;
  final Animation<double>? pulse;
  final bool darkMode;

  /// A highlight that is visible on both light and dark surfaces: dark in light
  /// mode, white in dark mode.
  Color get _haloColor => darkMode ? Colors.white : const Color(0xFF111827);

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
    if (dragRange != null) {
      _drawDragRange(canvas, center, innerRadius, outerRadius, dragRange!);
    }

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
        hovered: block.id == highlightedId && !selectedIds.contains(block.id),
        selected: selectedIds.contains(block.id),
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

  void _drawDragRange(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, ({DateTime start, DateTime end}) range) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerRadius - innerRadius) * 0.55
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0x2EFFFFFF);
    var cursor = range.start;
    while (cursor.isBefore(range.end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd =
          nextMidnight.isBefore(range.end) ? nextMidnight : range.end;
      _drawSegment(
          canvas, center, innerRadius, outerRadius, cursor, segmentEnd, paint);
      cursor = segmentEnd;
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
    required bool hovered,
    required bool selected,
  }) {
    final p = pulse?.value ?? 0.0;
    final width = isLive ? strokeWidth + 2 : strokeWidth;
    if (selected) {
      _strokeSegments(
        canvas,
        center,
        innerRadius,
        outerRadius,
        block,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 12 + p * 10
          ..strokeCap = StrokeCap.butt
          ..color = _haloColor.withValues(alpha: 0.30 + p * 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    } else if (hovered) {
      _strokeSegments(
        canvas,
        center,
        innerRadius,
        outerRadius,
        block,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width + 7 + p * 6
          ..strokeCap = StrokeCap.butt
          ..color = _haloColor.withValues(alpha: 0.22 + p * 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    _strokeSegments(
      canvas,
      center,
      innerRadius,
      outerRadius,
      block,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
  }

  void _strokeSegments(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, TimeBlock block, Paint paint) {
    var cursor = block.start.toLocal();
    final end = block.end.toLocal();
    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
      _drawSegment(
          canvas, center, innerRadius, outerRadius, cursor, segmentEnd, paint);
      cursor = segmentEnd;
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

  @override
  bool shouldRepaint(_ClockPainter oldDelegate) =>
      oldDelegate.blocks != blocks ||
      oldDelegate.activities != activities ||
      oldDelegate.highlightedId != highlightedId ||
      oldDelegate.selectedIds != selectedIds ||
      oldDelegate.dragRange != dragRange ||
      oldDelegate.darkMode != darkMode;
}
