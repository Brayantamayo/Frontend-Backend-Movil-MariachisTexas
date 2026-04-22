import 'package:http/http.dart' as http;

class NetworkConfig {
  // Configuración de red para diferentes entornos
  static const String _localhost = 'http://localhost:3000';
  static const String _localIP = 'http://192.168.18.158:3000';
  static const String _emulatorIP = 'http://10.0.2.2:3000';

  /// URLs alternativas para probar en caso de fallo
  static List<String> get fallbackUrls => [
        'http://localhost:3000', // Tu backend local
        'http://192.168.18.158:3000', // Tu IP con puerto 3000
        _emulatorIP, // Emulador Android
        _localhost, // Localhost
        _localIP, // Red local
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

  /// Método para probar conectividad con diferentes URLs
  static Future<String?> findWorkingUrl() async {
    for (String url in fallbackUrls) {
      try {
        print('🔍 NetworkConfig: Probando URL: $url');
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
    print('❌ NetworkConfig: Ninguna URL disponible');
    return null;
  }
}
