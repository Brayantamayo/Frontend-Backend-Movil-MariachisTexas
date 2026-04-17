import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_controller.dart';
import 'auth/auth_controller.dart';
import 'repertorio/repertorio_controller.dart';
import 'ui/app_root.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => RepertorioController()),
      ],
      child: const AppRoot(),
    ),
  );
}

