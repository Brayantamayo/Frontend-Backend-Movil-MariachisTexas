import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/bottom_nav.dart';
import 'clientes_screen.dart';
import 'cotizaciones_screen.dart';
import 'ensayos_screen.dart';
import 'menu_screen.dart';
import 'repertorio_screen.dart';
import 'reservas_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    ReservasScreen(),
    CotizacionesScreen(),
    ClientesScreen(),
    MenuScreen(),
    RepertorioScreen(),
    EnsayosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: const Color(AppColors.primary),
              padding: const EdgeInsets.only(top: 0),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'M',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: auth.logout,
                        icon: const Icon(Icons.logout),
                        color: const Color(0xFFFEE2E2),
                        tooltip: 'Cerrar sesión',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: IndexedStack(index: _index, children: _tabs),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

