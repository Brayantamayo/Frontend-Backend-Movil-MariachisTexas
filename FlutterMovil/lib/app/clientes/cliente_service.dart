import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mariachi_admin/app/clientes/cliente_model.dart';

class ClienteService {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static Future<List<Cliente>> obtenerClientes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/clientes'),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Cliente.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar clientes');
    }
  }
}