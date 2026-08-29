import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/domain.dart';
import '../../providers.dart';
import '../../repositories/activity_repository.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedAccountProvider).value;
    final accountId = account?.id;
    final activities = account == null
        ? const AsyncValue<List<Activity>>.data(<Activity>[])
        : ref.watch(activitiesProvider(account.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Things')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: accountId == null
            ? null
            : () => _showEditor(context, ref, accountId),
        icon: const Icon(Icons.add),
        label: const Text('New'),
      ),
      body: activities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (values) {
          if (values.isEmpty) {
            return const Center(
                child: Text('Add the first thing you want to track.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: values.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final activity = values[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Color(activity.color)),
                  title: Text(activity.name),
                  subtitle: Text(activity.deleted
                      ? 'Deleted'
                      : activity.archived
                          ? 'Archived'
                          : 'Active'),
                  enabled: !activity.deleted,
                  trailing: activity.deleted
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (value) async {
                            final repository =
                                ref.read(activityRepositoryProvider);
                            if (value == 'edit') {
                              await _showEditor(context, ref, accountId!,
                                  activity: activity);
                            } else if (value == 'archive') {
                              await repository.setArchived(
                                  accountId!, activity.id, !activity.archived);
                            } else if (value == 'delete') {
                              await repository.delete(accountId!, activity.id);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                                value: 'archive',
                                child: Text('Archive / restore')),
                            PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref,
    String accountId, {
    Activity? activity,
  }) async {
    final repository = ref.read(activityRepositoryProvider);
    final current =
        ref.read(activitiesProvider(accountId)).value ?? const <Activity>[];
    final name = TextEditingController(text: activity?.name ?? '');
    var color = activity?.color ?? repository.nextUnusedColor(current);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final item in ActivityRepository.palette)
                    GestureDetector(
                      onTap: () => setState(() => color = item),
                      child: CircleAvatar(
                        radius: 21,
                        backgroundColor: Color(item),
                        child: color == item
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (name.text.trim().isEmpty) return;
                  Navigator.pop(context, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved != true) return;
    try {
      if (activity == null) {
        await repository.create(
            accountId: accountId, name: name.text, color: color);
      } else {
        await repository.rename(accountId, activity.id, name.text);
        await repository.recolor(accountId, activity.id, color);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }
}
