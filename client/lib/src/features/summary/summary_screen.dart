import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/domain.dart';
import '../../models/time_bounds.dart';
import '../../providers.dart';
import '../../repositories/summary_repository.dart';

enum SummaryRange { daily, weekly, overall }

class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  SummaryRange _range = SummaryRange.daily;
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedAccountProvider).value;
    final activities = account == null
        ? const <Activity>[]
        : ref.watch(activitiesProvider(account.id)).value ?? const <Activity>[];
    final blocks = account == null
        ? const <TimeBlock>[]
        : ref.watch(timeBlocksProvider(account.id)).value ??
            const <TimeBlock>[];
    final totals = _totals(blocks, activities);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary'),
        actions: [
          if (_range != SummaryRange.overall)
            IconButton(
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_today_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<SummaryRange>(
              segments: const [
                ButtonSegment(value: SummaryRange.daily, label: Text('Daily')),
                ButtonSegment(
                    value: SummaryRange.weekly, label: Text('Weekly')),
                ButtonSegment(
                    value: SummaryRange.overall, label: Text('Overall')),
              ],
              selected: {_range},
              onSelectionChanged: (value) =>
                  setState(() => _range = value.first),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(_subtitle(),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          Expanded(
            child: totals.isEmpty
                ? const Center(child: Text('No completed focus blocks yet.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: totals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final total = totals[index];
                      final percentage = total.percentageOf(totals);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                      backgroundColor: Color(total.color),
                                      radius: 8),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${index + 1}. ${total.name}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ),
                                  Text(
                                      '${(percentage * 100).toStringAsFixed(0)}%'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 10,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                      Color(total.color)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatDuration(total.duration)} • ${total.blockCount} blocks',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<ActivityTotal> _totals(
      List<TimeBlock> blocks, List<Activity> activities) {
    return switch (_range) {
      SummaryRange.daily => SummaryRepository.aggregate(
          blocks,
          activities,
          startOfDay(_selectedDay),
          endOfDay(_selectedDay),
        ),
      SummaryRange.weekly => SummaryRepository.aggregate(
          blocks,
          activities,
          startOfWeek(_selectedDay),
          endOfWeek(_selectedDay),
        ),
      SummaryRange.overall =>
        SummaryRepository.aggregate(blocks, activities, null, null),
    };
  }

  String _subtitle() => switch (_range) {
        SummaryRange.daily => DateFormat('EEEE, MMM d, y').format(_selectedDay),
        SummaryRange.weekly =>
          'Week of ${DateFormat('MMM d').format(_monday(_selectedDay))}',
        SummaryRange.overall => 'All recorded history',
      };

  DateTime _monday(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  Future<void> _pickDay() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime(_selectedDay.year - 5),
      lastDate: DateTime(_selectedDay.year + 5),
    );
    if (selected != null) setState(() => _selectedDay = selected);
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  return '$hours h $minutes min';
}
