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

    final roundSelector = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var round = 1; round <= roundCount; round++)
          ChoiceChip(
            label: Text('Round $round'),
            selected: round == currentRound && timer.kind == BlockKind.focus,
            onSelected: timer.running
                ? null
                : (_) => controller.selectRound(round),
          ),
      ],
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
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: Theme.of(context).textTheme.titleSmall),
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
                        Expanded(flex: 4, child: timerView),
                      ],
                    ),
                  ),
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
