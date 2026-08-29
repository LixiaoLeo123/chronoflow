import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client})
      : _client = client ?? _pinnedClient(),
        _owned = client == null;

  static const baseUrl = String.fromEnvironment(
    'CHRONOFLOW_API_URL',
    defaultValue: 'https://javamc.top:9443',
  );

  /// SHA-256 of the deployment certificate, supplied at release build time:
  /// --dart-define=CHRONOFLOW_CERT_SHA256=...
  static const expectedCertificateSha256 = String.fromEnvironment(
    'CHRONOFLOW_CERT_SHA256',
  );
  static const allowUnpinned =
      bool.fromEnvironment('CHRONOFLOW_ALLOW_UNPINNED');

  final http.Client _client;
  final bool _owned;
  String? accessToken;

  static http.Client _pinnedClient() {
    final inner = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..badCertificateCallback = (certificate, host, port) {
        if (allowUnpinned && host == '127.0.0.1') return true;
        if (expectedCertificateSha256.isEmpty) return false;
        final digest = sha256.convert(certificate.der).toString();
        return digest ==
            expectedCertificateSha256.toLowerCase().replaceAll(':', '');
      };
    return IOClient(inner);
  }

  void close() {
    if (_owned) _client.close();
  }

  Future<Map<String, dynamic>> sync(Map<String, dynamic> body) =>
      post('/v1/sync', body, authenticated: true);

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (authenticated && accessToken != null)
          'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode,
          decoded['detail']?.toString() ?? 'Request failed');
    }
    return decoded;
  }
}
