import '../models/domain.dart';
import '../models/time_bounds.dart';
import 'block_repository.dart';

class SummaryRepository {
  SummaryRepository(this._blocks);

  final BlockRepository _blocks;

  static List<ActivityTotal> aggregate(
    List<TimeBlock> blocks,
    List<Activity> activities,
    DateTime? start,
    DateTime? end,
  ) {
    final filtered = blocks.where((block) {
      if (block.kind != BlockKind.focus ||
          block.status != BlockStatus.completed ||
          block.deleted) {
        return false;
      }
      if (start != null && block.start.isBefore(start)) return false;
      if (end != null && !block.start.isBefore(end)) return false;
      return true;
    }).toList();
    final grouped = <String, ({int duration, int count})>{};
    for (final block in filtered) {
      final current = grouped[block.activityId] ?? (duration: 0, count: 0);
      grouped[block.activityId] = (
        duration:
            current.duration + block.end.difference(block.start).inMilliseconds,
        count: current.count + 1,
      );
    }
    return grouped.entries.map((entry) {
      final activity = activities.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => Activity(
          id: entry.key,
          accountId: '',
          name: 'Deleted activity',
          color: 0xFF64748B,
          archived: true,
          deleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return ActivityTotal(
        activityId: entry.key,
        name: activity.name,
        color: activity.color,
        duration: Duration(milliseconds: entry.value.duration),
        blockCount: entry.value.count,
      );
    }).toList()
      ..sort((left, right) => right.duration.compareTo(left.duration));
  }

  Future<List<ActivityTotal>> overall(
          String accountId, List<Activity> activities) =>
      _blocks.totals(accountId, activities, null, null);

  Future<List<ActivityTotal>> daily(
          String accountId, List<Activity> activities, DateTime day) =>
      _blocks.totals(accountId, activities, startOfDay(day), endOfDay(day));

  Future<List<ActivityTotal>> weekly(
          String accountId, List<Activity> activities, DateTime day) =>
      _blocks.totals(accountId, activities, startOfWeek(day), endOfWeek(day));
}
