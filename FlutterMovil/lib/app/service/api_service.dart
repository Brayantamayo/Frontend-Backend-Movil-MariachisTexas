import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // ── Cambia según entorno ──────────────────────────────────
    static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';   // Flutter Web
    }
    return 'http://10.0.2.2:3000/api';     // Android Emulator
  }

  static String? _token;

  static void setToken(String token) => _token = token;
  static void clearToken() => _token = null;

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── GET ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http
        .get(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── POST ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final res = await http
        .post(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── PUT ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── PATCH ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final res = await http
        .patch(Uri.parse('$baseUrl$path'), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http
        .delete(Uri.parse('$baseUrl$path'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    return _handle(res);
  }

  // ── Handler central ───────────────────────────────────────
  static Map<String, dynamic> _handle(http.Response res) {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    // Mapea los errores de tu backend al mensaje correcto
    final mensaje = body['message'] ?? body['error'] ?? 'Error desconocido';
    throw ApiException(mensaje, res.statusCode);
  }
}

// Excepción personalizada
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}