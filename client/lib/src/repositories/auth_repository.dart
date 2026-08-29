import '../database/app_database.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import 'secure_session_store.dart';

class AuthRepository {
  AuthRepository(this._database, this._client, this._authApi, this._sessions);

  final AppDatabase _database;
  final ApiClient _client;
  final AuthApi _authApi;
  final SecureSessionStore _sessions;

  Future<List<Account>> accounts() => _database.allAccounts();

  Future<Account?> selectedAccount() => _database.selectedAccount();

  Future<Account> login(String username, String password) async {
    final response = await _authApi.login(username, password);
    return _persist(response);
  }

  Future<Account> register({
    required String username,
    required String password,
    required String invitationCode,
  }) async {
    final response = await _authApi.register(
      username: username,
      password: password,
      invitationCode: invitationCode,
    );
    return _persist(response);
  }

  Future<Account> _persist(Map<String, dynamic> response) async {
    final user = response['user'] as Map<String, dynamic>;
    final accountId = user['id'] as String;
    final now = DateTime.now();
    _client.accessToken = response['accessToken'] as String;
    await _sessions.save(accountId, response['refreshToken'] as String);
    final account = Account(
      id: accountId,
      username: user['username'] as String,
      selected: true,
      lastUsedAt: now,
    );
    await _database.upsertAccount(account.toCompanion(true));
    await _database.selectAccount(accountId);
    return account;
  }

  Future<String?> refreshTokenFor(String accountId) =>
      _sessions.read(accountId);

  Future<bool> ensureAccessToken(String accountId) async {
    if (_client.accessToken != null) return true;
    final refreshToken = await _sessions.read(accountId);
    if (refreshToken == null) return false;
    try {
      final response = await _authApi.refresh(refreshToken);
      _client.accessToken = response['accessToken'] as String;
      await _sessions.save(accountId, response['refreshToken'] as String);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _sessions.delete(accountId);
      }
      return false;
    }
  }

  Future<void> select(String accountId) => _database.selectAccount(accountId);

  Future<Map<String, dynamic>> createInvite(
    String accountId, {
    int daysValid = 7,
  }) async {
    if (!await ensureAccessToken(accountId)) {
      throw ApiException(0, 'Sign in again to create invitations');
    }
    return _authApi.createInvite(daysValid: daysValid);
  }

  Future<void> logout(String accountId) async {
    await _sessions.delete(accountId);
    _client.accessToken = null;
    await _database.clearSelectedAccount();
  }

  Future<void> forget(String accountId) async {
    await _sessions.delete(accountId);
    await (_database.delete(_database.accounts)
          ..where((row) => row.id.equals(accountId)))
        .go();
  }
}
