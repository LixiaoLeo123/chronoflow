import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/domain.dart';
import '../../providers.dart';
import 'pomodoro_controller.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedAccountProvider).value;
    if (account == null) return const SizedBox.shrink();
    final activities =
        ref.watch(activitiesProvider(account.id)).value ?? const <Activity>[];
    final timer = ref.watch(pomodoroProvider(account.id));
    final controller = ref.read(pomodoroProvider(account.id).notifier);
    final active =
        activities.where((item) => !item.deleted && !item.archived).toList();
    final roundCount = timer.settings.roundsBeforeLongBreak;
    final currentRound = (timer.phaseIndex % roundCount) + 1;

    final activitySelector = DropdownButtonFormField<String?>(
      initialValue: timer.activityId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'What are you working on?',
        prefixIcon: const Icon(Icons.work_outline),
        helperText: active.isEmpty ? 'Create a thing to get started' : null,
      ),
      items: [
        if (active.isEmpty)
          const DropdownMenuItem(value: null, child: Text('Choose an activity')),
        for (final activity in active)
          DropdownMenuItem(
            value: activity.id,
            child: Row(
              children: [
                CircleAvatar(
                    radius: 7, backgroundColor: Color(activity.color)),
                const SizedBox(width: 8),
                Expanded(child: Text(activity.name, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
      onChanged: active.isEmpty ? null : controller.selectActivity,
    );

    final controls = Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: timer.running ? controller.pause : controller.start,
          icon: Icon(timer.running ? Icons.pause : Icons.play_arrow),
          label: Text(timer.running ? 'Pause' : 'Start'),
        ),
        OutlinedButton.icon(
          onPressed: controller.stop,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
    );

    final roundSelector = _RoundSelector(
      roundCount: roundCount,
      currentRound: currentRound,
      enabled: !timer.running,
      onSelected: controller.selectRound,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final timerView = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimerDial(state: timer),
                const SizedBox(height: 12),
                Text(timer.status, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                controls,
              ],
            );

            if (constraints.maxWidth >= 900) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Session',
                                  style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 20),
                              activitySelector,
                              const SizedBox(height: 24),
                              Text('Focus round',
                                  style:
                                      Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 12),
                              roundSelector,
                              const SizedBox(height: 12),
                              Text(
                                'Round selection is available while the timer is stopped.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Card(
                        child: Center(child: timerView),
                      ),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      activitySelector,
                      const SizedBox(height: 24),
                      Text('Focus round',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 12),
                      roundSelector,
                      const SizedBox(height: 28),
                      timerView,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TimerDial extends StatelessWidget {
  const _TimerDial({required this.state});

  final PomodoroState state;

  @override
  Widget build(BuildContext context) {
    final duration = state.settings.durationFor(state.kind);
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : 1 - state.remaining.inMilliseconds / duration.inMilliseconds;
    final total = state.settings.roundsBeforeLongBreak;
    final phaseNumber = (state.phaseIndex % total) + 1;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 280,
          child: CircularProgressIndicator(value: progress, strokeWidth: 14),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label(state.kind), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _remaining(state.remaining),
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Round $phaseNumber of $total'),
          ],
        ),
      ],
    );
  }
}

String _label(BlockKind kind) => switch (kind) {
      BlockKind.focus => 'Focus',
      BlockKind.shortBreak => 'Short break',
      BlockKind.longBreak => 'Long break',
    };

String _remaining(Duration duration) {
  final minutes = duration.inMinutes.clamp(0, 999).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _RoundSelector extends StatelessWidget {
  const _RoundSelector({
    required this.roundCount,
    required this.currentRound,
    required this.enabled,
    required this.onSelected,
  });

  final int roundCount;
  final int currentRound;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = colorScheme.primary;
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous round',
          onPressed: enabled && currentRound > 1
              ? () => onSelected(currentRound - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Round $currentRound of $roundCount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var round = 1; round <= roundCount; round++) ...[
                    if (round > 1)
                      _RoundConnector(active: round <= currentRound, color: color),
                    GestureDetector(
                      onTap: enabled ? () => onSelected(round) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: round == currentRound ? 16 : 10,
                        height: round == currentRound ? 16 : 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: round == currentRound
                              ? color
                              : round < currentRound
                                  ? color.withValues(alpha: 0.45)
                                  : colorScheme.surfaceContainerHighest,
                          border: round == currentRound
                              ? null
                              : Border.all(color: colorScheme.outline),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Next round',
          onPressed: enabled && currentRound < roundCount
              ? () => onSelected(currentRound + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _RoundConnector extends StatelessWidget {
  const _RoundConnector({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: active
          ? color.withValues(alpha: 0.45)
          : Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
