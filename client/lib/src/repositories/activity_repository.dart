import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/domain.dart';

class ActivityRepository {
  ActivityRepository(this._database);

  static const palette = <int>[
    0xFF2563EB,
    0xFF059669,
    0xFFF97316,
    0xFF9333EA,
    0xFFE11D48,
    0xFF0891B2,
    0xFFCA8A04,
  ];

  final AppDatabase _database;

  Stream<List<Activity>> watchActivities(String accountId) {
    final query = _database.select(_database.activities)
      ..where((row) => row.accountId.equals(accountId))
      ..orderBy([
        (row) => OrderingTerm.asc(row.deleted),
        (row) => OrderingTerm.asc(row.archived),
        (row) => OrderingTerm.asc(row.name),
      ]);
    return query.watch().map(
          (rows) => rows
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
        );
  }

  Future<Activity> create({
    required String accountId,
    required String name,
    required int color,
  }) async {
    final now = DateTime.now();
    final activity = Activity(
      id: const Uuid().v7(),
      accountId: accountId,
      name: name.trim(),
      color: color,
      archived: false,
      deleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await _database.upsertActivity(activity);
    return activity;
  }

  Future<void> rename(String accountId, String id, String name) => _modify(
      accountId, id, (activity) => activity.copyWith(name: name.trim()));

  Future<void> recolor(String accountId, String id, int color) =>
      _modify(accountId, id, (activity) => activity.copyWith(color: color));

  Future<void> setArchived(String accountId, String id, bool archived) =>
      _modify(
          accountId, id, (activity) => activity.copyWith(archived: archived));

  Future<void> delete(String accountId, String id) => _modify(accountId, id,
      (activity) => activity.copyWith(deleted: true, archived: true));

  Future<void> _modify(
    String accountId,
    String id,
    Activity Function(Activity) transform,
  ) async {
    final rows = await (_database.select(_database.activities)
          ..where((row) => row.accountId.equals(accountId) & row.id.equals(id)))
        .get();
    final row = rows.singleOrNull;
    if (row == null) return;
    await _database.upsertActivity(
      transform(
        Activity(
          id: row.id,
          accountId: row.accountId,
          name: row.name,
          color: row.color,
          archived: row.archived,
          deleted: row.deleted,
          createdAt: row.createdAt,
          updatedAt: row.updatedAt,
        ),
      ).copyWith(updatedAt: DateTime.now()),
    );
  }

  int nextUnusedColor(List<Activity> activities) {
    final used = activities
        .where((item) => !item.deleted)
        .map((item) => item.color)
        .toSet();
    return palette.firstWhere(used.contains, orElse: () => palette.first);
  }
}
