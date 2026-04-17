import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String baseUrl = 'http://localhost:3000';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

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