import 'package:http/http.dart' as http;

class NetworkConfig {
  // Configuración de red para diferentes entornos
  static const String _localhost = 'http://localhost:3000';
  static const String _localIP = 'http://192.168.18.158:3000';
  static const String _emulatorIP = 'http://10.0.2.2:3000';

  /// Obtiene la URL base según el entorno
  static String get baseUrl {
    // Para desarrollo local, usar localhost
    // Para emulador Android, usar 10.0.2.2
    // Para dispositivo físico, usar la IP local

    // Usar localhost que es donde está corriendo el servidor
    return _localhost;
  }

  /// Método para probar conectividad con diferentes URLs
  static Future<String?> findWorkingUrl() async {
    for (String url in fallbackUrls) {
      try {
        final response = await http
            .get(
              Uri.parse('$url/health'),
              headers: commonHeaders,
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          print('✅ NetworkConfig: URL funcionando: $url');
          return url;
        }
      } catch (e) {
        print('❌ NetworkConfig: URL no disponible: $url - $e');
        continue;
      }
    }
    return null;
  }

  /// URLs alternativas para probar en caso de fallo
  static List<String> get fallbackUrls => [
        _localhost, // Localhost (prioritario)
        _localIP, // Red local
        _emulatorIP, // Emulador Android
      ];

  /// Timeout para las peticiones HTTP
  static const Duration timeout = Duration(seconds: 10);

  /// Headers comunes para todas las peticiones
  static Map<String, String> get commonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers con autenticación
  static Map<String, String> authHeaders(String token) => {
        ...commonHeaders,
        'Authorization': 'Bearer $token',
      };
}
