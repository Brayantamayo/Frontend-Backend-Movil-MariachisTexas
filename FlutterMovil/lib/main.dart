import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mariachi_admin/app/app_controller.dart';
import 'package:mariachi_admin/app/clientes/clientes_controller.dart';
import 'package:mariachi_admin/auth/auth_controller.dart';
import 'package:mariachi_admin/cotizacion/cotizacion_controller.dart';
import 'package:mariachi_admin/repertorio/repertorio_controller.dart';
import 'package:mariachi_admin/reserva/reserva_controller.dart';
import 'package:mariachi_admin/ui/app_root.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppController()),
        ChangeNotifierProvider(create: (_) => ClientesController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => RepertorioController()),
        ChangeNotifierProvider(create: (_) => CotizacionController()),
        ChangeNotifierProvider(create: (_) => ReservaController()),
      ],
      child: const AppRoot(),
    ),
  );
}