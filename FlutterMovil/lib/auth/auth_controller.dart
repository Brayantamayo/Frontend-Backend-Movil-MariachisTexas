import 'dart:async';

import 'package:flutter/foundation.dart';

@immutable
class AuthUser {
  final String name;
  final String role;

  const AuthUser({required this.name, required this.role});
}

class AuthController extends ChangeNotifier {
  bool _isAuthenticated = false;
  AuthUser? _user;

  bool get isAuthenticated => _isAuthenticated;
  AuthUser? get user => _user;

  Future<bool> login({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (email == 'admin@mariachi.com' && password == '123456') {
      _isAuthenticated = true;
      _user = const AuthUser(name: 'Admin Mariachi', role: 'admin');
      notifyListeners();
      return true;
    }

    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}

