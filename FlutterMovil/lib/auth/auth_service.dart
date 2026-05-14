import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/env.dart';
import '../core/config/network_config.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';
  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';
  static const _biometricEnabledKey = 'biometric_enabled';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse(Env.endpoint('auth/login'));

    final response = await http
        .post(
          uri,
          headers: NetworkConfig.commonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(NetworkConfig.timeout);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      final token = body['token'] as String;
      // Guardar token en secure storage Y en SharedPreferences como respaldo
      await _storage.write(key: _tokenKey, value: token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      // Guardar datos del usuario para restaurarlos con huella
      final userData =
          (body['usuario'] ?? body['user']) as Map<String, dynamic>?;
      if (userData != null) {
        await prefs.setString('user_data', jsonEncode(userData));
      }
      return body;
    }

    throw Exception(body['message'] ?? 'Error al iniciar sesión');
  }

  /// Guarda las credenciales cifradas para uso con biometría
  Future<void> guardarCredencialesBiometricas({
    required String email,
    required String password,
  }) async {
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
  }

  /// Verifica si hay credenciales biométricas guardadas
  Future<bool> tieneBiometricaConfigurada() async {
    final prefs = await SharedPreferences.getInstance();
    final habilitado = prefs.getBool(_biometricEnabledKey) ?? false;
    if (!habilitado) return false;
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    return email != null &&
        email.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// Obtiene las credenciales guardadas para biometría
  Future<Map<String, String>?> getCredencialesBiometricas() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return {'email': email, 'password': password};
  }

  Future<String?> getToken() async {
    // Intentar secure storage primero, luego SharedPreferences como respaldo
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null) return token;
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Obtiene los datos del usuario guardados localmente
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove('user_data');
    // NO borrar credenciales biométricas al cerrar sesión normal
    // para que el usuario pueda volver a entrar con huella
  }

  /// Borra todo incluyendo credenciales biométricas (logout total)
  Future<void> clearAll() async {
    await _storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
