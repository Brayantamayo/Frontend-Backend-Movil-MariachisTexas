import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
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
        // 🔥 AQUÍ GUARDAS EL TOKEN
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['token']);

        return body;
      } else {
        throw Exception(body['message'] ?? 'Error al iniciar sesión');
      }
    } on Exception {
      rethrow;
    }
  }
}
