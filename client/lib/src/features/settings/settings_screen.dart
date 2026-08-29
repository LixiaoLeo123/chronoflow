import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAccountProvider);
    final accounts = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: accounts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (values) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
          ],
        ),
      ),
    );
  }
}
