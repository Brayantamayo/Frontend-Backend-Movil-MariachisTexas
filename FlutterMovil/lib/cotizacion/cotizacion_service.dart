import 'dart:convert';
import 'dart:html' as html;
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

    final uri = Uri.parse(
        '${NetworkConfig.baseUrl}/api/cotizaciones/search?q=${Uri.encodeComponent(query)}');
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

    // Intentar encontrar una URL que funcione
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

        // Si la respuesta parece HTML, no intentar parsear como JSON
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
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    // Intentar encontrar una URL que funcione
    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id/convertir');
    final response = await http
        .post(uri, headers: NetworkConfig.authHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al convertir a reserva');
    }
  }

  // ── Anular cotización ──────────────────────────────────────────────────────

  Future<Cotizacion> anularCotizacion(int id) async {
    print('🔍 CotizacionService: Iniciando anulación de cotización $id');

    final token = await _getToken();
    if (token == null) {
      print('❌ CotizacionService: No hay token para anular');
      throw Exception('No autenticado');
    }

    // Intentar encontrar una URL que funcione
    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception(
          'No se puede conectar al servidor. Verifica que esté corriendo en localhost:3000');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id/anular');
    print('🔍 CotizacionService: Haciendo petición PATCH a: $uri');

    try {
      final response = await http
          .patch(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 CotizacionService: Respuesta anular - Status: ${response.statusCode}');
      print('🔍 CotizacionService: Body: ${response.body}');

      if (response.statusCode == 200) {
        final cotizacionActualizada = Cotizacion.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
        print(
            '✅ CotizacionService: Cotización anulada exitosamente - Estado: ${cotizacionActualizada.estado}');
        return cotizacionActualizada;
      } else {
        print(
            '❌ CotizacionService: Error al anular - Status: ${response.statusCode}');

        // Si la respuesta parece HTML, no intentar parsear como JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de JSON. Status: ${response.statusCode}');
        }

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al anular cotización');
        } catch (e) {
          throw Exception(
              'Respuesta inválida del servidor: ${response.statusCode}');
        }
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

    // Intentar encontrar una URL que funcione
    String? workingUrl = await NetworkConfig.findWorkingUrl();
    if (workingUrl == null) {
      throw Exception('No se puede conectar al servidor');
    }

    final uri = Uri.parse('$workingUrl/api/cotizaciones/$id');
    final response = await http
        .delete(uri, headers: NetworkConfig.authHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? 'Error al eliminar cotización');
    }
  }

  // ── Generar PDF ────────────────────────────────────────────────────────────

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

        // Crear un blob con los bytes del PDF
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Crear un enlace temporal para descargar
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'cotizacion-$id.pdf')
          ..style.display = 'none';

        // Agregar al documento, hacer clic y remover
        html.document.body!.append(anchor);
        anchor.click();
        anchor.remove();

        // Limpiar la URL del blob después de un pequeño delay
        await Future.delayed(const Duration(milliseconds: 100));
        html.Url.revokeObjectUrl(url);

        print('✅ CotizacionService: Descarga iniciada');
      } else {
        print(
            '❌ CotizacionService: Error al descargar PDF - Status: ${response.statusCode}');
        print('❌ CotizacionService: Response body: ${response.body}');

        // Si la respuesta parece HTML, no intentar parsear como JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de JSON. Status: ${response.statusCode}');
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
}
