import 'package:flutter/material.dart';
import '/auth/auth_controller.dart';

class AppController extends ChangeNotifier {
  final AuthController authController;

  // 👆 Recibe el AuthController como dependencia
  AppController(this.authController);

  bool _isSplash = true;
  bool get isSplash => _isSplash;

  Future<void> _boot() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      authController.cargarTokenGuardado(), // restaura sesión en paralelo
    ]);
    _isSplash = false;
    notifyListeners();
  }
}