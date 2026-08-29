import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/domain.dart';
import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAccountProvider);
    final accounts = ref.watch(accountsProvider);
    final account = selected.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (values) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TimerSettingsCard(
              accountId: account?.id,
              enabled: account != null,
            ),
            const SizedBox(height: 16),
            _InvitationCard(accountId: account?.id),
            const SizedBox(height: 16),
            Text('Accounts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (values.isEmpty)
              const Card(child: ListTile(title: Text('No cached accounts'))),
            for (final account in values)
              Card(
                child: ListTile(
                  leading: Icon(
                    account.id == selected.value?.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(account.username),
                  subtitle: Text(
                      account.selected ? 'Active' : 'Cached offline session'),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).select(account.id);
                    ref.invalidate(selectedAccountProvider);
                    ref.invalidate(accountsProvider);
                  },
                  trailing: IconButton(
                    tooltip: 'Remove from device',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).forget(account.id);
                      ref.invalidate(selectedAccountProvider);
                      ref.invalidate(accountsProvider);
                    },
                  ),
                ),
              ),
            if (account != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).logout(account.id);
                    ref.invalidate(pomodoroProvider(account.id));
                    ref.invalidate(selectedAccountProvider);
                    ref.invalidate(accountsProvider);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimerSettingsCard extends ConsumerWidget {
  const _TimerSettingsCard({required this.accountId, required this.enabled});

  final String? accountId;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accountId == null) return const SizedBox.shrink();
    final settings = ref.watch(timerSettingsProvider(accountId!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pomodoro', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            settings.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('$error'),
              data: (value) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsNumberField(
                    label: 'Focus minutes',
                    value: value.focusMinutes,
                    onChanged: (focusMinutes) => _save(
                      ref,
                      value.copyWith(focusMinutes: focusMinutes),
                    ),
                  ),
                  _SettingsNumberField(
                    label: 'Short break minutes',
                    value: value.shortBreakMinutes,
                    onChanged: (shortBreakMinutes) => _save(
                      ref,
                      value.copyWith(shortBreakMinutes: shortBreakMinutes),
                    ),
                  ),
                  _SettingsNumberField(
                    label: 'Long break minutes',
                    value: value.longBreakMinutes,
                    onChanged: (longBreakMinutes) => _save(
                      ref,
                      value.copyWith(longBreakMinutes: longBreakMinutes),
                    ),
                  ),
                  _SettingsNumberField(
                    label: 'Focus rounds before long break',
                    value: value.roundsBeforeLongBreak,
                    onChanged: (roundsBeforeLongBreak) => _save(
                      ref,
                      value.copyWith(
                          roundsBeforeLongBreak: roundsBeforeLongBreak),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-start breaks'),
                    value: value.autoStartBreaks,
                    onChanged: enabled
                        ? (autoStartBreaks) =>
                            _save(ref, value.copyWith(autoStartBreaks: autoStartBreaks))
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-start focus'),
                    value: value.autoStartFocus,
                    onChanged: enabled
                        ? (autoStartFocus) =>
                            _save(ref, value.copyWith(autoStartFocus: autoStartFocus))
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(WidgetRef ref, TimerSettings value) async {
    if (accountId == null) return;
    await ref.read(pomodoroProvider(accountId!).notifier).updateSettings(value);
    ref.invalidate(timerSettingsProvider(accountId!));
  }
}

class _InvitationCard extends ConsumerWidget {
  const _InvitationCard({required this.accountId});

  final String? accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (accountId == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.card_giftcard_outlined),
        title: const Text('Generate invitation code'),
        subtitle:
            const Text('Admin-only codes let another person create an account.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showInvitation(context, ref, accountId!),
      ),
    );
  }

  Future<void> _showInvitation(
    BuildContext context,
    WidgetRef ref,
    String accountId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response =
          await ref.read(authRepositoryProvider).createInvite(accountId);
      final code = response['code']?.toString() ?? '';
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Invitation code'),
          content: SelectableText(code),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}

class _SettingsNumberField extends StatefulWidget {
  const _SettingsNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_SettingsNumberField> createState() => _SettingsNumberFieldState();
}

class _SettingsNumberFieldState extends State<_SettingsNumberField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _SettingsNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        int.tryParse(_controller.text) != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: widget.label),
        onSubmitted: (text) {
          final parsed = int.tryParse(text);
          if (parsed != null && parsed > 0) widget.onChanged(parsed);
        },
      ),
    );
  }
}
