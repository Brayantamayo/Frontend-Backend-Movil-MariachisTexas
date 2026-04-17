import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/app_controller.dart';
import '../auth/auth_controller.dart';
import '../core/theme/app_colors.dart';
import '../auth/login_screen.dart';
import 'screens/shell_screen.dart';
import 'widgets/splash_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(AppColors.primary),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mariachi Admin',
      theme: ThemeData(
        colorScheme: scheme.copyWith(
          primary: const Color(AppColors.primary),
          surface: const Color(AppColors.surface),
        ),
        scaffoldBackgroundColor: const Color(AppColors.background),
        useMaterial3: true,
      ),
      home: Consumer2<AppController, AuthController>(
        builder: (context, app, auth, _) {
          if (app.isSplash) return const SplashScreen();
          if (!auth.isAuthenticated) return const LoginScreen();
          return const ShellScreen();
        },
      ),
    );
  }
}

