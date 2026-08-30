import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);
  Ticker? _growTicker;
  final Map<String, double> _grow = {};

  /// Set during [build] so gesture handlers can reuse the current blocks.
  List<TimeBlock> _displayBlocks = const [];
  String? _hoveredId;

  bool _selectMode = false;
  bool _dragActive = false;
  Offset? _dragStart;
  Offset? _dragCurrent;
  bool _dragOuter = false;
  double? _dragStartAngle;
  double _dragEndAngle = 0;
  int _dragDir = 0;
  double _sweptMax = 0;
  final Stopwatch _dragWatch = Stopwatch();
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _growTicker?.dispose();
    _repaint.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('24-hour clock'),
        actions: [
          IconButton(
            tooltip: _selectMode ? 'Stop selecting' : 'Select segments',
            icon: Icon(_selectMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectMode,
          ),
        ],
      ),
      floatingActionButton: !_selectMode && !_dragActive
          ? FloatingActionButton.extended(
              onPressed: () => _addBlock(account.id),
              icon: const Icon(Icons.add),
              label: const Text('New event'),
            )
          : null,
      body: Column(
        children: [
          Expanded(child: _dialArea(account.id, _displayBlocks, activities)),
          if (_selectMode && _selectedIds.isNotEmpty && !_dragActive)
            _selectionBar(context),
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
                    grow: _grow,
                    dragOuter: _dragOuter,
                    dragStartAngle: _dragStartAngle,
                    dragEndAngle: _dragEndAngle,
                    darkMode: darkMode,
                    repaint: _repaint,
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

  // --- Selection mode ------------------------------------------------------

  void _toggleSelectMode() {
    setState(() {
      _selectMode = !_selectMode;
      if (!_selectMode) _selectedIds = {};
    });
    _ensureGrowTicker();
  }

  void _ensureGrowTicker() {
    _growTicker ??= createTicker(_tickGrow)..start();
  }

  void _tickGrow(Duration _) {
    final targets = <String, double>{
      for (final block in _displayBlocks)
        block.id: _selectedIds.contains(block.id)
            ? 1.0
            : (block.id == _hoveredId ? 0.35 : 0.0),
    };
    var settling = true;
    for (final MapEntry(:key, :value) in targets.entries) {
      final current = _grow[key] ?? 0.0;
      final next = current + (value - current) * 0.25;
      if ((next - value).abs() > 0.004) settling = false;
      _grow[key] = next;
    }
    final stale = _grow.keys
        .where((id) => !targets.containsKey(id))
        .toList();
    for (final id in stale) {
      final next = (_grow[id] ?? 0.0) * 0.75;
      if (next.abs() < 0.004) {
        _grow.remove(id);
      } else {
        _grow[id] = next;
        settling = false;
      }
    }
    _repaint.value++;
    if (settling) {
      _growTicker?.stop();
      _growTicker?.dispose();
      _growTicker = null;
    }
  }

  // --- Pointer handling ----------------------------------------------------

  void _onHover(Offset position, List<TimeBlock> blocks) {
    final id = _blockAt(position, blocks)?.id;
    if (id != _hoveredId) {
      setState(() => _hoveredId = id);
      _ensureGrowTicker();
    }
  }

  void _onHoverExit() {
    if (_hoveredId != null) {
      setState(() => _hoveredId = null);
      _ensureGrowTicker();
    }
  }

  void _onPanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _dragCurrent = details.localPosition;
    _dragDir = 0;
    _sweptMax = 0;
    _dragEndAngle = 0;
    _dragStartAngle = _dialAngleAt(details.localPosition);
    _dragOuter = _isOuterAt(details.localPosition);
    _dragWatch
      ..reset()
      ..start();
    final hadSelection = _selectedIds.isNotEmpty;
    _selectedIds = {};
    _dragActive = true;
    if (hadSelection || _selectMode) setState(() {});
    if (_selectMode) _ensureGrowTicker();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_dragStart == null) return;
    _dragCurrent = details.localPosition;
    final startAngle = _dragStartAngle;
    if (startAngle == null) return;
    final currentAngle = _dialAngleAt(details.localPosition);
    if (currentAngle == null) return;
    var delta = currentAngle - startAngle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    // Lock the sweep direction on the first meaningful movement, then keep the
    // arc on that side of the starting point (wrap-safe).
    if (_dragDir == 0 && delta.abs() > 0.03) {
      _dragDir = delta > 0 ? 1 : -1;
    }
    if (_dragDir != 0) {
      final progress = _dragDir * delta;
      if (progress > _sweptMax) _sweptMax = progress;
      _dragEndAngle = startAngle + _dragDir * _sweptMax;
    }
    setState(() {
      _selectedIds = _blocksInDragRange();
    });
    if (_selectMode) _ensureGrowTicker();
  }

  void _onPanEnd() {
    final wasQuick = _dragWatch.elapsed < const Duration(milliseconds: 400);
    final current = _dragCurrent;
    _dragStart = null;
    _dragCurrent = null;
    _dragStartAngle = null;
    _dragEndAngle = 0;
    _sweptMax = 0;
    _dragWatch.stop();
    _dragActive = false;
    if (wasQuick && current != null) {
      // A click with a bit of jitter: behave like a tap.
      setState(() {});
      _openBlockAt(current, _displayBlocks);
      return;
    }
    setState(() {});
    if (_selectMode) _ensureGrowTicker();
  }

  void _openBlockAt(Offset position, List<TimeBlock> blocks) {
    if (_selectMode) {
      final found = _blockAt(position, blocks);
      if (found != null && found.id != _liveBlockId) {
        setState(() {
          if (!_selectedIds.add(found.id)) _selectedIds.remove(found.id);
        });
        _ensureGrowTicker();
      } else {
        _clearSelection();
      }
      return;
    }
    final found = _blockAt(position, blocks);
    if (found == null) return;
    _openEditor(found);
  }

  Set<String> _blocksInDragRange() {
    final startAngle = _dragStartAngle;
    if (startAngle == null || _sweptMax <= 0.001) return {};
    final endAngle = _dragEndAngle;
    final lo = math.min(startAngle, endAngle);
    final hi = math.max(startAngle, endAngle);
    final fullRing = _sweptMax >= 2 * math.pi - 0.01;
    final account = ref.read(selectedAccountProvider).value;
    if (account == null) return {};
    final blocks =
        (ref.read(timeBlocksProvider(account.id)).value ?? const <TimeBlock>[])
            .where((block) => !block.deleted);
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final selected = <String>{};
    for (final block in blocks) {
      if (block.id == _liveBlockId) continue;
      final arc = _blockArcOnRing(block, _dragOuter, dayStart);
      if (arc == null) continue;
      if (fullRing || _arcsOverlap(lo, hi, arc.start, arc.end)) {
        selected.add(block.id);
      }
    }
    return selected;
  }

  /// The block's visible arc (in radians, clockwise from the top of the dial)
  /// on the [outer] ring of today, or null when the block doesn't touch it.
  ({double start, double end})? _blockArcOnRing(
      TimeBlock block, bool outer, DateTime dayStart) {
    final ringStart =
        outer ? dayStart.add(const Duration(hours: 12)) : dayStart;
    final ringEnd = ringStart.add(const Duration(hours: 12));
    final s = block.start.toLocal();
    final e = block.end.toLocal();
    if (!e.isAfter(s) || e.isBefore(ringStart) || s.isAfter(ringEnd)) return null;
    final a = s.isAfter(ringStart) ? s : ringStart;
    final b = e.isBefore(ringEnd) ? e : ringEnd;
    if (!b.isAfter(a)) return null;
    final amin = a.difference(ringStart).inMilliseconds / 60000.0;
    final bmin = b.difference(ringStart).inMilliseconds / 60000.0;
    return (start: amin / 720.0 * 2 * math.pi, end: bmin / 720.0 * 2 * math.pi);
  }

  bool _arcsOverlap(double lo, double hi, double a, double b) {
    for (final k in [-1, 0, 1]) {
      final a2 = a + k * 2 * math.pi;
      final b2 = b + k * 2 * math.pi;
      if (a2 < hi && b2 > lo) return true;
    }
    return false;
  }

  void _clearSelection() {
    setState(() => _selectedIds = {});
    _ensureGrowTicker();
  }

  Future<void> _deleteSelection() async {
    final account = ref.read(selectedAccountProvider).value;
    if (account == null || _selectedIds.isEmpty) return;
    final repository = ref.read(blockRepositoryProvider);
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await repository.delete(account.id, id);
    }
    if (mounted) setState(() => _selectedIds = {});
    if (mounted) _ensureGrowTicker();
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
              Text('${_selectedIds.length} segment(s)'),
              const Spacer(),
              TextButton(
                onPressed: _toggleSelectMode,
                child: const Text('Done'),
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

  // --- Geometry helpers ----------------------------------------------------

  /// The dial size and metrics from the painted ring.
  ({Size size, Offset center, double outer, double inner})? _metrics() {
    final renderBox = _clockKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;
    final size = renderBox.size;
    final outer = size.shortestSide / 2 - 8;
    return (
      size: size,
      center: Offset(size.width / 2, size.height / 2),
      outer: outer,
      inner: outer * 0.58,
    );
  }

  /// Position angle in radians, clockwise from the top of the dial, [0, 2π).
  double? _dialAngleAt(Offset position) {
    final m = _metrics();
    if (m == null) return null;
    return (math.atan2(position.dy - m.center.dy, position.dx - m.center.dx) +
            math.pi / 2 +
            2 * math.pi) %
        (2 * math.pi);
  }

  bool _isOuterAt(Offset position) {
    final m = _metrics();
    if (m == null) return false;
    final d = (position - m.center).distance;
    return d > (m.inner + m.outer) / 2;
  }

  /// Maps a dial position to a wall-clock time today, or null when the position
  /// is not inside the ring band.
  DateTime? _timeAt(Offset position) {
    final m = _metrics();
    if (m == null) return null;
    final band = m.outer - m.inner;
    final stroke = band * 0.34;
    final distance = (position - m.center).distance;
    if (distance > m.outer + stroke + 14 ||
        distance < m.inner - stroke - 14) {
      return null;
    }
    final isOuter = distance > (m.inner + m.outer) / 2;
    final angle = _dialAngleAt(position);
    if (angle == null) return null;
    final fraction = angle / (2 * math.pi);
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
    this.grow = const {},
    this.dragOuter = false,
    this.dragStartAngle,
    this.dragEndAngle = 0,
    required this.darkMode,
    super.repaint,
  });

  final List<TimeBlock> blocks;
  final List<Activity> activities;
  final String? highlightedId;
  final Set<String> selectedIds;
  final Map<String, double> grow;
  final bool dragOuter;
  final double? dragStartAngle;
  final double dragEndAngle;
  final bool darkMode;

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
    if (dragStartAngle != null) {
      _drawDragRange(canvas, center, innerRadius, outerRadius, strokeWidth);
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

  /// The swept range stays on the ring where the drag started and grows from
  /// the starting point in the locked direction (wrap-safe), so it never jumps
  /// to the other side.
  void _drawDragRange(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, double strokeWidth) {
    final radius = dragOuter ? outerRadius : innerRadius;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerRadius - innerRadius) * 0.45
      ..strokeCap = StrokeCap.butt
      ..color = (darkMode ? Colors.white : const Color(0xFF111827))
          .withValues(alpha: 0.30);
    final sweep = dragEndAngle - dragStartAngle!;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      dragStartAngle! - math.pi / 2,
      sweep,
      false,
      paint,
    );
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
    final growValue = grow[block.id] ?? 0.0;
    final width = (isLive ? strokeWidth + 2 : strokeWidth) +
        strokeWidth * growValue * 0.9;
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
      oldDelegate.dragStartAngle != dragStartAngle ||
      oldDelegate.dragEndAngle != dragEndAngle ||
      oldDelegate.dragOuter != dragOuter ||
      oldDelegate.darkMode != darkMode;
}