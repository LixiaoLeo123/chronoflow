import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  late final AnimationController _growController;
  final Map<String, double> _grow = {};
  Map<String, double> _growFrom = {};
  Map<String, double> _growTo = {};

  /// Set during [build] so gesture handlers can reuse the current blocks.
  List<TimeBlock> _displayBlocks = const [];
  String? _hoveredId;
  Offset? _hoverAnchor;
  DateTime _selectedDay = _dateOnly(DateTime.now());

  bool _dragActive = false;
  bool _dragMoved = false;
  bool _editorOpen = false;
  bool _selectionDialogOpen = false;
  OverlayEntry? _selectionOverlay;
  Offset? _dragStart;
  bool _dragOuter = false;
  double? _dragStartAngle;
  double? _lastDragAngle;
  double _dragEndAngle = 0;
  int _dragDir = 0;
  double _sweptMax = 0;
  Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _growController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_tickGrow);
  }

  @override
  void dispose() {
    _selectionOverlay?.remove();
    _growController.dispose();
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
            .where((block) => _blockTouchesDay(block, _selectedDay))
            .toList();
    final timer = ref.watch(pomodoroProvider(account.id));
    final liveBlock = _isToday(_selectedDay)
        ? _liveBlock(timer, account.id, activities)
        : null;
    _displayBlocks = [
      ...blocks,
      if (liveBlock != null) liveBlock,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_isToday(_selectedDay)
            ? '24-hour clock'
            : 'Clock · ${DateFormat('MMM d, y').format(_selectedDay)}'),
        actions: [
          if (!_isToday(_selectedDay))
            IconButton(
              tooltip: 'Jump to today',
              icon: const Icon(Icons.today_outlined),
              onPressed: () => setState(() {
                _selectedDay = _dateOnly(DateTime.now());
                _hoveredId = null;
                _hoverAnchor = null;
                _selectedIds = {};
              }),
            ),
          IconButton(
            tooltip: 'Choose date',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDay,
          ),
        ],
      ),
      floatingActionButton: !_dragActive
          ? FloatingActionButton.extended(
              onPressed: () => _addBlock(account.id),
              icon: const Icon(Icons.add),
              label: const Text('New event'),
            )
          : null,
      body: _dialArea(account.id, _displayBlocks, activities),
    );
  }

  Widget _dialArea(
      String accountId, List<TimeBlock> blocks, List<Activity> activities) {
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
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) =>
                        _openBlockAt(details.localPosition, _displayBlocks),
                    onPanStart: (details) => _onPanStart(details.localPosition),
                    onPanUpdate: (details) =>
                        _onPanUpdate(details.localPosition),
                    onPanEnd: (_) => _onPanEnd(),
                    onPanCancel: _onPointerCancel,
                    child: ValueListenableBuilder<int>(
                      valueListenable: _repaint,
                      builder: (context, revision, child) => CustomPaint(
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
                          showDragRange:
                              _dragMoved && _dragDir != 0 && _sweptMax > 0.001,
                          selectedDay: _selectedDay,
                          darkMode: darkMode,
                          revision: revision,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(child: _hoverLabel(activities, blocks)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hoverLabel(List<Activity> activities, List<TimeBlock> blocks) {
    final block = _hoveredId == null
        ? null
        : blocks.where((item) => item.id == _hoveredId).firstOrNull;
    final activity = block == null
        ? null
        : activities.where((item) => item.id == block.activityId).firstOrNull;
    final label = activity?.name ??
        (block == null
            ? null
            : switch (block.kind) {
                BlockKind.focus => 'Focus',
                BlockKind.shortBreak => 'Short break',
                BlockKind.longBreak => 'Long break',
              });
    final chip = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: label == null
          ? const SizedBox(key: ValueKey('empty'))
          : DecoratedBox(
              key: ValueKey(label),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.45),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
    );
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final position = _hoverAnchor;
          if (position == null) return chip;
          const width = 190.0;
          final left = (position.dx + 14)
              .clamp(4.0, math.max(4.0, constraints.maxWidth - width - 4))
              .toDouble();
          final top = (position.dy - 30)
              .clamp(4.0, math.max(4.0, constraints.maxHeight - 48))
              .toDouble();
          return Stack(
              children: [Positioned(left: left, top: top, child: chip)]);
        },
      ),
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
    if (!activities.any(
        (item) => item.id == activityId && !item.deleted && !item.archived)) {
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

  // --- Selection animation -------------------------------------------------

  void _animateGrow() {
    final targets = <String, double>{
      for (final block in _displayBlocks)
        block.id: block.id == _hoveredId ? 0.65 : 0.0,
    };
    final ids = {..._grow.keys, ...targets.keys};
    _growFrom = {for (final id in ids) id: _grow[id] ?? 0.0};
    _growTo = {for (final id in ids) id: targets[id] ?? 0.0};
    _growController.forward(from: 0);
  }

  void _tickGrow() {
    final progress = Curves.easeOutCubic.transform(_growController.value);
    final ids = {..._growFrom.keys, ..._growTo.keys};
    for (final id in ids) {
      final from = _growFrom[id] ?? 0.0;
      final to = _growTo[id] ?? 0.0;
      _grow[id] = from + (to - from) * progress;
    }
    _grow.removeWhere(
        (id, value) => value.abs() < 0.001 && (_growTo[id] ?? 0).abs() < 0.001);
    _repaint.value++;
  }

  // --- Pointer handling ----------------------------------------------------

  void _onHover(Offset position, List<TimeBlock> blocks) {
    if (_dragActive) return;
    final block = _blockAt(position, blocks);
    final id = block?.id;
    if (id != _hoveredId) {
      setState(() {
        _hoveredId = id;
        _hoverAnchor = block == null ? _hoverAnchor : _segmentAnchor(block);
      });
      _animateGrow();
    }
  }

  void _onHoverExit() {
    if (_hoveredId != null) {
      setState(() {
        _hoveredId = null;
      });
      _animateGrow();
    }
  }

  void _onPanStart(Offset position) {
    _dragStart = position;
    _dragMoved = false;
    _dragDir = 0;
    _sweptMax = 0;
    _dragStartAngle = _dialAngleAt(position);
    _dragEndAngle = _dragStartAngle ?? 0;
    _dragOuter = _isOuterAt(position);
    _lastDragAngle = _dragStartAngle;
    _selectedIds = {};
    _hoveredId = null;
    _hoverAnchor = null;
    _dragActive = true;
    // Rebuild immediately so the FAB/selection actions cannot compete with
    // the active gesture and the dial enters its drag state on the first move.
    setState(() {});
    _animateGrow();
  }

  void _onPanUpdate(Offset position) {
    if (_dragStart == null) return;
    _dragMoved = true;
    final startAngle = _dragStartAngle;
    if (startAngle == null) return;
    final currentAngle = _dialAngleAt(position);
    if (currentAngle == null) return;
    final previousAngle = _lastDragAngle ?? startAngle;
    var delta = currentAngle - previousAngle;
    while (delta > math.pi) {
      delta -= 2 * math.pi;
    }
    while (delta < -math.pi) {
      delta += 2 * math.pi;
    }
    _lastDragAngle = currentAngle;
    // Lock the initial direction, then keep a continuous, reversible sweep.
    if (_dragDir == 0 && delta.abs() > 0.03) {
      _dragDir = delta > 0 ? 1 : -1;
    }
    if (_dragDir != 0) {
      var next = _sweptMax + _dragDir * delta;
      // A reversal retracts the current range. Once it reaches its origin,
      // keep it there instead of silently switching to the opposite side.
      _sweptMax = next.clamp(0.0, 2 * math.pi).toDouble();
      _dragEndAngle = startAngle + _dragDir * _sweptMax;
    }
    final nextSelection = _blocksInDragRange();
    final selectionChanged = !_sameIds(_selectedIds, nextSelection);
    if (selectionChanged) {
      setState(() => _selectedIds = nextSelection);
    } else {
      // Drag geometry changes even while the set of hit segments is stable.
      // Repaint only the dial instead of rebuilding the whole screen.
      _repaint.value++;
    }
  }

  void _onPanEnd() {
    final shouldOpenActions = _selectedIds.isNotEmpty;
    _dragStart = null;
    _dragStartAngle = null;
    _lastDragAngle = null;
    _dragEndAngle = 0;
    _sweptMax = 0;
    _dragActive = false;
    _dragMoved = false;
    setState(() {});
    if (shouldOpenActions) _showSelectionDialog();
  }

  void _onPointerCancel() {
    _dragStart = null;
    _dragStartAngle = null;
    _lastDragAngle = null;
    _dragEndAngle = 0;
    _sweptMax = 0;
    _dragActive = false;
    _dragMoved = false;
    setState(() {});
  }

  bool _sameIds(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _openBlockAt(Offset position, List<TimeBlock> blocks) async {
    if (_editorOpen) return;
    final found = _blockAt(position, blocks);
    if (found == null) return;
    _editorOpen = true;
    try {
      await _openEditor(found);
    } finally {
      _editorOpen = false;
    }
  }

  Set<String> _blocksInDragRange() {
    final startAngle = _dragStartAngle;
    if (startAngle == null || _sweptMax <= 0.001) return {};
    final endAngle = _dragEndAngle;
    final lo = math.min(startAngle, endAngle);
    final hi = math.max(startAngle, endAngle);
    final fullRing = _sweptMax >= 2 * math.pi - 0.01;
    final blocks = _displayBlocks.where((block) => !block.deleted);
    final dayStart = _selectedDay;
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
    if (!e.isAfter(s) || e.isBefore(ringStart) || s.isAfter(ringEnd)) {
      return null;
    }
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
    _animateGrow();
  }

  Future<void> _deleteSelection() async {
    final account = ref.read(selectedAccountProvider).value;
    if (account == null || _selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected segments?'),
        content: Text('This will delete ${_selectedIds.length} segment(s).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final repository = ref.read(blockRepositoryProvider);
    final ids = _selectedIds.toList();
    for (final id in ids) {
      await repository.delete(account.id, id);
    }
    if (mounted) setState(() => _selectedIds = {});
    if (mounted) _animateGrow();
  }

  Future<void> _editSelection() async {
    if (_selectedIds.length != 1 || _editorOpen) return;
    final id = _selectedIds.single;
    final block = _displayBlocks.where((item) => item.id == id).firstOrNull;
    if (block == null) return;
    setState(() => _selectedIds = {});
    _animateGrow();
    _editorOpen = true;
    try {
      await _openEditor(block);
    } finally {
      _editorOpen = false;
    }
  }

  void _showSelectionDialog() {
    if (_selectionDialogOpen || _selectedIds.isEmpty || !mounted) return;
    _selectionDialogOpen = true;
    final entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(
            color: Colors.transparent,
            dismissible: true,
            onDismiss: () => _closeSelectionPopup(clear: true),
          ),
          Center(child: _selectionPopup(overlayContext)),
        ],
      ),
    );
    _selectionOverlay = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
  }

  Widget _selectionPopup(BuildContext popupContext) {
    final count = _selectedIds.length;
    final scheme = Theme.of(popupContext).colorScheme;
    void choose(String action) {
      _closeSelectionPopup(clear: false);
      switch (action) {
        case 'edit':
          _editSelection();
        case 'delete':
          _deleteSelection();
        case 'clear':
          _clearSelection();
      }
    }

    return Dialog(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      elevation: 24,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      count == 1
                          ? '1 segment selected'
                          : '$count segments selected',
                      style: Theme.of(popupContext).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (count == 1) ...[
                FilledButton.icon(
                  onPressed: () => choose('edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit segment'),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                onPressed: () => choose('delete'),
                icon: const Icon(Icons.delete_outline),
                label: Text(count == 1
                    ? 'Delete segment'
                    : 'Delete all $count segments'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => choose('clear'),
                child: const Text('Clear selection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _closeSelectionPopup({required bool clear}) {
    _selectionOverlay?.remove();
    _selectionOverlay = null;
    _selectionDialogOpen = false;
    if (clear && mounted) _clearSelection();
  }

  // --- Geometry helpers ----------------------------------------------------

  /// The dial size and metrics from the painted ring.
  ({Size size, Offset center, double outer, double inner})? _metrics() {
    final renderBox =
        _clockKey.currentContext?.findRenderObject() as RenderBox?;
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

  /// Finds the block whose arc covers the tapped spot, with a small tolerance
  /// so thin or short segments respond reliably.
  TimeBlock? _blockAt(Offset position, List<TimeBlock> blocks) {
    final m = _metrics();
    if (m == null) return null;
    final distance = (position - m.center).distance;
    final band = m.outer - m.inner;
    final stroke = band * 0.34;
    if (distance < m.inner - stroke - 16 || distance > m.outer + stroke + 16) {
      return null;
    }
    final outer = distance > (m.inner + m.outer) / 2;
    final angle = _dialAngleAt(position);
    if (angle == null) return null;
    final tolerance = math.max(
      0.02,
      (stroke / 2 + 12) / (outer ? m.outer : m.inner),
    );
    final dayStart = _selectedDay;
    TimeBlock? nearest;
    var nearestGap = double.infinity;
    for (final block in blocks) {
      final arc = _blockArcOnRing(block, outer, dayStart);
      if (arc == null) continue;
      final gap = _angularGap(angle, arc.start, arc.end);
      if (gap <= tolerance && gap < nearestGap) {
        nearest = block;
        nearestGap = gap;
      }
    }
    return nearest;
  }

  double _angularGap(double angle, double start, double end) {
    var nearest = double.infinity;
    for (final k in [-1, 0, 1]) {
      final offset = k * 2 * math.pi;
      if (angle >= start + offset && angle <= end + offset) return 0;
      nearest = math.min(nearest, (angle - start - offset).abs());
      nearest = math.min(nearest, (angle - end - offset).abs());
    }
    return nearest;
  }

  Offset? _segmentAnchor(TimeBlock block) {
    final metrics = _metrics();
    if (metrics == null) return null;
    final dayEnd = _selectedDay.add(const Duration(days: 1));
    final start = block.start.toLocal().isAfter(_selectedDay)
        ? block.start.toLocal()
        : _selectedDay;
    final end =
        block.end.toLocal().isBefore(dayEnd) ? block.end.toLocal() : dayEnd;
    if (!end.isAfter(start)) return null;
    final midpoint = start
        .add(Duration(milliseconds: end.difference(start).inMilliseconds ~/ 2));
    final outer =
        !midpoint.isBefore(_selectedDay.add(const Duration(hours: 12)));
    final ringStart =
        outer ? _selectedDay.add(const Duration(hours: 12)) : _selectedDay;
    final fraction = midpoint.difference(ringStart).inMilliseconds /
        const Duration(hours: 12).inMilliseconds;
    final angle = fraction * 2 * math.pi - math.pi / 2;
    final radius = outer ? metrics.outer : metrics.inner;
    return metrics.center + Offset(math.cos(angle), math.sin(angle)) * radius;
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(_selectedDay.year - 5),
      lastDate: DateTime(_selectedDay.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDay = _dateOnly(picked);
      _hoveredId = null;
      _hoverAnchor = null;
      _selectedIds = {};
    });
    _animateGrow();
  }

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return now.year == day.year && now.month == day.month && now.day == day.day;
  }

  bool _blockTouchesDay(TimeBlock block, DateTime day) {
    final end = day.add(const Duration(days: 1));
    final start = block.start.toLocal();
    final finish = block.end.toLocal();
    return finish.isAfter(day) && start.isBefore(end);
  }

  // --- Editors -------------------------------------------------------------

  Future<void> _openEditor(TimeBlock block) async {
    final account = ref.read(selectedAccountProvider).value;
    if (account == null) return;
    if (block.id == _liveBlockId) {
      await _showLiveEditor(account.id);
      return;
    }
    await _showBlockEditor(
        context: context, accountId: account.id, block: block);
  }

  Future<void> _addBlock(String accountId) =>
      _showBlockEditor(context: context, accountId: accountId, block: null);

  Future<void> _showLiveEditor(String accountId) async {
    final result = await showDialog<Object?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Live recording'),
        content: const Text(
            'This arc records the running focus timer. Deleting it cuts '
            'the recording here — it keeps growing from this moment.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'delete'),
            child: const Text('Delete & keep recording'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Close'),
          ),
        ],
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
    var start = block?.start.toLocal() ?? _defaultStart(_selectedDay);
    var end = block?.end.toLocal() ?? start.add(const Duration(minutes: 25));
    var activityId = block?.activityId ?? activities.firstOrNull?.id ?? '';
    var kind = block?.kind ?? BlockKind.focus;
    final saved = await showDialog<Object?>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
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
                      ButtonSegment(
                          value: BlockKind.focus, label: Text('Focus')),
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
                  Text(
                      'Start: ${TimeOfDay.fromDateTime(start).format(context)}'),
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
                          onPressed: () =>
                              Navigator.pop(sheetContext, 'delete'),
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

DateTime _defaultStart(DateTime day) {
  final now = DateTime.now();
  if (!_sameDay(day, now)) return DateTime(day.year, day.month, day.day, 9);
  return DateTime(now.year, now.month, now.day, now.hour + 1);
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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
    required this.showDragRange,
    required this.selectedDay,
    required this.revision,
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
  final bool showDragRange;
  final DateTime selectedDay;
  final int revision;

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
    if (showDragRange && dragStartAngle != null) {
      _drawDragRange(canvas, center, innerRadius, outerRadius, strokeWidth);
    }

    final ordered = [...blocks]..sort((a, b) {
        final aRaised = a.id == highlightedId || selectedIds.contains(a.id);
        final bRaised = b.id == highlightedId || selectedIds.contains(b.id);
        return (aRaised ? 1 : 0).compareTo(bRaised ? 1 : 0);
      });
    for (final block in ordered) {
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

  void _drawLabels(
      Canvas canvas, Offset center, double innerRadius, double outerRadius) {
    final band = outerRadius - innerRadius;
    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (var hour = 0; hour < 24; hour += 2) {
      final angle = _hourAngle(hour);
      final radius =
          hour < 12 ? innerRadius + band * 0.24 : innerRadius + band * 0.76;
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
    final growValue =
        selectedIds.contains(block.id) ? 1.0 : (grow[block.id] ?? 0.0);
    final scale = 1 + growValue * 0.22;
    _strokeSegments(
      canvas,
      center,
      innerRadius,
      outerRadius,
      block,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isLive ? strokeWidth + 2 : strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color,
      scale: scale,
    );
  }

  void _strokeSegments(Canvas canvas, Offset center, double innerRadius,
      double outerRadius, TimeBlock block, Paint paint,
      {double scale = 1}) {
    final dayEnd = selectedDay.add(const Duration(days: 1));
    var cursor = block.start.toLocal().isAfter(selectedDay)
        ? block.start.toLocal()
        : selectedDay;
    final blockEnd = block.end.toLocal();
    final end = blockEnd.isBefore(dayEnd) ? blockEnd : dayEnd;
    if (!end.isAfter(cursor)) return;
    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
      _drawSegment(canvas, center, innerRadius, outerRadius, cursor, segmentEnd,
          paint, scale);
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
      double scale) {
    for (final piece in _splitAtNoon(start, end)) {
      final inner = piece.$1.hour < 12;
      final radius = inner ? innerRadius : outerRadius;
      final startAngle =
          _fractionOnRing(piece.$1, inner) * 2 * math.pi - math.pi / 2;
      final sweep = (_fractionOnRing(piece.$2, inner) -
              _fractionOnRing(piece.$1, inner)) *
          2 *
          math.pi;
      if (sweep <= 0) continue;
      final midpoint = piece.$1.add(Duration(
          milliseconds: piece.$2.difference(piece.$1).inMilliseconds ~/ 2));
      final midpointAngle =
          _fractionOnRing(midpoint, inner) * 2 * math.pi - math.pi / 2;
      final anchor = center +
          Offset(math.cos(midpointAngle), math.sin(midpointAngle)) * radius;
      canvas.save();
      canvas.translate(anchor.dx, anchor.dy);
      canvas.scale(scale);
      canvas.translate(-anchor.dx, -anchor.dy);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      canvas.restore();
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
      oldDelegate.showDragRange != showDragRange ||
      oldDelegate.dragOuter != dragOuter ||
      oldDelegate.selectedDay != selectedDay ||
      oldDelegate.darkMode != darkMode ||
      oldDelegate.revision != revision;
}
