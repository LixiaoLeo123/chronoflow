import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/domain.dart';
import 'pomodoro_controller.dart';
import '../../providers.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedAccountProvider).value;
    if (account == null) return const SizedBox.shrink();
    final activities =
        ref.watch(activitiesProvider(account.id)).value ?? const <Activity>[];
    final settings = ref.watch(timerSettingsProvider(account.id)).value;
    final timer = ref.watch(pomodoroProvider(account.id));
    final controller = ref.read(pomodoroProvider(account.id).notifier);
    final active =
        activities.where((item) => !item.deleted && !item.archived).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pomodoro')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: timer.activityId,
                    decoration: const InputDecoration(
                      labelText: 'What are you working on?',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Choose an activity')),
                      for (final activity in active)
                        DropdownMenuItem(
                          value: activity.id,
                          child: Row(children: [
                            CircleAvatar(
                                radius: 7,
                                backgroundColor: Color(activity.color)),
                            const SizedBox(width: 8),
                            Text(activity.name),
                          ]),
                        ),
                    ],
                    onChanged: controller.selectActivity,
                  ),
                  const SizedBox(height: 28),
                  _TimerDial(state: timer),
                  const SizedBox(height: 12),
                  Text(timer.status,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            timer.running ? controller.pause : controller.start,
                        icon: Icon(
                            timer.running ? Icons.pause : Icons.play_arrow),
                        label: Text(timer.running ? 'Pause' : 'Start'),
                      ),
                      OutlinedButton.icon(
                        onPressed: controller.stop,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (settings != null)
                    _SettingsEditor(
                      settings: settings,
                      onChanged: controller.updateSettings,
                    ),
                ],
              ),
            ),
          ),
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
            Text(_label(state.kind),
                style: Theme.of(context).textTheme.titleMedium),
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

class _SettingsEditor extends StatelessWidget {
  const _SettingsEditor({required this.settings, required this.onChanged});

  final TimerSettings settings;
  final Future<void> Function(TimerSettings) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _NumberField(
              label: 'Focus minutes',
              value: settings.focusMinutes,
              onChanged: (value) =>
                  onChanged(settings.copyWith(focusMinutes: value)),
            ),
            _NumberField(
              label: 'Short break minutes',
              value: settings.shortBreakMinutes,
              onChanged: (value) =>
                  onChanged(settings.copyWith(shortBreakMinutes: value)),
            ),
            _NumberField(
              label: 'Long break minutes',
              value: settings.longBreakMinutes,
              onChanged: (value) =>
                  onChanged(settings.copyWith(longBreakMinutes: value)),
            ),
            _NumberField(
              label: 'Focus rounds before long break',
              value: settings.roundsBeforeLongBreak,
              onChanged: (value) =>
                  onChanged(settings.copyWith(roundsBeforeLongBreak: value)),
            ),
            SwitchListTile(
              title: const Text('Auto-start breaks'),
              value: settings.autoStartBreaks,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoStartBreaks: value)),
            ),
            SwitchListTile(
              title: const Text('Auto-start focus'),
              value: settings.autoStartFocus,
              onChanged: (value) =>
                  onChanged(settings.copyWith(autoStartFocus: value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onSubmitted: (text) {
          final parsed = int.tryParse(text);
          if (parsed != null && parsed > 0) onChanged(parsed);
        },
      ),
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
