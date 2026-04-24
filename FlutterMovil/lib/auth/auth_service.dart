import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(Env.endpoint('auth/login'));

    final response = await http
        .post(
          uri,
          headers: NetworkConfig.commonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(NetworkConfig.timeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      // flutter_secure_storage en vez de SharedPreferences (más seguro para tokens)
      await _storage.write(key: 'token', value: body['token'] as String);
      return body;
    }

    throw Exception(body['message'] ?? 'Error al iniciar sesión');
  }

  Future<String?> getToken() => _storage.read(key: 'token');

  Future<void> clearToken() => _storage.delete(key: 'token');
}
