library;

import 'package:flutter/foundation.dart';

class Environment {
  final String name;
  final String apiUrl;
  final String apiVersion;

  const Environment({
    required this.name,
    required this.apiUrl,
    required this.apiVersion,
  });

  // ⚠️ Cambia _localIP por tu IP si usas dispositivo físico
  static const String _localIP = 'http://192.168.18.158:3000';
  static const String _localhost = 'http://localhost:3000';

  /// Detecta automáticamente la URL según la plataforma
  static Environment get current => const Environment(
        name: 'development',
        apiUrl: kIsWeb
            ? _localhost // Chrome / web
            : _localIP, // Dispositivo físico (cambia a _emulator si usas emulador)
        apiVersion: 'api',
      );

  static const prod = Environment(
    name: 'production',
    apiUrl: 'https://api.tudominio.com',
    apiVersion: 'v1',
  );
}

// Alias para compatibilidad
class Env {
  static String get apiUrl => Environment.current.apiUrl;
  static String get apiVersion => Environment.current.apiVersion;
  static String endpoint(String path) => '$apiUrl/$apiVersion/$path';
}
