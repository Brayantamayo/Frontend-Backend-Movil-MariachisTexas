import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/network_config.dart';
import 'package:mariachi_admin/core/models/app_models.dart';

class RepertorioService {
  static const _storage = FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'token');

  Map<String, String> _headers(String token) =>
      NetworkConfig.authHeaders(token);

////Obtener Lista de Canciones
Future<List<Cancion>> getCanciones() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/repertorio'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Cancion.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(res.body));
  }

////Obtener Canciones por búsqueda
Future<List<Cancion>> buscarCanciones(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(
            Uri.parse('${NetworkConfig.baseUrl}/api/repertorio/search?q=${Uri.encodeComponent(query)}'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Cancion.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(res.body));
  }


/// Obtener Detalle de una Canción
Future<Cancion> getDetalle(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        ////Obtener Detalle de una Canción
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/repertorio/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      return Cancion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(res.body));
  }

////Activar / Desactivar una Canción
Future<Cancion> toggleCancion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');
    final res = await http
        .patch(Uri.parse('${NetworkConfig.baseUrl}/api/repertorio/$id/toggle'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      return Cancion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(res.body));
  }

/// Eliminar una Canción
Future<void> eliminarCancion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .delete(Uri.parse('${NetworkConfig.baseUrl}/api/repertorio/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode != 200) throw Exception(_msg(res.body));
  }

  String _msg(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['message'] ?? 'Error desconocido';
    } catch (_) {
      return 'Error desconocido';
    }
  }
}