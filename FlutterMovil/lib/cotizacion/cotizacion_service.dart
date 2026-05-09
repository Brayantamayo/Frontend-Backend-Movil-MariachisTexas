import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';
import '../core/utils/pdf_stub.dart'
    if (dart.library.html) '../core/utils/pdf_web.dart'
    if (dart.library.js_interop) '../core/utils/pdf_web.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class CotizacionService {
  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = prefs.getString('token');
    if (fromPrefs != null) return fromPrefs;
    // fallback a secure storage
    const storage = FlutterSecureStorage();
    return storage.read(key: 'token');
  }

  // ── Obtener todas las cotizaciones (JSON crudo) ────────────────────────────

  Future<List<Map<String, dynamic>>> getCotizacionesRaw() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones'));

    final response = await http
        .get(uri, headers: NetworkConfig.authHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      // Usar jsonDecode y luego iterar sin cast de tipo
      final dynamic decoded = jsonDecode(response.body);
      final result = <Map<String, dynamic>>[];
      for (final item in decoded) {
        final m = <String, dynamic>{};
        (item as Map).forEach((k, v) => m[k.toString()] = v);
        result.add(m);
      }
      return result;
    } else {
      throw Exception('Error al cargar cotizaciones');
    }
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
        if (data.isNotEmpty) {
          final primera = data.first as Map<String, dynamic>;
          print('=== DEBUG COTIZACION COMPLETA: $primera');
          print('=== DEBUG COTIZACION SERVICES: ${primera['services']}');
        }
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

  // ── Obtener detalle de cotización (JSON crudo) ────────────────────────────

  Future<Map<String, dynamic>> getCotizacionByIdRaw(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id'));

    final response = await http
        .get(uri, headers: NetworkConfig.authHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } else {
      throw Exception('Error al obtener detalle');
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
          .patch(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['message'] ?? 'Error al convertir a reserva');
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

        if (kIsWeb) {
          descargarEnWeb(bytes, 'cotizacion-$id.pdf');
          return;
        }

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

  // ── Actualizar cotización ──────────────────────────────────────────────────

  Future<void> actualizarCotizacion(
    int id, {
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required String homenajeado,
    required String tipoEvento,
    required DateTime fechaEvento,
    required String horaInicio,
    required String horaFin,
    required String ubicacion,
    required String notas,
    required List<Map<String, dynamic>> servicios,
    required double totalAmount,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones/$id'));
    final fechaStr =
        '${fechaEvento.year}-${fechaEvento.month.toString().padLeft(2, '0')}-${fechaEvento.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'clientName': clienteNombre,
      'clientEmail': clienteEmail,
      'clientPhone': clienteTelefono,
      'homenajeado': homenajeado,
      'eventType': tipoEvento,
      'eventDate': fechaStr,
      'startTime': horaInicio,
      'endTime': horaFin,
      'location': ubicacion,
      'notes': notas,
      'selectedServices': servicios,
      'totalAmount': totalAmount,
    });

    final response = await http
        .put(uri, headers: NetworkConfig.authHeaders(token), body: body)
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Error al actualizar cotización';
      try {
        msg = (jsonDecode(response.body) as Map)['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ── Crear cotización ───────────────────────────────────────────────────────

  Future<Cotizacion> crearCotizacion({
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required String homenajeado,
    required String tipoEvento,
    required DateTime fechaEvento,
    required String horaInicio,
    required String horaFin,
    required String ubicacion,
    required List<Map<String, dynamic>> servicios,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('cotizaciones'));

    final fechaStr =
        '${fechaEvento.year}-${fechaEvento.month.toString().padLeft(2, '0')}-${fechaEvento.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'clientName': clienteNombre,
      'clientEmail': clienteEmail,
      'clientPhone': clienteTelefono,
      'homenajeado': homenajeado,
      'eventType': tipoEvento,
      'eventDate': fechaStr,
      'startTime': horaInicio,
      'endTime': horaFin,
      'location': ubicacion,
      'services': servicios,
      'isDirectReservation': false,
    });

    try {
      final response = await http
          .post(uri, headers: NetworkConfig.authHeaders(token), body: body)
          .timeout(NetworkConfig.timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cotizacion.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorBody['message'] ?? 'Error al crear cotización');
      }
    } catch (e) {
      rethrow;
    }
  }
}
