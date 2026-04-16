import 'package:flutter/foundation.dart';
import 'auth.service.dart';

@immutable
class AuthUser {
  final int id;
  final String nombre;
  final String email;
  final int rolId; // el backend devuelve rolId como número

  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rolId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      rolId: json['rolId'] as int,
    );
  }

  /// Comodidad: saber si es administrador (rolId == 1 por convención)
  bool get isAdmin => rolId == 1;
}

class AuthController extends ChangeNotifier {
  final _service = AuthService();

  bool _isAuthenticated = false;
  AuthUser? _user;
  String? _token;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get lastError => _lastError;

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _lastError = null;
    try {
      final result = await _service.login(email: email, password: password);

      _token = result['token'] as String;
      _user = AuthUser.fromJson(result['user'] as Map<String, dynamic>);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('Login error: $_lastError');
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isAuthenticated = false;
    _user = null;
    _token = null;
    _lastError = null;
    notifyListeners();
  }
}