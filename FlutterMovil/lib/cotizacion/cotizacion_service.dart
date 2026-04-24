import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CotizacionService {
  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // ── Obtener todas las cotizaciones ─────────────────────────────────────────

  Future<List<Cotizacion>> getCotizaciones() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Cotizacion.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al cargar cotizaciones');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Buscar cotizaciones ────────────────────────────────────────────────────

  Future<List<Cotizacion>> buscarCotizaciones(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(
        Env.endpoint('cotizaciones/search?q=${Uri.encodeComponent(query)}'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => Cotizacion.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al buscar cotizaciones');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Obtener detalle de cotización ──────────────────────────────────────────

  Future<Cotizacion> getCotizacionById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        return Cotizacion.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Error al obtener detalle');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Convertir a reserva ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> convertirAReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id/convertir'));

    try {
      final response = await http
          .post(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al convertir a reserva');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Anular cotización ──────────────────────────────────────────────────────

  Future<void> anularCotizacion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id/anular'));

    try {
      final response = await http
          .patch(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al anular cotización');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Eliminar cotización ────────────────────────────────────────────────────

  Future<void> eliminarCotizacion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id'));

    try {
      final response = await http
          .delete(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar cotización');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── Descargar PDF ──────────────────────────────────────────────────────────

  Future<void> descargarPDF(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id/pdf'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // En móvil, guardar y abrir
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/cotizacion-$id.pdf');
          await file.writeAsBytes(bytes);
          await OpenFile.open(file.path);
        }
      } else {
        throw Exception('Error al descargar PDF');
      }
    } catch (e) {
      rethrow;
    }
  }
}
