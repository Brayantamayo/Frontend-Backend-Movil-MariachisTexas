import 'package:flutter/foundation.dart';
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
        rolId: json['rolId'] != null ? json['rolId'] as int : 0,
      );

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

  Future<void> cargarTokenGuardado() async {
    final token = await _service.getToken();
    if (token != null && token.isNotEmpty) {
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

  /// Valida credenciales y guarda el estado internamente SIN notificar (sin navegar).
  /// Llama a [confirmarLogin] para completar la navegación.
  Future<bool> loginSinNavegar(
      {required String email, required String password}) async {
    _lastError = null;
    try {
      final result = await _service.login(email: email, password: password);
      _token = result['token'] as String;
      final userData =
          (result['usuario'] ?? result['user']) as Map<String, dynamic>;
      _user = AuthUser.fromJson(userData);
      // NO ponemos _isAuthenticated = true todavía, ni notificamos
      return true;
    } on Exception catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Completa el login notificando a la app para que navegue a ShellScreen.
  void confirmarLogin() {
    _isAuthenticated = true;
    notifyListeners();
  }

  /// Login con huella: usa las credenciales guardadas para hacer login real al backend
  Future<bool> loginConHuella() async {
    _lastError = null;
    try {
      final credenciales = await _service.getCredencialesBiometricas();
      if (credenciales == null) return false;
      return await login(
        email: credenciales['email']!,
        password: credenciales['password']!,
      );
    } on Exception catch (e) {
      _lastError = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Guarda las credenciales para uso futuro con biometría
  Future<void> guardarCredencialesBiometricas({
    required String email,
    required String password,
  }) =>
      _service.guardarCredencialesBiometricas(email: email, password: password);

  /// Verifica si hay credenciales biométricas configuradas
  Future<bool> tieneBiometricaConfigurada() =>
      _service.tieneBiometricaConfigurada();

  Future<void> logout() async {
    await _service.clearToken();
    _isAuthenticated = false;
    _user = null;
    _token = null;
    _lastError = null;
    notifyListeners();
  }

  /// Obtiene el token guardado
  Future<String?> getToken() => _service.getToken();

  /// Inicia sesión con un token específico (respaldo)
  Future<bool> loginConTokenDirecto(String token) async {
    if (token.isEmpty) return false;
    final userData = await _service.getUserData();
    _token = token;
    _user = userData != null ? AuthUser.fromJson(userData) : null;
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }

  /// Inicia sesión usando el token guardado (respaldo)
  Future<bool> loginConToken() async {
    final token = await _service.getToken();
    if (token == null || token.isEmpty) return false;
    final userData = await _service.getUserData();
    _token = token;
    _user = userData != null ? AuthUser.fromJson(userData) : null;
    _isAuthenticated = true;
    notifyListeners();
    return true;
  }
}
