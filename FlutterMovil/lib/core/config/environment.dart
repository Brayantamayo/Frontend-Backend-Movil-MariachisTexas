library;

/// Configuración de entorno para la API
///
/// Usa este archivo para cambiar entre:
/// - desarrollo (localhost)
/// - staging
/// - producción
///
/// CAMBIA LA VARIABLE "current" PARA PROBAR DIFERENTES ENTORNOS

class Environment {
  final String name;
  final String apiUrl;
  final String apiVersion;

  const Environment({
    required this.name,
    required this.apiUrl,
    required this.apiVersion,
  });

  // Entornos disponibles
  static const dev = Environment(
    name: 'development',
    apiUrl: 'http://localhost:3000',
    apiVersion: 'api',
  );

  static const staging = Environment(
    name: 'staging',
    apiUrl: 'http://tu-servidor-staging:puerto',
    apiVersion: 'api',
  );

  static const prod = Environment(
    name: 'production',
    apiUrl: 'https://api.tudominio.com',
    apiVersion: 'v1',
  );

  // ⚠️ CAMBIA AQUÍ EL ENTORNO ACTUAL
  static Environment get current => dev;
}

// Alias para compatibilidad
class Env {
  static String get apiUrl => Environment.current.apiUrl;
  static String get apiVersion => Environment.current.apiVersion;
  static String endpoint(String path) => '$apiUrl/$apiVersion/$path';
}
