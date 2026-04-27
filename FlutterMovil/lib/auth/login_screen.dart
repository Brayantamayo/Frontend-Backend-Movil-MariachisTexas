import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _pwVisible = false;
  String? _error;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shake;

  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmer;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  static const _bg = Color.fromARGB(255, 109, 9, 9);
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _shake = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticOut),
    );

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmer = Tween(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _shakeCtrl.dispose();
    _shimmerCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final ok = await context.read<AuthController>().login(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (!mounted) return;
      if (!ok) {
        _shakeCtrl.forward(from: 0);
        setState(() => _error = 'Credenciales incorrectas. Acceso denegado.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión. Verifica tu red.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canSubmit =>
      !_loading && _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Fondo decorativo
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _BackgroundPainter(),
          ),
          // Contenido
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: _buildCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 31, 9, 9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color.fromARGB(255, 37, 7, 7),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 26, 4, 4),
        border: Border(
          bottom: BorderSide(color: Color(0xFF3A3A3A), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 26),
      child: Column(
        children: [
          // Logo con ring doble
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 34, 5, 5),
                    width: 1,
                  ),
                ),
              ),
              // Inner ring
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFF4A4A4A), width: 1.5),
                ),
              ),
              // Ícono
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 8, 1, 1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/Logo.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'BIENVENIDO',
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            'INGRESA TUS CREDENCIALES',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF888888),
              letterSpacing: 3.5,
            ),
          ),

          const SizedBox(height: 14),

          // Ornamento charro
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ornLine(),
              const SizedBox(width: 8),
              _ornDiamond(),
              const SizedBox(width: 8),
              _ornLine(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ornLine() => Container(
        width: 60,
        height: 1,
        color: const Color(0xFF3A3A3A),
      );

  Widget _ornDiamond() => Transform.rotate(
        angle: 0.785, // 45°
        child: Container(
          width: 7,
          height: 7,
          color: const Color(0xFF4A4A4A),
        ),
      );

  // ─── BODY ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    return Container(
      color: const Color.fromARGB(255, 29, 5, 5),
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Puntos decorativos estilo bordado charro
          _buildDots(),

          const SizedBox(height: 18),

          _buildField(
            label: 'Correo electrónico',
            controller: _email,
            hint: 'admin@mariachi.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            labelColor: _green,
          ),

          const SizedBox(height: 16),

          _buildField(
            label: 'Contraseña',
            controller: _password,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: !_pwVisible,
            textInputAction: TextInputAction.done,
            labelColor: _red,
            suffix: GestureDetector(
              onTap: () => setState(() => _pwVisible = !_pwVisible),
              child: Icon(
                _pwVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF666666),
              ),
            ),
            onSubmitted: (_) => _canSubmit ? _submit() : null,
          ),

          // Error animado
          if (_error != null) ...[
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _shake,
              builder: (context, child) {
                final dx = 6 * (0.5 - (_shake.value % 1.0)).abs() * 2;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5A2A2A)),
                ),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _red,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Botón con shimmer
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _canSubmit
                ? AnimatedBuilder(
                    animation: _shimmer,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [
                              (_shimmer.value - 0.3).clamp(0.0, 1.0),
                              _shimmer.value.clamp(0.0, 1.0),
                              (_shimmer.value + 0.3).clamp(0.0, 1.0),
                            ],
                            colors: const [
                              _red,
                              Color(0xFFD44637),
                              _red,
                            ],
                          ),
                        ),
                        child: child,
                      );
                    },
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _buttonContent(),
                    ),
                  )
                : FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF666666),
                      disabledBackgroundColor: const Color(0xFF666666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _buttonContent(),
                  ),
          ),

          const SizedBox(height: 20),

          // Divisor
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFF3A3A3A))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '..................',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: _green,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFF3A3A3A))),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined,
                  size: 12, color: Color(0xFF666666)),
              const SizedBox(width: 6),
              Text(
                'Conexión cifrada SSL · Solo administradores',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buttonContent() {
    if (_loading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          'Ingresar',
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final active = i % 2 == 0;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF4A4A4A) : const Color(0xFF3A3A3A),
          ),
        );
      }),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Widget? suffix,
    void Function(String)? onSubmitted,
    Color? labelColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: labelColor ?? const Color(0xFF888888),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.dmSans(fontSize: 14.5, color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                fontSize: 14, color: const Color(0xFF999999)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF666666)),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide:
                  const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide:
                  const BorderSide(color: Color(0xFFDDDDDD), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(
                  color: labelColor ?? const Color(0xFF888888), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── BACKGROUND PAINTER ────────────────────────────────────────────────────

class _BackgroundPainter extends CustomPainter {
  static const _accent = Color(0xFF3A3A3A);

  @override
  void paint(Canvas canvas, Size size) {
    final thinLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Líneas verticales laterales
    thinLine.color = _accent.withValues(alpha: 0.3);
    canvas.drawLine(const Offset(22, 0), Offset(22, size.height), thinLine);
    canvas.drawLine(Offset(size.width - 22, 0),
        Offset(size.width - 22, size.height), thinLine);

    // Líneas horizontales
    thinLine.color = _accent.withValues(alpha: 0.2);
    canvas.drawLine(const Offset(0, 100), Offset(size.width, 100), thinLine);
    canvas.drawLine(Offset(0, size.height - 100),
        Offset(size.width, size.height - 100), thinLine);

    // Glow sutil en la parte superior
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _accent.withValues(alpha: 0.15),
          _accent.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, 0),
        radius: size.width * 0.8,
      ));
    canvas.drawCircle(Offset(size.width / 2, 0), size.width * 0.8, glowPaint);

    // Ornamentos de esquinas
    final cornerPaint = Paint()
      ..color = _accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.square;

    _drawCorner(canvas, cornerPaint, 32, 32, false, false);
    _drawCorner(canvas, cornerPaint, size.width - 32, 32, true, false);
    _drawCorner(canvas, cornerPaint, 32, size.height - 32, false, true);
    _drawCorner(
        canvas, cornerPaint, size.width - 32, size.height - 32, true, true);

    // Notas musicales decorativas
    _drawMusicNote(canvas, size.width * 0.1, size.height * 0.32, 0.12);
    _drawMusicNote(canvas, size.width * 0.88, size.height * 0.6, 0.09);
    _drawMusicNote(canvas, size.width * 0.12, size.height * 0.72, 0.07);
    _drawMusicNote(canvas, size.width * 0.85, size.height * 0.22, 0.1);
  }

  void _drawCorner(
      Canvas canvas, Paint paint, double x, double y, bool flipX, bool flipY) {
    const arm = 22.0;
    final dx = flipX ? -1.0 : 1.0;
    final dy = flipY ? -1.0 : 1.0;
    canvas.drawLine(Offset(x, y), Offset(x + arm * dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + arm * dy), paint);
  }

  void _drawMusicNote(Canvas canvas, double x, double y, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '♪',
        style: TextStyle(
          fontSize: 28,
          color: const Color(0xFF3A3A3A).withValues(alpha: opacity),
          fontFamily: 'serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(_) => false;
}
