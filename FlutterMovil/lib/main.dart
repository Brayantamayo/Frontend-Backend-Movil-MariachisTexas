import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mariachi_admin/app/service/app_controller.dart';
import 'package:mariachi_admin/clientes/clientes_controller.dart';
import 'package:mariachi_admin/auth/auth_controller.dart';
import 'package:mariachi_admin/cotizacion/cotizacion_controller.dart';
import 'package:mariachi_admin/repertorio/repertorio_controller.dart';
import 'package:mariachi_admin/reserva/reserva_controller.dart';
import 'package:mariachi_admin/ui/app_root.dart';

void main() {
  final authController = AuthController();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authController),
        ChangeNotifierProvider(create: (_) => AppController(authController)), // 👈 recibe authController
        ChangeNotifierProvider(create: (_) => ClientesController()),
        ChangeNotifierProvider(create: (_) => RepertorioController()),
        ChangeNotifierProvider(create: (_) => CotizacionController()),
        ChangeNotifierProvider(create: (_) => ReservaController()),
      ],
      child: const AppRoot(),
    ),
  );
}