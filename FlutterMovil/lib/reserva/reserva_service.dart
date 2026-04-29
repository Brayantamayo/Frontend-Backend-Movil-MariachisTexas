import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mariachi_admin/core/models/app_models.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class ReservaService {
// ── Token ─────────────────────────────────────────────────────────────────

  static const _storage = FlutterSecureStorage();
  Future<String?> _getToken() => _storage.read(key: 'token');

// ── Utilidades privadas ────────────────────────────────────────────────────

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

    // Agregar parámetro para obtener todas las reservas incluyendo finalizadas
    final uri = Uri.parse(Env.endpoint('reservas?incluirFinalizadas=true'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      if (data.isNotEmpty) {
        final primera = data.first as Map<String, dynamic>;
        print('=== DEBUG RESERVA KEYS: ${primera.keys.toList()}');
        // Imprimir todas las claves que puedan contener servicios
        for (final key in primera.keys) {
          final val = primera[key];
          if (val is List && val.isNotEmpty) {
            print('=== LISTA "$key" (${val.length} items): ${val.first}');
          }
        }
      }
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

    final uri = Uri.parse(Env.endpoint('reservas/$id'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Reserva.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Registrar abono ────────────────────────────────────────────────────────

  Future<void> registrarAbono(
    int reservaId, {
    required double monto,
    required String metodoPago,
    String? notas,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$reservaId/abonos'));

    // El backend espera: { amount, date, method, notes }
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'amount': monto,
      'date': date,
      'method': metodoPago,
      if (notas != null && notas.isNotEmpty) 'notes': notas,
    });

    final response = await http
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200 || response.statusCode == 201) return;

    throw Exception(_extractErrorMessage(response));
  }

  // ── Anular reserva ─────────────────────────────────────────────────────────

  Future<void> anularReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id/anular'));

    final response = await http
        .patch(uri, headers: _buildHeaders(token), body: jsonEncode({}))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // ── Crear reserva directa ──────────────────────────────────────────────────

  Future<Reserva> crearReserva({
    required int clienteId,
    required String clienteNombre,
    required String clienteEmail,
    required String clienteTelefono,
    required String homenajeado,
    required String tipoEvento,
    required DateTime fechaEvento,
    required String horaInicio,
    required String horaFin,
    required String ubicacion,
    required double totalValor,
    List<Map<String, dynamic>>? servicios,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas'));

    final fechaStr =
        '${fechaEvento.year}-${fechaEvento.month.toString().padLeft(2, '0')}-${fechaEvento.day.toString().padLeft(2, '0')}';

    final bodyData = {
      'clienteId': clienteId,
      'clientName': clienteNombre,
      'clientEmail': clienteEmail,
      'clientPhone': clienteTelefono,
      'homenajeado': homenajeado,
      'eventType': tipoEvento,
      'eventDate': fechaStr,
      'startTime': horaInicio,
      'endTime': horaFin,
      'location': ubicacion,
      'totalAmount': totalValor,
    };

    // El backend usa "selectedServices" como campo para los servicios
    if (servicios != null && servicios.isNotEmpty) {
      bodyData['selectedServices'] = servicios;
      bodyData['tiposSerenata'] = servicios;
    }

    final body = jsonEncode(bodyData);

    print('=== DEBUG: Enviando datos al backend ===');
    print('URL: $uri');
    print('Body: $body');

    final response = await http
        .post(uri, headers: _buildHeaders(token), body: body)
        .timeout(NetworkConfig.timeout);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Reserva.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Obtener horas disponibles ──────────────────────────────────────────────

  Future<List<String>> obtenerHorasDisponibles(DateTime fecha) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final fechaStr =
        '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

    final uri =
        Uri.parse(Env.endpoint('reservas/disponibilidad?fecha=$fechaStr'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // El backend puede devolver las horas de diferentes formas
      if (data is List) {
        return data.map((e) => e.toString()).toList();
      } else if (data is Map) {
        final horas = data['horas'] ??
            data['horasDisponibles'] ??
            data['available'] ??
            [];
        return (horas as List).map((e) => e.toString()).toList();
      }

      return [];
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Actualizar reserva ────────────────────────────────────────────────────

  Future<Reserva> actualizarReserva(int id, Map<String, dynamic> datos) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id'));

    final response = await http
        .put(uri, headers: _buildHeaders(token), body: jsonEncode(datos))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Reserva.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Eliminar reserva ───────────────────────────────────────────────────────

  Future<void> eliminarReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id'));

    final response = await http
        .delete(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // ── Reprogramar reserva ──────────────────────────────────────────────────

  Future<Reserva> reprogramarReserva(int id, DateTime nuevaFecha,
      String nuevaHoraInicio, String nuevaHoraFin) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id/reprogramar'));
    final fechaStr =
        '${nuevaFecha.year}-${nuevaFecha.month.toString().padLeft(2, '0')}-${nuevaFecha.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'eventDate': fechaStr,
      'startTime': nuevaHoraInicio,
      'endTime': nuevaHoraFin,
    });

    final response = await http
        .patch(uri, headers: _buildHeaders(token), body: body)
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Reserva.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Finalizar reserva ────────────────────────────────────────────────────

  Future<Reserva> finalizarReserva(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id/finalizar'));

    final response = await http
        .patch(uri, headers: _buildHeaders(token), body: jsonEncode({}))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      return Reserva.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Obtener abonos de una reserva ────────────────────────────────────────

  Future<List<Abono>> obtenerAbonosReserva(int reservaId) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$reservaId/abonos'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Abono.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }

  // ── Obtener todos los abonos ────────────────────────────────────────────

  Future<List<Abono>> obtenerTodosAbonos() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('abonos'));

    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Abono.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw Exception(_extractErrorMessage(response));
  }
}
