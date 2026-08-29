// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _selectedMeta =
      const VerificationMeta('selected');
  @override
  late final GeneratedColumn<bool> selected = GeneratedColumn<bool>(
      'selected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("selected" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _syncCursorMeta =
      const VerificationMeta('syncCursor');
  @override
  late final GeneratedColumn<String> syncCursor = GeneratedColumn<String>(
      'sync_cursor', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastUsedAtMeta =
      const VerificationMeta('lastUsedAt');
  @override
  late final GeneratedColumn<DateTime> lastUsedAt = GeneratedColumn<DateTime>(
      'last_used_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, username, selected, syncCursor, lastUsedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('selected')) {
      context.handle(_selectedMeta,
          selected.isAcceptableOrUnknown(data['selected']!, _selectedMeta));
    }
    if (data.containsKey('sync_cursor')) {
      context.handle(
          _syncCursorMeta,
          syncCursor.isAcceptableOrUnknown(
              data['sync_cursor']!, _syncCursorMeta));
    }
    if (data.containsKey('last_used_at')) {
      context.handle(
          _lastUsedAtMeta,
          lastUsedAt.isAcceptableOrUnknown(
              data['last_used_at']!, _lastUsedAtMeta));
    } else if (isInserting) {
      context.missing(_lastUsedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      selected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}selected'])!,
      syncCursor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_cursor']),
      lastUsedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_used_at'])!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String username;
  final bool selected;
  final String? syncCursor;
  final DateTime lastUsedAt;
  const Account(
      {required this.id,
      required this.username,
      required this.selected,
      this.syncCursor,
      required this.lastUsedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['selected'] = Variable<bool>(selected);
    if (!nullToAbsent || syncCursor != null) {
      map['sync_cursor'] = Variable<String>(syncCursor);
    }
    map['last_used_at'] = Variable<DateTime>(lastUsedAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      username: Value(username),
      selected: Value(selected),
      syncCursor: syncCursor == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCursor),
      lastUsedAt: Value(lastUsedAt),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      selected: serializer.fromJson<bool>(json['selected']),
      syncCursor: serializer.fromJson<String?>(json['syncCursor']),
      lastUsedAt: serializer.fromJson<DateTime>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'selected': serializer.toJson<bool>(selected),
      'syncCursor': serializer.toJson<String?>(syncCursor),
      'lastUsedAt': serializer.toJson<DateTime>(lastUsedAt),
    };
  }

  Account copyWith(
          {String? id,
          String? username,
          bool? selected,
          Value<String?> syncCursor = const Value.absent(),
          DateTime? lastUsedAt}) =>
      Account(
        id: id ?? this.id,
        username: username ?? this.username,
        selected: selected ?? this.selected,
        syncCursor: syncCursor.present ? syncCursor.value : this.syncCursor,
        lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      selected: data.selected.present ? data.selected.value : this.selected,
      syncCursor:
          data.syncCursor.present ? data.syncCursor.value : this.syncCursor,
      lastUsedAt:
          data.lastUsedAt.present ? data.lastUsedAt.value : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('selected: $selected, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, selected, syncCursor, lastUsedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.username == this.username &&
          other.selected == this.selected &&
          other.syncCursor == this.syncCursor &&
          other.lastUsedAt == this.lastUsedAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> username;
  final Value<bool> selected;
  final Value<String?> syncCursor;
  final Value<DateTime> lastUsedAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.selected = const Value.absent(),
    this.syncCursor = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String username,
    this.selected = const Value.absent(),
    this.syncCursor = const Value.absent(),
    required DateTime lastUsedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        username = Value(username),
        lastUsedAt = Value(lastUsedAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<bool>? selected,
    Expression<String>? syncCursor,
    Expression<DateTime>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (selected != null) 'selected': selected,
      if (syncCursor != null) 'sync_cursor': syncCursor,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? username,
      Value<bool>? selected,
      Value<String?>? syncCursor,
      Value<DateTime>? lastUsedAt,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      selected: selected ?? this.selected,
      syncCursor: syncCursor ?? this.syncCursor,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (selected.present) {
      map['selected'] = Variable<bool>(selected.value);
    }
    if (syncCursor.present) {
      map['sync_cursor'] = Variable<String>(syncCursor.value);
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<DateTime>(lastUsedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('selected: $selected, ')
          ..write('syncCursor: $syncCursor, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivitiesTable extends Activities
    with TableInfo<$ActivitiesTable, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
      'color', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedMeta =
      const VerificationMeta('archived');
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
      'archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, accountId, name, color, archived, deleted, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activities';
  @override
  VerificationContext validateIntegrity(Insertable<ActivityRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(_archivedMeta,
          archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta));
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}color'])!,
      archived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}archived'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ActivitiesTable createAlias(String alias) {
    return $ActivitiesTable(attachedDatabase, alias);
  }
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final String id;
  final String accountId;
  final String name;
  final int color;
  final bool archived;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ActivityRow(
      {required this.id,
      required this.accountId,
      required this.name,
      required this.color,
      required this.archived,
      required this.deleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    map['archived'] = Variable<bool>(archived);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ActivitiesCompanion toCompanion(bool nullToAbsent) {
    return ActivitiesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      name: Value(name),
      color: Value(color),
      archived: Value(archived),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ActivityRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      archived: serializer.fromJson<bool>(json['archived']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'archived': serializer.toJson<bool>(archived),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ActivityRow copyWith(
          {String? id,
          String? accountId,
          String? name,
          int? color,
          bool? archived,
          bool? deleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      ActivityRow(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        name: name ?? this.name,
        color: color ?? this.color,
        archived: archived ?? this.archived,
        deleted: deleted ?? this.deleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ActivityRow copyWithCompanion(ActivitiesCompanion data) {
    return ActivityRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      archived: data.archived.present ? data.archived.value : this.archived,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, accountId, name, color, archived, deleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.color == this.color &&
          other.archived == this.archived &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ActivitiesCompanion extends UpdateCompanion<ActivityRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> name;
  final Value<int> color;
  final Value<bool> archived;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ActivitiesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.archived = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivitiesCompanion.insert({
    required String id,
    required String accountId,
    required String name,
    required int color,
    this.archived = const Value.absent(),
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        name = Value(name),
        color = Value(color),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ActivityRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<int>? color,
    Expression<bool>? archived,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (archived != null) 'archived': archived,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String>? name,
      Value<int>? color,
      Value<bool>? archived,
      Value<bool>? deleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ActivitiesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      color: color ?? this.color,
      archived: archived ?? this.archived,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivitiesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('archived: $archived, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimeBlocksTable extends TimeBlocks
    with TableInfo<$TimeBlocksTable, TimeBlockRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimeBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
      'start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
      'end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _deletedMeta =
      const VerificationMeta('deleted');
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
      'deleted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("deleted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        accountId,
        activityId,
        kind,
        start,
        end,
        status,
        deleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'time_blocks';
  @override
  VerificationContext validateIntegrity(Insertable<TimeBlockRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(_deletedMeta,
          deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TimeBlockRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimeBlockRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      deleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}deleted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TimeBlocksTable createAlias(String alias) {
    return $TimeBlocksTable(attachedDatabase, alias);
  }
}

class TimeBlockRow extends DataClass implements Insertable<TimeBlockRow> {
  final String id;
  final String accountId;
  final String activityId;
  final String kind;
  final DateTime start;
  final DateTime end;
  final String status;
  final bool deleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const TimeBlockRow(
      {required this.id,
      required this.accountId,
      required this.activityId,
      required this.kind,
      required this.start,
      required this.end,
      required this.status,
      required this.deleted,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['activity_id'] = Variable<String>(activityId);
    map['kind'] = Variable<String>(kind);
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['status'] = Variable<String>(status);
    map['deleted'] = Variable<bool>(deleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimeBlocksCompanion toCompanion(bool nullToAbsent) {
    return TimeBlocksCompanion(
      id: Value(id),
      accountId: Value(accountId),
      activityId: Value(activityId),
      kind: Value(kind),
      start: Value(start),
      end: Value(end),
      status: Value(status),
      deleted: Value(deleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimeBlockRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimeBlockRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      kind: serializer.fromJson<String>(json['kind']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      status: serializer.fromJson<String>(json['status']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'activityId': serializer.toJson<String>(activityId),
      'kind': serializer.toJson<String>(kind),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'status': serializer.toJson<String>(status),
      'deleted': serializer.toJson<bool>(deleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimeBlockRow copyWith(
          {String? id,
          String? accountId,
          String? activityId,
          String? kind,
          DateTime? start,
          DateTime? end,
          String? status,
          bool? deleted,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      TimeBlockRow(
        id: id ?? this.id,
        accountId: accountId ?? this.accountId,
        activityId: activityId ?? this.activityId,
        kind: kind ?? this.kind,
        start: start ?? this.start,
        end: end ?? this.end,
        status: status ?? this.status,
        deleted: deleted ?? this.deleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TimeBlockRow copyWithCompanion(TimeBlocksCompanion data) {
    return TimeBlockRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      status: data.status.present ? data.status.value : this.status,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlockRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('status: $status, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, accountId, activityId, kind, start, end,
      status, deleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimeBlockRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.activityId == this.activityId &&
          other.kind == this.kind &&
          other.start == this.start &&
          other.end == this.end &&
          other.status == this.status &&
          other.deleted == this.deleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TimeBlocksCompanion extends UpdateCompanion<TimeBlockRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String> activityId;
  final Value<String> kind;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<String> status;
  final Value<bool> deleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TimeBlocksCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.status = const Value.absent(),
    this.deleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimeBlocksCompanion.insert({
    required String id,
    required String accountId,
    required String activityId,
    required String kind,
    required DateTime start,
    required DateTime end,
    required String status,
    this.deleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        accountId = Value(accountId),
        activityId = Value(activityId),
        kind = Value(kind),
        start = Value(start),
        end = Value(end),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<TimeBlockRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? activityId,
    Expression<String>? kind,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<String>? status,
    Expression<bool>? deleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (activityId != null) 'activity_id': activityId,
      if (kind != null) 'kind': kind,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (status != null) 'status': status,
      if (deleted != null) 'deleted': deleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimeBlocksCompanion copyWith(
      {Value<String>? id,
      Value<String>? accountId,
      Value<String>? activityId,
      Value<String>? kind,
      Value<DateTime>? start,
      Value<DateTime>? end,
      Value<String>? status,
      Value<bool>? deleted,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TimeBlocksCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      activityId: activityId ?? this.activityId,
      kind: kind ?? this.kind,
      start: start ?? this.start,
      end: end ?? this.end,
      status: status ?? this.status,
      deleted: deleted ?? this.deleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimeBlocksCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('status: $status, ')
          ..write('deleted: $deleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerSettingsTableTable extends TimerSettingsTable
    with TableInfo<$TimerSettingsTableTable, TimerSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _focusMinutesMeta =
      const VerificationMeta('focusMinutes');
  @override
  late final GeneratedColumn<int> focusMinutes = GeneratedColumn<int>(
      'focus_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(25));
  static const VerificationMeta _shortBreakMinutesMeta =
      const VerificationMeta('shortBreakMinutes');
  @override
  late final GeneratedColumn<int> shortBreakMinutes = GeneratedColumn<int>(
      'short_break_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(5));
  static const VerificationMeta _longBreakMinutesMeta =
      const VerificationMeta('longBreakMinutes');
  @override
  late final GeneratedColumn<int> longBreakMinutes = GeneratedColumn<int>(
      'long_break_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _roundsBeforeLongBreakMeta =
      const VerificationMeta('roundsBeforeLongBreak');
  @override
  late final GeneratedColumn<int> roundsBeforeLongBreak = GeneratedColumn<int>(
      'rounds_before_long_break', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(4));
  static const VerificationMeta _autoStartBreaksMeta =
      const VerificationMeta('autoStartBreaks');
  @override
  late final GeneratedColumn<bool> autoStartBreaks = GeneratedColumn<bool>(
      'auto_start_breaks', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_start_breaks" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _autoStartFocusMeta =
      const VerificationMeta('autoStartFocus');
  @override
  late final GeneratedColumn<bool> autoStartFocus = GeneratedColumn<bool>(
      'auto_start_focus', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("auto_start_focus" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        focusMinutes,
        shortBreakMinutes,
        longBreakMinutes,
        roundsBeforeLongBreak,
        autoStartBreaks,
        autoStartFocus,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_settings_table';
  @override
  VerificationContext validateIntegrity(Insertable<TimerSettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('focus_minutes')) {
      context.handle(
          _focusMinutesMeta,
          focusMinutes.isAcceptableOrUnknown(
              data['focus_minutes']!, _focusMinutesMeta));
    }
    if (data.containsKey('short_break_minutes')) {
      context.handle(
          _shortBreakMinutesMeta,
          shortBreakMinutes.isAcceptableOrUnknown(
              data['short_break_minutes']!, _shortBreakMinutesMeta));
    }
    if (data.containsKey('long_break_minutes')) {
      context.handle(
          _longBreakMinutesMeta,
          longBreakMinutes.isAcceptableOrUnknown(
              data['long_break_minutes']!, _longBreakMinutesMeta));
    }
    if (data.containsKey('rounds_before_long_break')) {
      context.handle(
          _roundsBeforeLongBreakMeta,
          roundsBeforeLongBreak.isAcceptableOrUnknown(
              data['rounds_before_long_break']!, _roundsBeforeLongBreakMeta));
    }
    if (data.containsKey('auto_start_breaks')) {
      context.handle(
          _autoStartBreaksMeta,
          autoStartBreaks.isAcceptableOrUnknown(
              data['auto_start_breaks']!, _autoStartBreaksMeta));
    }
    if (data.containsKey('auto_start_focus')) {
      context.handle(
          _autoStartFocusMeta,
          autoStartFocus.isAcceptableOrUnknown(
              data['auto_start_focus']!, _autoStartFocusMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  TimerSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerSettingsRow(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      focusMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}focus_minutes'])!,
      shortBreakMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}short_break_minutes'])!,
      longBreakMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}long_break_minutes'])!,
      roundsBeforeLongBreak: attachedDatabase.typeMapping.read(DriftSqlType.int,
          data['${effectivePrefix}rounds_before_long_break'])!,
      autoStartBreaks: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}auto_start_breaks'])!,
      autoStartFocus: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}auto_start_focus'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TimerSettingsTableTable createAlias(String alias) {
    return $TimerSettingsTableTable(attachedDatabase, alias);
  }
}

class TimerSettingsRow extends DataClass
    implements Insertable<TimerSettingsRow> {
  final String accountId;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int roundsBeforeLongBreak;
  final bool autoStartBreaks;
  final bool autoStartFocus;
  final DateTime updatedAt;
  const TimerSettingsRow(
      {required this.accountId,
      required this.focusMinutes,
      required this.shortBreakMinutes,
      required this.longBreakMinutes,
      required this.roundsBeforeLongBreak,
      required this.autoStartBreaks,
      required this.autoStartFocus,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['focus_minutes'] = Variable<int>(focusMinutes);
    map['short_break_minutes'] = Variable<int>(shortBreakMinutes);
    map['long_break_minutes'] = Variable<int>(longBreakMinutes);
    map['rounds_before_long_break'] = Variable<int>(roundsBeforeLongBreak);
    map['auto_start_breaks'] = Variable<bool>(autoStartBreaks);
    map['auto_start_focus'] = Variable<bool>(autoStartFocus);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimerSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return TimerSettingsTableCompanion(
      accountId: Value(accountId),
      focusMinutes: Value(focusMinutes),
      shortBreakMinutes: Value(shortBreakMinutes),
      longBreakMinutes: Value(longBreakMinutes),
      roundsBeforeLongBreak: Value(roundsBeforeLongBreak),
      autoStartBreaks: Value(autoStartBreaks),
      autoStartFocus: Value(autoStartFocus),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimerSettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerSettingsRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      focusMinutes: serializer.fromJson<int>(json['focusMinutes']),
      shortBreakMinutes: serializer.fromJson<int>(json['shortBreakMinutes']),
      longBreakMinutes: serializer.fromJson<int>(json['longBreakMinutes']),
      roundsBeforeLongBreak:
          serializer.fromJson<int>(json['roundsBeforeLongBreak']),
      autoStartBreaks: serializer.fromJson<bool>(json['autoStartBreaks']),
      autoStartFocus: serializer.fromJson<bool>(json['autoStartFocus']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'focusMinutes': serializer.toJson<int>(focusMinutes),
      'shortBreakMinutes': serializer.toJson<int>(shortBreakMinutes),
      'longBreakMinutes': serializer.toJson<int>(longBreakMinutes),
      'roundsBeforeLongBreak': serializer.toJson<int>(roundsBeforeLongBreak),
      'autoStartBreaks': serializer.toJson<bool>(autoStartBreaks),
      'autoStartFocus': serializer.toJson<bool>(autoStartFocus),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimerSettingsRow copyWith(
          {String? accountId,
          int? focusMinutes,
          int? shortBreakMinutes,
          int? longBreakMinutes,
          int? roundsBeforeLongBreak,
          bool? autoStartBreaks,
          bool? autoStartFocus,
          DateTime? updatedAt}) =>
      TimerSettingsRow(
        accountId: accountId ?? this.accountId,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
        longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
        roundsBeforeLongBreak:
            roundsBeforeLongBreak ?? this.roundsBeforeLongBreak,
        autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
        autoStartFocus: autoStartFocus ?? this.autoStartFocus,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TimerSettingsRow copyWithCompanion(TimerSettingsTableCompanion data) {
    return TimerSettingsRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      focusMinutes: data.focusMinutes.present
          ? data.focusMinutes.value
          : this.focusMinutes,
      shortBreakMinutes: data.shortBreakMinutes.present
          ? data.shortBreakMinutes.value
          : this.shortBreakMinutes,
      longBreakMinutes: data.longBreakMinutes.present
          ? data.longBreakMinutes.value
          : this.longBreakMinutes,
      roundsBeforeLongBreak: data.roundsBeforeLongBreak.present
          ? data.roundsBeforeLongBreak.value
          : this.roundsBeforeLongBreak,
      autoStartBreaks: data.autoStartBreaks.present
          ? data.autoStartBreaks.value
          : this.autoStartBreaks,
      autoStartFocus: data.autoStartFocus.present
          ? data.autoStartFocus.value
          : this.autoStartFocus,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerSettingsRow(')
          ..write('accountId: $accountId, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('shortBreakMinutes: $shortBreakMinutes, ')
          ..write('longBreakMinutes: $longBreakMinutes, ')
          ..write('roundsBeforeLongBreak: $roundsBeforeLongBreak, ')
          ..write('autoStartBreaks: $autoStartBreaks, ')
          ..write('autoStartFocus: $autoStartFocus, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      accountId,
      focusMinutes,
      shortBreakMinutes,
      longBreakMinutes,
      roundsBeforeLongBreak,
      autoStartBreaks,
      autoStartFocus,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerSettingsRow &&
          other.accountId == this.accountId &&
          other.focusMinutes == this.focusMinutes &&
          other.shortBreakMinutes == this.shortBreakMinutes &&
          other.longBreakMinutes == this.longBreakMinutes &&
          other.roundsBeforeLongBreak == this.roundsBeforeLongBreak &&
          other.autoStartBreaks == this.autoStartBreaks &&
          other.autoStartFocus == this.autoStartFocus &&
          other.updatedAt == this.updatedAt);
}

class TimerSettingsTableCompanion extends UpdateCompanion<TimerSettingsRow> {
  final Value<String> accountId;
  final Value<int> focusMinutes;
  final Value<int> shortBreakMinutes;
  final Value<int> longBreakMinutes;
  final Value<int> roundsBeforeLongBreak;
  final Value<bool> autoStartBreaks;
  final Value<bool> autoStartFocus;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TimerSettingsTableCompanion({
    this.accountId = const Value.absent(),
    this.focusMinutes = const Value.absent(),
    this.shortBreakMinutes = const Value.absent(),
    this.longBreakMinutes = const Value.absent(),
    this.roundsBeforeLongBreak = const Value.absent(),
    this.autoStartBreaks = const Value.absent(),
    this.autoStartFocus = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerSettingsTableCompanion.insert({
    required String accountId,
    this.focusMinutes = const Value.absent(),
    this.shortBreakMinutes = const Value.absent(),
    this.longBreakMinutes = const Value.absent(),
    this.roundsBeforeLongBreak = const Value.absent(),
    this.autoStartBreaks = const Value.absent(),
    this.autoStartFocus = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        updatedAt = Value(updatedAt);
  static Insertable<TimerSettingsRow> custom({
    Expression<String>? accountId,
    Expression<int>? focusMinutes,
    Expression<int>? shortBreakMinutes,
    Expression<int>? longBreakMinutes,
    Expression<int>? roundsBeforeLongBreak,
    Expression<bool>? autoStartBreaks,
    Expression<bool>? autoStartFocus,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (focusMinutes != null) 'focus_minutes': focusMinutes,
      if (shortBreakMinutes != null) 'short_break_minutes': shortBreakMinutes,
      if (longBreakMinutes != null) 'long_break_minutes': longBreakMinutes,
      if (roundsBeforeLongBreak != null)
        'rounds_before_long_break': roundsBeforeLongBreak,
      if (autoStartBreaks != null) 'auto_start_breaks': autoStartBreaks,
      if (autoStartFocus != null) 'auto_start_focus': autoStartFocus,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerSettingsTableCompanion copyWith(
      {Value<String>? accountId,
      Value<int>? focusMinutes,
      Value<int>? shortBreakMinutes,
      Value<int>? longBreakMinutes,
      Value<int>? roundsBeforeLongBreak,
      Value<bool>? autoStartBreaks,
      Value<bool>? autoStartFocus,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TimerSettingsTableCompanion(
      accountId: accountId ?? this.accountId,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      roundsBeforeLongBreak:
          roundsBeforeLongBreak ?? this.roundsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (focusMinutes.present) {
      map['focus_minutes'] = Variable<int>(focusMinutes.value);
    }
    if (shortBreakMinutes.present) {
      map['short_break_minutes'] = Variable<int>(shortBreakMinutes.value);
    }
    if (longBreakMinutes.present) {
      map['long_break_minutes'] = Variable<int>(longBreakMinutes.value);
    }
    if (roundsBeforeLongBreak.present) {
      map['rounds_before_long_break'] =
          Variable<int>(roundsBeforeLongBreak.value);
    }
    if (autoStartBreaks.present) {
      map['auto_start_breaks'] = Variable<bool>(autoStartBreaks.value);
    }
    if (autoStartFocus.present) {
      map['auto_start_focus'] = Variable<bool>(autoStartFocus.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerSettingsTableCompanion(')
          ..write('accountId: $accountId, ')
          ..write('focusMinutes: $focusMinutes, ')
          ..write('shortBreakMinutes: $shortBreakMinutes, ')
          ..write('longBreakMinutes: $longBreakMinutes, ')
          ..write('roundsBeforeLongBreak: $roundsBeforeLongBreak, ')
          ..write('autoStartBreaks: $autoStartBreaks, ')
          ..write('autoStartFocus: $autoStartFocus, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TimerStatesTable extends TimerStates
    with TableInfo<$TimerStatesTable, TimerState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TimerStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _activityIdMeta =
      const VerificationMeta('activityId');
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
      'activity_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phaseIndexMeta =
      const VerificationMeta('phaseIndex');
  @override
  late final GeneratedColumn<int> phaseIndex = GeneratedColumn<int>(
      'phase_index', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
      'ends_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
      'paused', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("paused" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _remainingMsMeta =
      const VerificationMeta('remainingMs');
  @override
  late final GeneratedColumn<int> remainingMs = GeneratedColumn<int>(
      'remaining_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        accountId,
        activityId,
        kind,
        phaseIndex,
        startedAt,
        endsAt,
        paused,
        remainingMs,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'timer_states';
  @override
  VerificationContext validateIntegrity(Insertable<TimerState> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
          _activityIdMeta,
          activityId.isAcceptableOrUnknown(
              data['activity_id']!, _activityIdMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('phase_index')) {
      context.handle(
          _phaseIndexMeta,
          phaseIndex.isAcceptableOrUnknown(
              data['phase_index']!, _phaseIndexMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('ends_at')) {
      context.handle(_endsAtMeta,
          endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta));
    }
    if (data.containsKey('paused')) {
      context.handle(_pausedMeta,
          paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta));
    }
    if (data.containsKey('remaining_ms')) {
      context.handle(
          _remainingMsMeta,
          remainingMs.isAcceptableOrUnknown(
              data['remaining_ms']!, _remainingMsMeta));
    } else if (isInserting) {
      context.missing(_remainingMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  TimerState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TimerState(
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      activityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}activity_id']),
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      phaseIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}phase_index'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      endsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ends_at']),
      paused: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}paused'])!,
      remainingMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remaining_ms'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TimerStatesTable createAlias(String alias) {
    return $TimerStatesTable(attachedDatabase, alias);
  }
}

class TimerState extends DataClass implements Insertable<TimerState> {
  final String accountId;
  final String? activityId;
  final String kind;
  final int phaseIndex;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final bool paused;
  final int remainingMs;
  final DateTime updatedAt;
  const TimerState(
      {required this.accountId,
      this.activityId,
      required this.kind,
      required this.phaseIndex,
      this.startedAt,
      this.endsAt,
      required this.paused,
      required this.remainingMs,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || activityId != null) {
      map['activity_id'] = Variable<String>(activityId);
    }
    map['kind'] = Variable<String>(kind);
    map['phase_index'] = Variable<int>(phaseIndex);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || endsAt != null) {
      map['ends_at'] = Variable<DateTime>(endsAt);
    }
    map['paused'] = Variable<bool>(paused);
    map['remaining_ms'] = Variable<int>(remainingMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TimerStatesCompanion toCompanion(bool nullToAbsent) {
    return TimerStatesCompanion(
      accountId: Value(accountId),
      activityId: activityId == null && nullToAbsent
          ? const Value.absent()
          : Value(activityId),
      kind: Value(kind),
      phaseIndex: Value(phaseIndex),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      endsAt:
          endsAt == null && nullToAbsent ? const Value.absent() : Value(endsAt),
      paused: Value(paused),
      remainingMs: Value(remainingMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory TimerState.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TimerState(
      accountId: serializer.fromJson<String>(json['accountId']),
      activityId: serializer.fromJson<String?>(json['activityId']),
      kind: serializer.fromJson<String>(json['kind']),
      phaseIndex: serializer.fromJson<int>(json['phaseIndex']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      endsAt: serializer.fromJson<DateTime?>(json['endsAt']),
      paused: serializer.fromJson<bool>(json['paused']),
      remainingMs: serializer.fromJson<int>(json['remainingMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'activityId': serializer.toJson<String?>(activityId),
      'kind': serializer.toJson<String>(kind),
      'phaseIndex': serializer.toJson<int>(phaseIndex),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'endsAt': serializer.toJson<DateTime?>(endsAt),
      'paused': serializer.toJson<bool>(paused),
      'remainingMs': serializer.toJson<int>(remainingMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TimerState copyWith(
          {String? accountId,
          Value<String?> activityId = const Value.absent(),
          String? kind,
          int? phaseIndex,
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> endsAt = const Value.absent(),
          bool? paused,
          int? remainingMs,
          DateTime? updatedAt}) =>
      TimerState(
        accountId: accountId ?? this.accountId,
        activityId: activityId.present ? activityId.value : this.activityId,
        kind: kind ?? this.kind,
        phaseIndex: phaseIndex ?? this.phaseIndex,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        endsAt: endsAt.present ? endsAt.value : this.endsAt,
        paused: paused ?? this.paused,
        remainingMs: remainingMs ?? this.remainingMs,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TimerState copyWithCompanion(TimerStatesCompanion data) {
    return TimerState(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      activityId:
          data.activityId.present ? data.activityId.value : this.activityId,
      kind: data.kind.present ? data.kind.value : this.kind,
      phaseIndex:
          data.phaseIndex.present ? data.phaseIndex.value : this.phaseIndex,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      paused: data.paused.present ? data.paused.value : this.paused,
      remainingMs:
          data.remainingMs.present ? data.remainingMs.value : this.remainingMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TimerState(')
          ..write('accountId: $accountId, ')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('phaseIndex: $phaseIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('paused: $paused, ')
          ..write('remainingMs: $remainingMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, activityId, kind, phaseIndex,
      startedAt, endsAt, paused, remainingMs, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TimerState &&
          other.accountId == this.accountId &&
          other.activityId == this.activityId &&
          other.kind == this.kind &&
          other.phaseIndex == this.phaseIndex &&
          other.startedAt == this.startedAt &&
          other.endsAt == this.endsAt &&
          other.paused == this.paused &&
          other.remainingMs == this.remainingMs &&
          other.updatedAt == this.updatedAt);
}

class TimerStatesCompanion extends UpdateCompanion<TimerState> {
  final Value<String> accountId;
  final Value<String?> activityId;
  final Value<String> kind;
  final Value<int> phaseIndex;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> endsAt;
  final Value<bool> paused;
  final Value<int> remainingMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TimerStatesCompanion({
    this.accountId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.kind = const Value.absent(),
    this.phaseIndex = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.paused = const Value.absent(),
    this.remainingMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TimerStatesCompanion.insert({
    required String accountId,
    this.activityId = const Value.absent(),
    required String kind,
    this.phaseIndex = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.paused = const Value.absent(),
    required int remainingMs,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : accountId = Value(accountId),
        kind = Value(kind),
        remainingMs = Value(remainingMs),
        updatedAt = Value(updatedAt);
  static Insertable<TimerState> custom({
    Expression<String>? accountId,
    Expression<String>? activityId,
    Expression<String>? kind,
    Expression<int>? phaseIndex,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endsAt,
    Expression<bool>? paused,
    Expression<int>? remainingMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (activityId != null) 'activity_id': activityId,
      if (kind != null) 'kind': kind,
      if (phaseIndex != null) 'phase_index': phaseIndex,
      if (startedAt != null) 'started_at': startedAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (paused != null) 'paused': paused,
      if (remainingMs != null) 'remaining_ms': remainingMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TimerStatesCompanion copyWith(
      {Value<String>? accountId,
      Value<String?>? activityId,
      Value<String>? kind,
      Value<int>? phaseIndex,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? endsAt,
      Value<bool>? paused,
      Value<int>? remainingMs,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TimerStatesCompanion(
      accountId: accountId ?? this.accountId,
      activityId: activityId ?? this.activityId,
      kind: kind ?? this.kind,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      paused: paused ?? this.paused,
      remainingMs: remainingMs ?? this.remainingMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (phaseIndex.present) {
      map['phase_index'] = Variable<int>(phaseIndex.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (remainingMs.present) {
      map['remaining_ms'] = Variable<int>(remainingMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TimerStatesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('activityId: $activityId, ')
          ..write('kind: $kind, ')
          ..write('phaseIndex: $phaseIndex, ')
          ..write('startedAt: $startedAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('paused: $paused, ')
          ..write('remainingMs: $remainingMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $ActivitiesTable activities = $ActivitiesTable(this);
  late final $TimeBlocksTable timeBlocks = $TimeBlocksTable(this);
  late final $TimerSettingsTableTable timerSettingsTable =
      $TimerSettingsTableTable(this);
  late final $TimerStatesTable timerStates = $TimerStatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [accounts, activities, timeBlocks, timerSettingsTable, timerStates];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String username,
  Value<bool> selected,
  Value<String?> syncCursor,
  required DateTime lastUsedAt,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> username,
  Value<bool> selected,
  Value<String?> syncCursor,
  Value<DateTime> lastUsedAt,
  Value<int> rowid,
});

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get selected => $composableBuilder(
      column: $table.selected, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get syncCursor => $composableBuilder(
      column: $table.syncCursor, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnFilters(column));
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get selected => $composableBuilder(
      column: $table.selected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get syncCursor => $composableBuilder(
      column: $table.syncCursor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<bool> get selected =>
      $composableBuilder(column: $table.selected, builder: (column) => column);

  GeneratedColumn<String> get syncCursor => $composableBuilder(
      column: $table.syncCursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastUsedAt => $composableBuilder(
      column: $table.lastUsedAt, builder: (column) => column);
}

class $$AccountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()> {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<bool> selected = const Value.absent(),
            Value<String?> syncCursor = const Value.absent(),
            Value<DateTime> lastUsedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            username: username,
            selected: selected,
            syncCursor: syncCursor,
            lastUsedAt: lastUsedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String username,
            Value<bool> selected = const Value.absent(),
            Value<String?> syncCursor = const Value.absent(),
            required DateTime lastUsedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            username: username,
            selected: selected,
            syncCursor: syncCursor,
            lastUsedAt: lastUsedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
    Account,
    PrefetchHooks Function()>;
typedef $$ActivitiesTableCreateCompanionBuilder = ActivitiesCompanion Function({
  required String id,
  required String accountId,
  required String name,
  required int color,
  Value<bool> archived,
  Value<bool> deleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ActivitiesTableUpdateCompanionBuilder = ActivitiesCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> name,
  Value<int> color,
  Value<bool> archived,
  Value<bool> deleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ActivitiesTableFilterComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ActivitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get archived => $composableBuilder(
      column: $table.archived, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ActivitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivitiesTable> {
  $$ActivitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ActivitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    ActivityRow,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (ActivityRow, BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>),
    ActivityRow,
    PrefetchHooks Function()> {
  $$ActivitiesTableTableManager(_$AppDatabase db, $ActivitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> color = const Value.absent(),
            Value<bool> archived = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesCompanion(
            id: id,
            accountId: accountId,
            name: name,
            color: color,
            archived: archived,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required String name,
            required int color,
            Value<bool> archived = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ActivitiesCompanion.insert(
            id: id,
            accountId: accountId,
            name: name,
            color: color,
            archived: archived,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ActivitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ActivitiesTable,
    ActivityRow,
    $$ActivitiesTableFilterComposer,
    $$ActivitiesTableOrderingComposer,
    $$ActivitiesTableAnnotationComposer,
    $$ActivitiesTableCreateCompanionBuilder,
    $$ActivitiesTableUpdateCompanionBuilder,
    (ActivityRow, BaseReferences<_$AppDatabase, $ActivitiesTable, ActivityRow>),
    ActivityRow,
    PrefetchHooks Function()>;
typedef $$TimeBlocksTableCreateCompanionBuilder = TimeBlocksCompanion Function({
  required String id,
  required String accountId,
  required String activityId,
  required String kind,
  required DateTime start,
  required DateTime end,
  required String status,
  Value<bool> deleted,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TimeBlocksTableUpdateCompanionBuilder = TimeBlocksCompanion Function({
  Value<String> id,
  Value<String> accountId,
  Value<String> activityId,
  Value<String> kind,
  Value<DateTime> start,
  Value<DateTime> end,
  Value<String> status,
  Value<bool> deleted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TimeBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TimeBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get deleted => $composableBuilder(
      column: $table.deleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TimeBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimeBlocksTable> {
  $$TimeBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TimeBlocksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimeBlocksTable,
    TimeBlockRow,
    $$TimeBlocksTableFilterComposer,
    $$TimeBlocksTableOrderingComposer,
    $$TimeBlocksTableAnnotationComposer,
    $$TimeBlocksTableCreateCompanionBuilder,
    $$TimeBlocksTableUpdateCompanionBuilder,
    (
      TimeBlockRow,
      BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlockRow>
    ),
    TimeBlockRow,
    PrefetchHooks Function()> {
  $$TimeBlocksTableTableManager(_$AppDatabase db, $TimeBlocksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimeBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimeBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimeBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> activityId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<DateTime> start = const Value.absent(),
            Value<DateTime> end = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> deleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBlocksCompanion(
            id: id,
            accountId: accountId,
            activityId: activityId,
            kind: kind,
            start: start,
            end: end,
            status: status,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String accountId,
            required String activityId,
            required String kind,
            required DateTime start,
            required DateTime end,
            required String status,
            Value<bool> deleted = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimeBlocksCompanion.insert(
            id: id,
            accountId: accountId,
            activityId: activityId,
            kind: kind,
            start: start,
            end: end,
            status: status,
            deleted: deleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimeBlocksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimeBlocksTable,
    TimeBlockRow,
    $$TimeBlocksTableFilterComposer,
    $$TimeBlocksTableOrderingComposer,
    $$TimeBlocksTableAnnotationComposer,
    $$TimeBlocksTableCreateCompanionBuilder,
    $$TimeBlocksTableUpdateCompanionBuilder,
    (
      TimeBlockRow,
      BaseReferences<_$AppDatabase, $TimeBlocksTable, TimeBlockRow>
    ),
    TimeBlockRow,
    PrefetchHooks Function()>;
typedef $$TimerSettingsTableTableCreateCompanionBuilder
    = TimerSettingsTableCompanion Function({
  required String accountId,
  Value<int> focusMinutes,
  Value<int> shortBreakMinutes,
  Value<int> longBreakMinutes,
  Value<int> roundsBeforeLongBreak,
  Value<bool> autoStartBreaks,
  Value<bool> autoStartFocus,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TimerSettingsTableTableUpdateCompanionBuilder
    = TimerSettingsTableCompanion Function({
  Value<String> accountId,
  Value<int> focusMinutes,
  Value<int> shortBreakMinutes,
  Value<int> longBreakMinutes,
  Value<int> roundsBeforeLongBreak,
  Value<bool> autoStartBreaks,
  Value<bool> autoStartFocus,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TimerSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TimerSettingsTableTable> {
  $$TimerSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get focusMinutes => $composableBuilder(
      column: $table.focusMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get shortBreakMinutes => $composableBuilder(
      column: $table.shortBreakMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get longBreakMinutes => $composableBuilder(
      column: $table.longBreakMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get roundsBeforeLongBreak => $composableBuilder(
      column: $table.roundsBeforeLongBreak,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoStartBreaks => $composableBuilder(
      column: $table.autoStartBreaks,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get autoStartFocus => $composableBuilder(
      column: $table.autoStartFocus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TimerSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerSettingsTableTable> {
  $$TimerSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get focusMinutes => $composableBuilder(
      column: $table.focusMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get shortBreakMinutes => $composableBuilder(
      column: $table.shortBreakMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get longBreakMinutes => $composableBuilder(
      column: $table.longBreakMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get roundsBeforeLongBreak => $composableBuilder(
      column: $table.roundsBeforeLongBreak,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoStartBreaks => $composableBuilder(
      column: $table.autoStartBreaks,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get autoStartFocus => $composableBuilder(
      column: $table.autoStartFocus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TimerSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerSettingsTableTable> {
  $$TimerSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get focusMinutes => $composableBuilder(
      column: $table.focusMinutes, builder: (column) => column);

  GeneratedColumn<int> get shortBreakMinutes => $composableBuilder(
      column: $table.shortBreakMinutes, builder: (column) => column);

  GeneratedColumn<int> get longBreakMinutes => $composableBuilder(
      column: $table.longBreakMinutes, builder: (column) => column);

  GeneratedColumn<int> get roundsBeforeLongBreak => $composableBuilder(
      column: $table.roundsBeforeLongBreak, builder: (column) => column);

  GeneratedColumn<bool> get autoStartBreaks => $composableBuilder(
      column: $table.autoStartBreaks, builder: (column) => column);

  GeneratedColumn<bool> get autoStartFocus => $composableBuilder(
      column: $table.autoStartFocus, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TimerSettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimerSettingsTableTable,
    TimerSettingsRow,
    $$TimerSettingsTableTableFilterComposer,
    $$TimerSettingsTableTableOrderingComposer,
    $$TimerSettingsTableTableAnnotationComposer,
    $$TimerSettingsTableTableCreateCompanionBuilder,
    $$TimerSettingsTableTableUpdateCompanionBuilder,
    (
      TimerSettingsRow,
      BaseReferences<_$AppDatabase, $TimerSettingsTableTable, TimerSettingsRow>
    ),
    TimerSettingsRow,
    PrefetchHooks Function()> {
  $$TimerSettingsTableTableTableManager(
      _$AppDatabase db, $TimerSettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerSettingsTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> accountId = const Value.absent(),
            Value<int> focusMinutes = const Value.absent(),
            Value<int> shortBreakMinutes = const Value.absent(),
            Value<int> longBreakMinutes = const Value.absent(),
            Value<int> roundsBeforeLongBreak = const Value.absent(),
            Value<bool> autoStartBreaks = const Value.absent(),
            Value<bool> autoStartFocus = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerSettingsTableCompanion(
            accountId: accountId,
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            roundsBeforeLongBreak: roundsBeforeLongBreak,
            autoStartBreaks: autoStartBreaks,
            autoStartFocus: autoStartFocus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String accountId,
            Value<int> focusMinutes = const Value.absent(),
            Value<int> shortBreakMinutes = const Value.absent(),
            Value<int> longBreakMinutes = const Value.absent(),
            Value<int> roundsBeforeLongBreak = const Value.absent(),
            Value<bool> autoStartBreaks = const Value.absent(),
            Value<bool> autoStartFocus = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerSettingsTableCompanion.insert(
            accountId: accountId,
            focusMinutes: focusMinutes,
            shortBreakMinutes: shortBreakMinutes,
            longBreakMinutes: longBreakMinutes,
            roundsBeforeLongBreak: roundsBeforeLongBreak,
            autoStartBreaks: autoStartBreaks,
            autoStartFocus: autoStartFocus,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimerSettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimerSettingsTableTable,
    TimerSettingsRow,
    $$TimerSettingsTableTableFilterComposer,
    $$TimerSettingsTableTableOrderingComposer,
    $$TimerSettingsTableTableAnnotationComposer,
    $$TimerSettingsTableTableCreateCompanionBuilder,
    $$TimerSettingsTableTableUpdateCompanionBuilder,
    (
      TimerSettingsRow,
      BaseReferences<_$AppDatabase, $TimerSettingsTableTable, TimerSettingsRow>
    ),
    TimerSettingsRow,
    PrefetchHooks Function()>;
typedef $$TimerStatesTableCreateCompanionBuilder = TimerStatesCompanion
    Function({
  required String accountId,
  Value<String?> activityId,
  required String kind,
  Value<int> phaseIndex,
  Value<DateTime?> startedAt,
  Value<DateTime?> endsAt,
  Value<bool> paused,
  required int remainingMs,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TimerStatesTableUpdateCompanionBuilder = TimerStatesCompanion
    Function({
  Value<String> accountId,
  Value<String?> activityId,
  Value<String> kind,
  Value<int> phaseIndex,
  Value<DateTime?> startedAt,
  Value<DateTime?> endsAt,
  Value<bool> paused,
  Value<int> remainingMs,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TimerStatesTableFilterComposer
    extends Composer<_$AppDatabase, $TimerStatesTable> {
  $$TimerStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get phaseIndex => $composableBuilder(
      column: $table.phaseIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get paused => $composableBuilder(
      column: $table.paused, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remainingMs => $composableBuilder(
      column: $table.remainingMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$TimerStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TimerStatesTable> {
  $$TimerStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get phaseIndex => $composableBuilder(
      column: $table.phaseIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get paused => $composableBuilder(
      column: $table.paused, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remainingMs => $composableBuilder(
      column: $table.remainingMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$TimerStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TimerStatesTable> {
  $$TimerStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
      column: $table.activityId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get phaseIndex => $composableBuilder(
      column: $table.phaseIndex, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<int> get remainingMs => $composableBuilder(
      column: $table.remainingMs, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TimerStatesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TimerStatesTable,
    TimerState,
    $$TimerStatesTableFilterComposer,
    $$TimerStatesTableOrderingComposer,
    $$TimerStatesTableAnnotationComposer,
    $$TimerStatesTableCreateCompanionBuilder,
    $$TimerStatesTableUpdateCompanionBuilder,
    (TimerState, BaseReferences<_$AppDatabase, $TimerStatesTable, TimerState>),
    TimerState,
    PrefetchHooks Function()> {
  $$TimerStatesTableTableManager(_$AppDatabase db, $TimerStatesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TimerStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TimerStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TimerStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> accountId = const Value.absent(),
            Value<String?> activityId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> phaseIndex = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> endsAt = const Value.absent(),
            Value<bool> paused = const Value.absent(),
            Value<int> remainingMs = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerStatesCompanion(
            accountId: accountId,
            activityId: activityId,
            kind: kind,
            phaseIndex: phaseIndex,
            startedAt: startedAt,
            endsAt: endsAt,
            paused: paused,
            remainingMs: remainingMs,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String accountId,
            Value<String?> activityId = const Value.absent(),
            required String kind,
            Value<int> phaseIndex = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> endsAt = const Value.absent(),
            Value<bool> paused = const Value.absent(),
            required int remainingMs,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TimerStatesCompanion.insert(
            accountId: accountId,
            activityId: activityId,
            kind: kind,
            phaseIndex: phaseIndex,
            startedAt: startedAt,
            endsAt: endsAt,
            paused: paused,
            remainingMs: remainingMs,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TimerStatesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TimerStatesTable,
    TimerState,
    $$TimerStatesTableFilterComposer,
    $$TimerStatesTableOrderingComposer,
    $$TimerStatesTableAnnotationComposer,
    $$TimerStatesTableCreateCompanionBuilder,
    $$TimerStatesTableUpdateCompanionBuilder,
    (TimerState, BaseReferences<_$AppDatabase, $TimerStatesTable, TimerState>),
    TimerState,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$ActivitiesTableTableManager get activities =>
      $$ActivitiesTableTableManager(_db, _db.activities);
  $$TimeBlocksTableTableManager get timeBlocks =>
      $$TimeBlocksTableTableManager(_db, _db.timeBlocks);
  $$TimerSettingsTableTableTableManager get timerSettingsTable =>
      $$TimerSettingsTableTableTableManager(_db, _db.timerSettingsTable);
  $$TimerStatesTableTableManager get timerStates =>
      $$TimerStatesTableTableManager(_db, _db.timerStates);
}
