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
      final msg = body['message']?.toString() ?? 'Error ${response.statusCode}';
      // Traducir errores comunes del backend
      if (msg.toLowerCase().contains('cliente') ||
          msg.toLowerCase().contains('client')) {
        return 'Esta reserva no tiene cliente asociado. No se puede registrar el abono.';
      }
      return msg;
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

  Future<void> registrarAbono(
    int reservaId, {
    required double monto,
    required String metodoPago,
    String? notas,
    int? clientId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas/$reservaId/abonos'));
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final bodyMap = <String, dynamic>{
      'amount': monto,
      'date': date,
      'method': metodoPago,
      if (notas != null && notas.isNotEmpty) 'notes': notas,
      if (clientId != null && clientId > 0) 'clientId': clientId,
    };

    final response = await http
        .post(uri, headers: _buildHeaders(token), body: jsonEncode(bodyMap))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      print('=== ABONO ERROR body: ${response.body}');
      throw Exception(_extractErrorMessage(response));
    }
  }

  /// Obtiene reservas ANULADAS que tienen abonos y las convierte a Venta
  Future<List<Venta>> obtenerReservasAnuladasConAbonos() async {
    final token = await _getToken();
    if (token == null) throw Exception('No autenticado');

    final uri = Uri.parse(Env.endpoint('reservas?incluirFinalizadas=true'));
    final response = await http
        .get(uri, headers: _buildHeaders(token))
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      List items;
      try {
        items = decoded as List;
      } catch (_) {
        return [];
      }

      return items
          .map((e) {
            try {
              final m = <String, dynamic>{};
              (e as Map).forEach((k, v) => m[k.toString()] = v);
              final estado = (m['status'] ?? '').toString().toUpperCase();
              if (estado != 'ANULADA') return null;
              final pagos = m['payments'] as List? ?? [];
              if (pagos.isEmpty) return null;
              // Convertir reserva anulada con abonos a Venta
              return Venta.fromJson({
                'id': m['id'],
                'clientName': m['clientName'],
                'clientEmail': m['clientEmail'] ?? '',
                'clientPhone': m['clientPhone'] ?? '',
                'homenajeado': m['homenajeado'] ?? '',
                'eventType': m['eventType'] ?? '',
                'eventDate': m['eventDate'],
                'eventTime': m['startTime'],
                'eventEndTime': m['endTime'],
                'eventLocation': m['location'] ?? '',
                'totalAmount': m['totalAmount'] ?? 0,
                'pendingAmount': m['pendingBalance'] ?? 0,
                'paidAmount': m['paidAmount'] ?? 0,
                'status': 'ANULADA',
                'date': m['createdAt'] ?? m['eventDate'],
                'services': m['selectedServices'] ?? [],
                'abonos': pagos,
              });
            } catch (_) {
              return null;
            }
          })
          .whereType<Venta>()
          .toList();
    }
    return [];
  }

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
