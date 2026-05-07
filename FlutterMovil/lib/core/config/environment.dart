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


  static const prod = Environment(
    name: 'production',
    apiUrl: 'https://mariachistexas-production.up.railway.app',
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
