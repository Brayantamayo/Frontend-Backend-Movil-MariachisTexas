library;

class Environment {
  final String name;
  final String apiUrl;
  final String apiVersion;

  const Environment({
    required this.name,
    required this.apiUrl,
    required this.apiVersion,
  });

  static const prod = Environment(
    name: 'mariachistexasmedellin-fron-back',
    apiUrl: 'https://mariachistexasmedellin-fron-back-ifoi.onrender.com',
    apiVersion: 'api',
  );
  static Environment get current => prod;
}

// Alias para compatibilidad
class Env {
  static String get apiUrl => Environment.current.apiUrl;
  static String get apiVersion => Environment.current.apiVersion;
  static String endpoint(String path) => '$apiUrl/$apiVersion/$path';
}
