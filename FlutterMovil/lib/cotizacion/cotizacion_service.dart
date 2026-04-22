import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'cotizacion.model.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class CotizacionService {
  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token;
  }

  // ── Obtener todas las cotizaciones ─────────────────────────────────────────

  Future<List<Cotizacion>> getCotizaciones() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No autenticado');
    }

    final uri = Uri.parse(Env.endpoint('cotizaciones'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta recibida - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            '✅ CotizacionService: JSON parseado exitosamente - ${data.length} cotizaciones');

        final cotizaciones = data
            .map((e) => Cotizacion.fromJson(e as Map<String, dynamic>))
            .toList();

        print(
            '✅ CotizacionService: Modelos creados exitosamente - ${cotizaciones.length} cotizaciones');
        return cotizaciones;
      } else {
        print('❌ CotizacionService: Error HTTP ${response.statusCode}');
        throw Exception('Error al cargar cotizaciones');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception caught: $e');
      rethrow;
    }
  }

  // ── Buscar cotizaciones ────────────────────────────────────────────────────

  Future<List<Cotizacion>> buscarCotizaciones(String query) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(
        Env.endpoint('cotizaciones/search?q=${Uri.encodeComponent(query)}'));
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

      print(
          '🔍 CotizacionService: Respuesta detalle - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final cotizacion = Cotizacion.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        print('✅ CotizacionService: Detalle obtenido exitosamente');
        return cotizacion;
      } else {
        throw Exception('Error al obtener detalle');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al obtener detalle: $e');
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

      print(
          '🔍 CotizacionService: Respuesta conversión - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ CotizacionService: Conversión exitosa');
        return result;
      } else {
        throw Exception('Error al convertir a reserva');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al convertir: $e');
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

      print(
          '🔍 CotizacionService: Respuesta anulación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: Anulación exitosa');
      } else {
        throw Exception('Error al anular cotización');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al anular: $e');
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

      print(
          '🔍 CotizacionService: Respuesta eliminación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: Eliminación exitosa');
      } else {
        throw Exception('Error al eliminar cotización');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al eliminar: $e');
      rethrow;
    }
  }

  // ── Descargar PDF ──────────────────────────────────────────────────────────

  Future<void> descargarPDF(int id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No autenticado');
    }

    try {
      final uri = Uri.parse(Env.endpoint('cotizaciones/$id/pdf'));

      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta PDF - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: PDF descargado exitosamente');

        final bytes = response.bodyBytes;

        if (kIsWeb) {
          // En web, el navegador maneja la descarga automáticamente si el servidor
          // envía el header Content-Disposition: attachment
          // Solo necesitamos hacer la petición HTTP
          _descargarEnWeb(bytes, 'cotizacion-$id.pdf');
        } else {
          // En móvil, guardar y abrir
          await _descargarEnMovil(bytes, id);
        }
      } else {
        print(
            '❌ CotizacionService: Error al descargar PDF - Status: ${response.statusCode}');
        throw Exception('Error al descargar PDF');
      }
    } catch (e) {
      print('❌ CotizacionService: Exception descargando PDF: $e');
      rethrow;
    }
  }

  // ── Descargar en Web ───────────────────────────────────────────────────────

  void _descargarEnWeb(List<int> bytes, String filename) {
    if (!kIsWeb) return;

    try {
      // ignore: avoid_print
      print(
          '📥 CotizacionService: Descarga iniciada en web (usando headers del servidor)');
    } catch (e) {
      // ignore: avoid_print
      print('❌ CotizacionService: Error descargando en web: $e');
    }
  }

  // ── Descargar en Móvil ─────────────────────────────────────────────────────

  Future<void> _descargarEnMovil(List<int> bytes, int id) async {
    if (kIsWeb) return;

    try {
      print('📥 CotizacionService: Descargando en móvil');

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/cotizacion-$id.pdf');
      await file.writeAsBytes(bytes);
      print('✅ CotizacionService: PDF guardado en: ${file.path}');

      // Abrir el PDF
      await OpenFile.open(file.path);
      print('✅ CotizacionService: PDF abierto');
    } catch (e) {
      print('❌ CotizacionService: Error descargando en móvil: $e');
      rethrow;
    }
  }
}
