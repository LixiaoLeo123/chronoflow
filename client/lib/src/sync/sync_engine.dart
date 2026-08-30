import 'dart:async';
import 'dart:developer' as developer;

import '../api/api_client.dart';
import '../repositories/auth_repository.dart';
import '../models/domain.dart';
import 'sync_repository.dart';

class SyncCoordinator {
  SyncCoordinator(this._engine);

  final SyncEngine _engine;
  StreamSubscription<void>? _changes;
  StreamSubscription<dynamic>? _connectivity;
  Timer? _debounce;
  Timer? _periodic;
  String? _account;
  String? _fingerprint;
  Future<bool>? _activeSync;
  String? lastError;

  Future<void> start({
    required String accountId,
    required Stream<bool> connectivity,
  }) async {
    await stop();
    _account = accountId;
    _periodic =
        Timer.periodic(const Duration(minutes: 15), (_) => synchronize());
    _connectivity = connectivity.listen((available) {
      if (available) synchronize();
    });
    _changes = _engine._repository.changes().listen((_) => _debouncedSync());
    await synchronize();
  }

  Future<void> stop() async {
    _debounce?.cancel();
    _periodic?.cancel();
    await _changes?.cancel();
    await _connectivity?.cancel();
    _debounce = null;
    _periodic = null;
    _changes = null;
    _connectivity = null;
    _account = null;
    _fingerprint = null;
  }

  void _debouncedSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), synchronize);
  }

  Future<bool> synchronize({bool force = false}) async {
    return synchronizeFor(_account, force: force);
  }

  /// Runs a manual sync for [accountId], even if the shell has not finished
  /// starting its background coordinator yet. If another sync is in flight,
  /// wait for it instead of reporting a false failure to the settings page.
  Future<bool> synchronizeFor(String? accountId, {bool force = false}) async {
    final account = accountId;
    if (account == null) return false;
    final active = _activeSync;
    if (active != null) return active;
    final future = _runSync(account, force: force);
    _activeSync = future;
    try {
      return await future;
    } finally {
      if (identical(_activeSync, future)) _activeSync = null;
    }
  }

  Future<bool> _runSync(String account, {required bool force}) async {
    final before = await _engine._repository.fingerprint(account);
    if (!force && before == _fingerprint && _fingerprint != null) return true;
    try {
      await _engine.synchronize(account);
      _fingerprint = await _engine._repository.fingerprint(account);
      lastError = null;
      return true;
    } catch (error, stackTrace) {
      _fingerprint = null;
      lastError = error.toString();
      developer.log('Synchronize failed',
          name: 'chronoflow.sync', error: error, stackTrace: stackTrace);
      return false;
    } finally {}
  }
}

class SyncEngine {
  SyncEngine(this._repository, this._client, this._authRepository);

  final SyncRepository _repository;
  final ApiClient _client;
  final AuthRepository _authRepository;

  Future<void> synchronize(String accountId) async {
    if (!await _authRepository.ensureAccessToken(accountId)) {
      throw StateError('No authenticated session');
    }
    final sinceText = await _repository.cursor(accountId);
    final local = await _repository.localDelta(
        accountId, sinceText == null ? null : DateTime.parse(sinceText));
    Map<String, dynamic> response;
    try {
      response = await _request(local);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      _client.accessToken = null;
      if (!await _authRepository.ensureAccessToken(accountId)) rethrow;
      response = await _request(local);
    }
    await _repository.applyServer(
      SyncBundle(
        activities: (response['activities'] as List<dynamic>)
            .map((item) => Activity.fromJson(item as Map<String, dynamic>))
            .toList(),
        blocks: (response['timeBlocks'] as List<dynamic>)
            .map((item) => TimeBlock.fromJson(item as Map<String, dynamic>))
            .toList(),
        serverTime: DateTime.parse(response['serverTime'] as String),
      ),
    );
    await _repository.saveCursor(accountId, response['syncCursor'] as String);
  }

  Future<Map<String, dynamic>> _request(SyncBundle local) =>
      _client.sync({
        // Always request the complete server snapshot. A device can have a
        // clock ahead of the server (or have missed an earlier response), in
        // which case an incremental cursor would permanently hide older rows.
        // The payload is small and this guarantees both devices converge.
        'since': null,
        'activities': local.activities.map((item) => item.toJson()).toList(),
        'timeBlocks': local.blocks.map((item) => item.toJson()).toList(),
      });
}
