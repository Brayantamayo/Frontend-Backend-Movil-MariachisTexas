import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../core/config/network_config.dart';
import 'cotizacion.model.dart';

class CotizacionService {
  static const _storage = FlutterSecureStorage();

  Future<String?> _getToken() => _storage.read(key: 'token');

  Map<String, String> _headers(String token) =>
      NetworkConfig.authHeaders(token);

  String _msg(String body) {
    try {
      return (jsonDecode(body) as Map<String, dynamic>)['message'] 
             ?? 'Error desconocido';
    } catch (_) {
      return 'Error desconocido';
    }
  }

  // ── GET todas ─────────────────────────────────────────────────────────────
  Future<List<Cotizacion>> getCotizaciones() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Cotizacion.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception(_msg(res.body));
  }

  // ── GET por ID ────────────────────────────────────────────────────────────
  Future<Cotizacion> getCotizacionById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      return Cotizacion.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_msg(res.body));
  }

  // ── PATCH anular ──────────────────────────────────────────────────────────
  Future<void> anularCotizacion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .patch(Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones/$id/anular'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode != 200) throw Exception(_msg(res.body));
  }

  // ── PATCH convertir ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> convertirAReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .patch(                                          // 👈 era POST, es PATCH
            Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones/$id/convertir'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_msg(res.body));
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Future<void> eliminarCotizacion(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .delete(Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones/$id'),
            headers: _headers(token))
        .timeout(NetworkConfig.timeout);

    if (res.statusCode != 200) throw Exception(_msg(res.body));
  }

  // ── GET PDF ───────────────────────────────────────────────────────────────
  Future<void> descargarPDF(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final res = await http
        .get(Uri.parse('${NetworkConfig.baseUrl}/api/cotizaciones/$id/pdf'),
            headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw Exception(_msg(res.body));

    if (kIsWeb) {
      // En web no se puede guardar archivos directamente
      throw Exception('Descarga de PDF no disponible en web');
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cotizacion-$id.pdf');
      await file.writeAsBytes(res.bodyBytes);
      await OpenFile.open(file.path);
    }
  }
}