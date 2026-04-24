import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mariachi_admin/core/config/env.dart';
import 'package:mariachi_admin/core/config/network_config.dart';
import 'package:mariachi_admin/core/models/app_models.dart';

class ClienteService {
  static const _storage = FlutterSecureStorage();

  static Future<List<Cliente>> obtenerClientes() async {
    final token = await _storage.read(key: 'token');
    if (token == null) throw Exception('No autenticado');

    final response = await http
        .get(
          Uri.parse(Env.endpoint('clientes')),
          headers: NetworkConfig.authHeaders(token),
        )
        .timeout(NetworkConfig.timeout);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // El backend puede devolver lista directamente o dentro de una propiedad
      final List data = decoded is List
          ? decoded
          : (decoded['data'] ?? decoded['clientes'] ?? decoded['items'] ?? [])
              as List;
      return data
          .map((e) => Cliente.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Error al cargar clientes: ${response.statusCode}');
  }
}
