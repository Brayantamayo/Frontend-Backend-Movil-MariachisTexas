import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NetworkConfig {
  static const String _localhost  = 'http://localhost:3000';
  static const String _localIP    = 'http://192.168.18.158:3000';
  static const String _emulatorIP = 'http://10.0.2.2:3000';

  /// URL base según plataforma
  static String get baseUrl {
    if (kIsWeb) return _localhost;       // Flutter Web
    return _emulatorIP;                  // Android Emulator
    // return _localIP;                  // Dispositivo físico
  }

  static const Duration timeout = Duration(seconds: 10);

  static Map<String, String> get commonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...commonHeaders,
    'Authorization': 'Bearer $token',
  };

  // Útil para debug, puedes quitarlo en producción
  static Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: commonHeaders)
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}