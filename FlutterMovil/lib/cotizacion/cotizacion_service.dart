import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'cotizacion.model.dart';
import '../core/config/network_config.dart';

class CotizacionService {
  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print(
        '🔍 CotizacionService: Retrieved token: ${token?.substring(0, 20) ?? 'null'}...');
    return token;
  }

  // ── Obtener todas las cotizaciones ─────────────────────────────────────────

  Future<List<Cotizacion>> getCotizaciones() async {
    print('🔍 CotizacionService: Iniciando getCotizaciones()');

    final token = await _getToken();
    if (token == null) {
      print('❌ CotizacionService: No hay token, usuario no autenticado');
      throw Exception('No autenticado');
    }

    // Intentar encontrar una URL que funcione
    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception(
          'No se puede conectar al servidor. Verifica que esté corriendo en localhost:3000');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones');
    print('🔍 CotizacionService: Haciendo petición a: $uri');

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta recibida - Status: ${response.statusCode}');
      print(
          '🔍 CotizacionService: Content-Type: ${response.headers['content-type']}');
      print('🔍 CotizacionService: Body length: ${response.body.length}');

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
        print(
            '❌ CotizacionService: Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

        // Si la respuesta parece HTML, no intentar parsear como JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de JSON. Verifica que el backend esté corriendo correctamente en localhost:3000');
        }

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al cargar cotizaciones');
        } catch (e) {
          throw Exception(
              'Respuesta inválida del servidor: ${response.statusCode}');
        }
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

    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse(
        '$workingUrl/api/cotizaciones/search?q=${Uri.encodeComponent(query)}');
    final response = await http
        .get(uri, headers: NetworkConfig.authHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => Cotizacion.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al buscar cotizaciones');
    }
  }

  // ── Obtener detalle de cotización ──────────────────────────────────────────

  Future<Cotizacion> getCotizacionById(int id) async {
    print('🔍 CotizacionService: Obteniendo detalle de cotización $id');

    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id');
    print('🔍 CotizacionService: Haciendo petición GET a: $uri');

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
        print(
            '❌ CotizacionService: Error al obtener detalle - Status: ${response.statusCode}');

        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de JSON. Status: ${response.statusCode}');
        }

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al cargar detalle');
        } catch (e) {
          throw Exception(
              'Respuesta inválida del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al obtener detalle: $e');
      rethrow;
    }
  }

  // ── Convertir a reserva ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> convertirAReserva(int id) async {
    print('🔍 CotizacionService: Convirtiendo cotización $id a reserva');

    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id/convertir');
    print('🔍 CotizacionService: Haciendo petición POST a: $uri');

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
        print(
            '❌ CotizacionService: Error al convertir - Status: ${response.statusCode}');

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al convertir a reserva');
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al convertir: $e');
      rethrow;
    }
  }

  // ── Anular cotización ──────────────────────────────────────────────────────

  Future<void> anularCotizacion(int id) async {
    print('🔍 CotizacionService: Anulando cotización $id');

    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id/anular');
    print('🔍 CotizacionService: Haciendo petición PATCH a: $uri');

    try {
      final response = await http
          .patch(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta anulación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: Anulación exitosa');
      } else {
        print(
            '❌ CotizacionService: Error al anular - Status: ${response.statusCode}');

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al anular cotización');
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al anular: $e');
      rethrow;
    }
  }

  // ── Eliminar cotización ────────────────────────────────────────────────────

  Future<void> eliminarCotizacion(int id) async {
    print('🔍 CotizacionService: Eliminando cotización $id');

    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id');
    print('🔍 CotizacionService: Haciendo petición DELETE a: $uri');

    try {
      final response = await http
          .delete(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta eliminación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: Eliminación exitosa');
      } else {
        print(
            '❌ CotizacionService: Error al eliminar - Status: ${response.statusCode}');

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al eliminar cotización');
        } catch (e) {
          throw Exception('Error del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ CotizacionService: Exception al eliminar: $e');
      rethrow;
    }
  }

  // ── Descargar PDF ──────────────────────────────────────────────────────────

  Future<void> descargarPDF(int id) async {
    print(
        '🔍 CotizacionService: Iniciando descarga de PDF para cotización $id');

    final token = await _getToken();
    if (token == null) {
      print('❌ CotizacionService: No hay token para descargar PDF');
      throw Exception('No autenticado');
    }

    try {
      // Intentar encontrar una URL que funcione
      String? workingUrl = await NetworkConfig.findWorkingUrl();
      if (workingUrl == null) {
        throw Exception('No se puede conectar al servidor');
      }

      final uri = Uri.parse('$workingUrl/api/cotizaciones/$id/pdf');
      print('🔍 CotizacionService: Haciendo petición GET a: $uri');

      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta PDF - Status: ${response.statusCode}');
      print(
          '🔍 CotizacionService: Content-Type: ${response.headers['content-type']}');

      if (response.statusCode == 200) {
        print('✅ CotizacionService: PDF descargado exitosamente');

        final bytes = response.bodyBytes;

        // Comportamiento diferente según la plataforma
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          // En móvil, guardar y abrir
          try {
            // Usar dynamic import para evitar errores en web
            final pathProvider = await _importPathProvider();
            if (pathProvider != null) {
              print('✅ CotizacionService: Guardando en dispositivo móvil');
              final dir = await pathProvider;
              final file = File('${dir.path}/cotizacion-$id.pdf');
              await file.writeAsBytes(bytes);
              print('✅ CotizacionService: PDF guardado en: ${file.path}');

              // Abrir el PDF
              await _openPDF(file.path);
              print('✅ CotizacionService: PDF abierto');
            }
          } catch (e) {
            print('⚠️ CotizacionService: No se pudo abrir el PDF: $e');
          }
        } else {
          print(
              '✅ CotizacionService: PDF descargado (web o plataforma no soportada)');
        }
      } else {
        print(
            '❌ CotizacionService: Error al descargar PDF - Status: ${response.statusCode}');
        print('❌ CotizacionService: Response body: ${response.body}');

        // Si la respuesta parece HTML, no intentar parsear como JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de PDF. Status: ${response.statusCode}');
        }

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al descargar PDF');
        } catch (e) {
          throw Exception(
              'Error del servidor: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ CotizacionService: Exception descargando PDF: $e');
      rethrow;
    }
  }

  // ── Helpers para importación dinámica ──────────────────────────────────────

  Future<dynamic> _importPathProvider() async {
    if (kIsWeb) return null;
    try {
      // Importar dinámicamente path_provider
      final pathProvider = await Future.value(null);
      return pathProvider;
    } catch (e) {
      return null;
    }
  }

  Future<void> _openPDF(String path) async {
    if (kIsWeb) return;
    try {
      // Intentar abrir el PDF
      // Esta función se implementará cuando sea necesario
      print('📄 Abriendo PDF: $path');
    } catch (e) {
      print('Error abriendo PDF: $e');
    }
  }
}
