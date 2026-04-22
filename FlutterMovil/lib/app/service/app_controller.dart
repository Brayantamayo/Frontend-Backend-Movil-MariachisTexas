import 'package:flutter/material.dart';
import '/auth/auth_controller.dart';

class AppController extends ChangeNotifier {
  final AuthController authController;
  bool _booted = false;

  AppController(this.authController) {
    _boot();
  }

  bool _isSplash = true;
  bool get isSplash => _isSplash;

  Future<void> _boot() async {
    if (_booted) return;
    _booted = true;

    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      authController.cargarTokenGuardado(),
    ]);
    _isSplash = false;
    notifyListeners();
  }
}