import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'reserva.model.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class ReservaService {
  // ── Token ────────────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token;
  }

  // ── Obtener todas las reservas ─────────────────────────────────────────────

  Future<List<Reserva>> getReservas() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No autenticado');
    }

    final uri = Uri.parse(Env.endpoint('reservas'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 ReservaService: Respuesta recibida - Status: ${response.statusCode}');
      print(
          '🔍 ReservaService: Content-Type: ${response.headers['content-type']}');
      print('🔍 ReservaService: Body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            '✅ ReservaService: JSON parseado exitosamente - ${data.length} reservas');

        final reservas = data
            .map((e) => Reserva.fromJson(e as Map<String, dynamic>))
            .toList();

        print(
            '✅ ReservaService: Modelos creados exitosamente - ${reservas.length} reservas');
        return reservas;
      } else {
        print('❌ ReservaService: Error HTTP ${response.statusCode}');
        print(
            '❌ ReservaService: Response body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');

        // Si la respuesta parece HTML, no intentar parsear como JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          throw Exception(
              'El servidor devolvió HTML en lugar de JSON. Verifica que el backend esté corriendo correctamente en localhost:3000');
        }

        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          throw Exception(body['message'] ?? 'Error al cargar reservas');
        } catch (e) {
          throw Exception(
              'Respuesta inválida del servidor: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ ReservaService: Exception caught: $e');
      rethrow;
    }
  }

  // ── Buscar reservas ────────────────────────────────────────────────────────

  Future<List<Reserva>> buscarReservas(String query) async {
    // Por ahora, obtener todas y filtrar en el cliente
    final reservas = await getReservas();
    return reservas
        .where((r) =>
            r.cotizacion?.nombreHomenajeado
                .toLowerCase()
                .contains(query.toLowerCase()) ??
            false)
        .toList();
  }

  // ── Obtener detalle de reserva ─────────────────────────────────────────────

  Future<Reserva> getReservaById(int id) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$id'));

    try {
      final response = await http
          .get(uri, headers: NetworkConfig.authHeaders(token))
          .timeout(NetworkConfig.timeout);

      print(
          '🔍 ReservaService: Respuesta detalle - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final reserva =
            Reserva.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        print('✅ ReservaService: Detalle obtenido exitosamente');
        return reserva;
      } else {
        print(
            '❌ ReservaService: Error al obtener detalle - Status: ${response.statusCode}');

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
      print('❌ ReservaService: Exception al obtener detalle: $e');
      rethrow;
    }
  }
}
