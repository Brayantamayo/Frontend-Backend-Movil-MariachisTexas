import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../core/config/network_config.dart';

class ReservaService {
// ── Token ─────────────────────────────────────────────────────────────────

  static const _storage = FlutterSecureStorage();
  Future<String?> _getToken() => _storage.read(key: 'token');


// ── Utilidades privadas ────────────────────────────────────────────────────

  String _resolveBaseUrl() => NetworkConfig.baseUrl;

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


// ── Listar reservas ────────────────────────────────────────────────────────

  Future<List<Reserva>> getReservas() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse('${_resolveBaseUrl()}/api/reservas');

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Reserva.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }

// ── Buscar reservas (filtro en cliente) ────────────────────────────────────

  Future<List<Reserva>> buscarReservas(String query) async {
  final reservas = await getReservas();
  final q = query.toLowerCase().trim();
  return reservas
      .where((r) =>
          r.homenajeado.toLowerCase().contains(q) ||
          r.clienteNombre.toLowerCase().contains(q))
      .toList();
}

// ── Detalle de reserva ─────────────────────────────────────────────────────

  Future<Reserva> getReservaById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

  final uri = Uri.parse('${_resolveBaseUrl()}/api/reservas/$id');

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Reserva.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Registrar abono ────────────────────────────────────────────────────────

  Future<Abono> registrarAbono(
    int reservaId, {
    required double monto,
    required String metodoPago,
    String? notas,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

  final uri = Uri.parse('${_resolveBaseUrl()}/api/reservas/$reservaId/abonos');

    final body = jsonEncode({
      'monto': monto,
      'metodoPago': metodoPago,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });

    final response = await http
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Abono.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Anular reserva ─────────────────────────────────────────────────────────

  Future<void> anularReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

  final uri = Uri.parse('${_resolveBaseUrl()}/api/reservas/$id/anular');

    final response = await http
        .patch(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractErrorMessage(response));
    }
  }
}