import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_controller.dart';
import '../../core/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    final ok = await context.read<AuthController>().login(
          email: _email.text.trim(),
          password: _password.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      setState(() => _error = 'Credenciales incorrectas. Acceso denegado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        !_loading && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 28,
                      color: Color(0x14000000),
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        size: 48,
                        color: Color(AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mariachi Admin',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Color(AppColors.text),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Acceso exclusivo para administración',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(AppColors.textMuted),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 22),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Correo Electrónico',
                        prefixIcon: Icon(Icons.mail_outline),
                        hintText: 'admin@mariachi.com',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                        hintText: '••••••••',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => canSubmit ? _submit() : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                        ),
                        child: Text(_loading ? 'Verificando...' : 'Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Usa: admin@mariachi.com / 123456',
                      style: TextStyle(
                        color: Color(AppColors.textMuted),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

