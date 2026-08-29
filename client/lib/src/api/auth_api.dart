import 'api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> login(String username, String password) =>
      _client
          .post('/v1/auth/login', {'username': username, 'password': password});

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String invitationCode,
  }) =>
      _client.post('/v1/auth/register', {
        'username': username,
        'password': password,
        'invitationCode': invitationCode,
      });

  Future<Map<String, dynamic>> refresh(String refreshToken) =>
      _client.post('/v1/auth/refresh', {'refreshToken': refreshToken});
}
