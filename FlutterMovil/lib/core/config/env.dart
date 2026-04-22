import 'environment.dart';

// Alias para compatibilidad
class Env {
  static String get apiUrl => Environment.current.apiUrl;
  static String get apiVersion => Environment.current.apiVersion;
  static String endpoint(String path) => '$apiUrl/$apiVersion/$path';
}
