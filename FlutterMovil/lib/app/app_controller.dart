import 'dart:async';
import 'package:flutter/foundation.dart';

class AppController extends ChangeNotifier {
  bool _isSplash = true;
  bool get isSplash => _isSplash;

  AppController() {
    _boot();
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    _isSplash = false;
    notifyListeners();
  }
}