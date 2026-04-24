import 'package:http/http.dart' as http;
import 'environment.dart';

class NetworkConfig {
  /// URL base — siempre viene de Environment
  static String get baseUrl => Environment.current.apiUrl;

  static const Duration timeout = Duration(seconds: 10);

  static Map<String, String> get commonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static Map<String, String> authHeaders(String token) => {
        ...commonHeaders,
        'Authorization': 'Bearer $token',
      };

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
