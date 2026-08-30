import 'dart:async';

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
  bool _syncing = false;
  String? _account;
  String? _fingerprint;

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
    final account = _account;
    if (account == null || _syncing) return false;
    final before = await _engine._repository.fingerprint(account);
    if (!force && before == _fingerprint && _fingerprint != null) return true;
    _syncing = true;
    try {
      await _engine.synchronize(account);
      _fingerprint = await _engine._repository.fingerprint(account);
      return true;
    } catch (_) {
      _fingerprint = null;
      return false;
    } finally {
      _syncing = false;
    }
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
      response = await _request(accountId, sinceText, local);
    } on ApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      _client.accessToken = null;
      if (!await _authRepository.ensureAccessToken(accountId)) rethrow;
      response = await _request(accountId, sinceText, local);
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

  Future<Map<String, dynamic>> _request(
    String accountId,
    String? sinceText,
    SyncBundle local,
  ) =>
      _client.sync({
        'since': sinceText,
        'activities': local.activities.map((item) => item.toJson()).toList(),
        'timeBlocks': local.blocks.map((item) => item.toJson()).toList(),
      });
}
