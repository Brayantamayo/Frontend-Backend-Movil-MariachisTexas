import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class VentaService {
  static const _storage = FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'token');

  Map<String, String> _buildHeaders(String token) =>
      NetworkConfig.authHeaders(token);

  String _extractErrorMessage(http.Response response) {
    if (response.body.trim().startsWith('<')) {
      return 'El servidor devolvió una respuesta inesperada (${response.statusCode})';
    }
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message']?.toString() ?? 'Error ${response.statusCode}';
    } catch (_) {
      return 'Respuesta inválida del servidor (${response.statusCode})';
    }
  }

  Future<List<Venta>> obtenerVentas() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('ventas'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // El backend puede devolver [] directamente o { data: [], ventas: [], ... }
      final List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map) {
        // Buscar la primera clave que sea una lista
        final listEntry = decoded.values.whereType<List>().firstOrNull;
        if (listEntry != null) {
          data = listEntry;
        } else {
          // El objeto mismo es una sola venta
          return [Venta.fromJson(decoded as Map<String, dynamic>)];
        }
      } else {
        throw Exception('Formato de respuesta inesperado del servidor');
      }

      return data
          .map((e) => Venta.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }

  Future<List<Venta>> buscarVentas(String query) async {
    final ventas = await obtenerVentas();
    final q = query.toLowerCase().trim();
    return ventas
        .where((v) =>
            v.clienteNombre.toLowerCase().contains(q) ||
            v.clienteEmail.toLowerCase().contains(q) ||
            v.clienteTelefono.contains(q))
        .toList();
  }

  Future<Venta> obtenerVentaById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('ventas/$id'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Venta.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    // Si no existe endpoint de detalle, buscar en la lista
    if (response.statusCode == 404) {
      final todas = await obtenerVentas();
      final venta = todas.where((v) => v.id == id).firstOrNull;
      if (venta != null) return venta;
    }

    throw Exception(_extractErrorMessage(response));
  }
}
