import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

@immutable
class AuthUser {
  final int id;
  final String nombre;
  final String email;
  final int rolId;

  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rolId,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        nombre: json['nombre'] as String,
        email: json['email'] as String,
        rolId: json['rolId'] != null ? json['rolId'] as int : 0, // seguro
      );

  bool get isAdmin => rolId == 1;
}

class AuthController extends ChangeNotifier {
  final _service = AuthService();
  static const _storage = FlutterSecureStorage();

  bool _isAuthenticated = false;
  AuthUser? _user;
  String? _token;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get user => _user;
  String? get token => _token;
  String? get lastError => _lastError;

  // 👈 Llámalo en AppController._boot()
  Future<void> cargarTokenGuardado() async {
    final token = await _storage.read(key: 'token');
    if (token != null) {
      _token = token;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _lastError = null;
    try {
      final result = await _service.login(email: email, password: password);
      _token = result['token'] as String;
      // Soporta tanto 'usuario' como 'user' según el backend
      final userData =
          (result['usuario'] ?? result['user']) as Map<String, dynamic>;
      _user = AuthUser.fromJson(userData);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _service.clearToken();
    _isAuthenticated = false;
    _user = null;
    _token = null;
    _lastError = null;
    notifyListeners();
  }
}
