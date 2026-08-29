import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  SecureSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _prefix = 'chronoflow.session.';

  Future<void> save(String accountId, String refreshToken) =>
      _storage.write(key: '$_prefix$accountId', value: refreshToken);

  Future<String?> read(String accountId) =>
      _storage.read(key: '$_prefix$accountId');

  Future<void> delete(String accountId) =>
      _storage.delete(key: '$_prefix$accountId');
}
