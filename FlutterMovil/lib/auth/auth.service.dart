import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/network_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Encontrar una URL que funcione
      String? baseUrl = await NetworkConfig.findWorkingUrl();
      if (baseUrl == null) {
        throw Exception(
            'No se puede conectar al servidor. Verifica que esté corriendo en localhost:3000');
      }

      final uri = Uri.parse('$baseUrl/api/auth/login');
      print('🔍 AuthService: Intentando login en: $uri');

      final response = await http
          .post(
            uri,
            headers: NetworkConfig.commonHeaders,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(NetworkConfig.timeout);

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        print('✅ AuthService: Login exitoso');

        // 🔥 AQUÍ GUARDAS EL TOKEN
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', body['token']);

        return body;
      } else {
        print('❌ AuthService: Error en login - Status: ${response.statusCode}');
        throw Exception(body['message'] ?? 'Error al iniciar sesión');
      }
    } on Exception {
      rethrow;
    }
  }
}
