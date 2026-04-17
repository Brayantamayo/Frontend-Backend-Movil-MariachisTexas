import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app_controller.dart';
import 'auth/auth_controller.dart';
import 'cotizacion/cotizacion_controller.dart';
import 'repertorio/repertorio_controller.dart';
import 'reserva/reserva_controller.dart';
import 'ui/app_root.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => RepertorioController()),
        ChangeNotifierProvider(create: (_) => CotizacionController()),
        ChangeNotifierProvider(create: (_) => ReservaController()),
      ],
      child: const AppRoot(),
    ),
  );
}
