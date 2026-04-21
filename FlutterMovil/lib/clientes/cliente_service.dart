import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mariachi_admin/clientes/cliente_model.dart';

class ClienteService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<List<Cliente>> obtenerClientes(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/clientes'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cliente.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar clientes: ${response.statusCode}');
    }
  }
}