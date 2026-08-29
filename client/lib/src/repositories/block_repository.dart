import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../models/domain.dart';

class BlockRepository {
  BlockRepository(this._database);

  final AppDatabase _database;

  Stream<List<TimeBlock>> watchBlocks(String accountId) {
    final query = _database.select(_database.timeBlocks)
      ..where((row) => row.accountId.equals(accountId))
      ..orderBy([(row) => OrderingTerm.asc(row.start)]);
    return query.watch().map(
          (rows) => rows
              .map(
                (row) => TimeBlock(
                  id: row.id,
                  accountId: row.accountId,
                  activityId: row.activityId,
                  kind: BlockKind.values.byName(row.kind),
                  start: row.start,
                  end: row.end,
                  status: BlockStatus.values.byName(row.status),
                  deleted: row.deleted,
                  createdAt: row.createdAt,
                  updatedAt: row.updatedAt,
                ),
              )
              .toList(),
        );
  }

  Future<void> save(TimeBlock block) async {
    final overlapping =
        await _overlapping(block.accountId, block.start, block.end, block.id);
    if (overlapping && !block.deleted) {
      throw StateError('Another block already occupies this time.');
    }
    await _database.upsertTimeBlock(block);
  }

  Future<bool> _overlapping(
    String accountId,
    DateTime start,
    DateTime end,
    String ignoreId,
  ) async {
    final rows = await (_database.select(_database.timeBlocks)
          ..where(
            (row) =>
                row.accountId.equals(accountId) &
                row.id.equals(ignoreId).not() &
                row.deleted.equals(false) &
                row.start.isSmallerThanValue(end) &
                row.end.isBiggerThanValue(start),
          )
          ..limit(1))
        .get();
    return rows.isNotEmpty;
  }

  Future<void> delete(String accountId, String id) async {
    final rows = await (_database.select(_database.timeBlocks)
          ..where((row) => row.accountId.equals(accountId) & row.id.equals(id)))
        .get();
    final row = rows.singleOrNull;
    if (row == null) return;
    await _database.upsertTimeBlock(
      TimeBlock(
        id: row.id,
        accountId: row.accountId,
        activityId: row.activityId,
        kind: BlockKind.values.byName(row.kind),
        start: row.start,
        end: row.end,
        status: BlockStatus.values.byName(row.status),
        deleted: true,
        createdAt: row.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<List<ActivityTotal>> totals(
    String accountId,
    List<Activity> activities,
    DateTime? start,
    DateTime? end,
  ) async {
    final query = _database.select(_database.timeBlocks)
      ..where(
        (row) =>
            row.accountId.equals(accountId) &
            row.kind.equals(BlockKind.focus.name) &
            row.status.equals(BlockStatus.completed.name) &
            row.deleted.equals(false),
      );
    if (start != null) {
      query.where((row) => row.start.isBiggerOrEqualValue(start));
    }
    if (end != null) {
      query.where((row) => row.start.isSmallerThanValue(end));
    }
    final rows = await query.get();
    final grouped = <String, ({int duration, int count})>{};
    for (final row in rows) {
      final current = grouped[row.activityId] ?? (duration: 0, count: 0);
      grouped[row.activityId] = (
        duration:
            current.duration + row.end.difference(row.start).inMilliseconds,
        count: current.count + 1,
      );
    }
    final totals = grouped.entries.map((entry) {
      final activity = activities.firstWhere(
        (item) => item.id == entry.key,
        orElse: () => Activity(
          id: entry.key,
          accountId: accountId,
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
      ..sort((a, b) => b.duration.compareTo(a.duration));
    return totals;
  }
}
