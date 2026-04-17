import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cancion.model.dart';

class RepertorioService {
  // Cambia esto por tu IP real cuando pruebes en dispositivo físico.
  // En emulador Android usa 10.0.2.2, en iOS simulator usa localhost.
  static const String _baseUrl = 'http://localhost:3000';

  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── Obtener lista de canciones activas ────────────────────────────────────

  Future<List<Cancion>> getCanciones() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$_baseUrl/api/repertorio');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Cancion.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al cargar repertorio');
    }
  }

  // ── Buscar canciones ───────────────────────────────────────────────────────

  Future<List<Cancion>> buscarCanciones(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$_baseUrl/api/repertorio/search?q=${Uri.encodeComponent(query)}');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Cancion.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al buscar');
    }
  }

  // ── Detalle completo (con letra) ──────────────────────────────────────────

  Future<Cancion> getDetalle(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$_baseUrl/api/repertorio/$id');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Cancion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al cargar detalle');
    }
  }

  // ── Activar / Desactivar ──────────────────────────────────────────────────

  Future<Cancion> toggleCancion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$_baseUrl/api/repertorio/$id/toggle');
    final response = await http
        .patch(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return Cancion.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al cambiar estado');
    }
  }

  // ── Eliminar ──────────────────────────────────────────────────────────────

  Future<void> eliminarCancion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('$_baseUrl/api/repertorio/$id');
    final response = await http
        .delete(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al eliminar');
    }
  }
}