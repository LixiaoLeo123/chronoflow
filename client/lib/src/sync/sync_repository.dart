import '../database/app_database.dart';
import '../models/domain.dart';
import 'package:drift/drift.dart';
import 'package:collection/collection.dart';

class SyncRepository {
  SyncRepository(this._database);

  final AppDatabase _database;

  Stream<void> changes() => _database.tableUpdates(
        TableUpdateQuery.onAllTables(
            [_database.activities, _database.timeBlocks]),
      );

  Future<String?> fingerprint(String accountId) async {
    final activityRows = await (_database.select(_database.activities)
          ..where((row) => row.accountId.equals(accountId))
          ..orderBy([
            (row) => OrderingTerm.desc(row.updatedAt),
          ])
          ..limit(1))
        .get();
    final blockRows = await (_database.select(_database.timeBlocks)
          ..where((row) => row.accountId.equals(accountId))
          ..orderBy([
            (row) => OrderingTerm.desc(row.updatedAt),
          ])
          ..limit(1))
        .get();
    return '${activityRows.length}:${activityRows.firstOrNull?.updatedAt.toIso8601String()}:'
        '${blockRows.length}:${blockRows.firstOrNull?.updatedAt.toIso8601String()}';
  }

  Future<SyncBundle> localDelta(String accountId, DateTime? since) async {
    // Send the complete account snapshot. The server applies timestamp-based
    // last-write-wins, and a full snapshot lets a device repair a server that
    // missed an older activity while still retaining a newer sync cursor.
    final activityQuery = _database.select(_database.activities)
      ..where((row) => row.accountId.equals(accountId));
    final blockQuery = _database.select(_database.timeBlocks)
      ..where((row) => row.accountId.equals(accountId));
    final activityRows = await activityQuery.get();
    final blockRows = await blockQuery.get();
    return SyncBundle(
      activities: activityRows
          .map(
            (row) => Activity(
              id: row.id,
              accountId: row.accountId,
              name: row.name,
              color: row.color,
              archived: row.archived,
              deleted: row.deleted,
              createdAt: row.createdAt,
              updatedAt: row.updatedAt,
            ),
          )
          .toList(),
      blocks: blockRows
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
      serverTime: DateTime.now().toUtc(),
    );
  }

  Future<void> applyServer(SyncBundle bundle) async {
    if (bundle.activities.isNotEmpty) {
      await _database.upsertActivities(bundle.activities);
    }
    if (bundle.blocks.isNotEmpty) {
      await _database.upsertTimeBlocks(bundle.blocks);
    }
  }

  Future<String?> cursor(String accountId) async {
    final account = await (_database.select(_database.accounts)
          ..where((row) => row.id.equals(accountId)))
        .getSingleOrNull();
    return account?.syncCursor;
  }

  Future<void> saveCursor(String accountId, String cursor) async {
    await (_database.update(_database.accounts)
          ..where((row) => row.id.equals(accountId)))
        .write(AccountsCompanion(syncCursor: Value(cursor)));
  }
}
