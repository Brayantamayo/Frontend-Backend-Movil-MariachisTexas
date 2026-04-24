import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/network_config.dart';
import '../core/models/app_models.dart';

class EnsayoService {
  static const _storage = FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'token');

  Map<String, String> _headers(String token) =>
      NetworkConfig.authHeaders(token);

  String _msg(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['message'] ??
          'Error desconocido';
    } catch (_) {
      return 'Error desconocido';
    }
  }

  // ── GET todas los ensayos ─────────────────────────────────────────────────
  Future<List<Ensayo>> getEnsayos() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/ensayos'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data
          .map((e) => Ensayo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception(_msg(res.body));
  }

  // ── GET por ID ────────────────────────────────────────────────────────────
  Future<Ensayo> getEnsayoById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/ensayos/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      return Ensayo.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(res.body));
  }

  // ── PATCH toggle estado (pendiente ↔ listo) ──────────────────────────────
  Future<void> toggleEstado(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .patch(Uri.parse('${NetworkConfig.baseUrl}/api/ensayos/$id/toggle-estado'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode != 200) throw Exception(_msg(res.body));
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> eliminarEnsayo(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .delete(Uri.parse('${NetworkConfig.baseUrl}/api/ensayos/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode != 200) throw Exception(_msg(res.body));
  }
}
