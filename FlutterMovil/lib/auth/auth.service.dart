import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // ─── Cambia esta constante según dónde corras la app ───────────────────────
  //  Emulador Android               → 'http://10.0.2.2:3000'
  //  Simulador iOS / Flutter Web    → 'http://localhost:3000'
  //  Dispositivo físico             → 'http://TU_IP_LOCAL:3000'
  //    (ej: ipconfig en Windows o ifconfig en Mac para ver tu IP)
  // ──────────────────────────────────────────────────────────────────────────
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
        return body;
      } else {
        throw Exception(body['message'] ?? 'Error al iniciar sesión');
      }
    } on Exception {
      rethrow;
    }
  }
}