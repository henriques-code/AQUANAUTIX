import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '_shared.dart';
import '../core/supabase_bootstrap.dart';
import 'home.dart';

/// Módulo de Login — UI redesenhada; lógica Supabase inalterada.
class LoginModuleScreen extends StatefulWidget {
  const LoginModuleScreen({super.key});

  @override
  State<LoginModuleScreen> createState() => _LoginModuleScreenState();
}

class _LoginModuleScreenState extends State<LoginModuleScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = true;
  bool _loading = false;
  bool _sessionActive = false;

  VideoPlayerController? _video;

  static const _white06 = Color.fromRGBO(255, 255, 255, 0.06);
  static const _white12 = Color.fromRGBO(255, 255, 255, 0.12);
  static const _white15 = Color.fromRGBO(255, 255, 255, 0.15);
  static const _white10 = Color.fromRGBO(255, 255, 255, 0.10);
  static const _cyan = Color(0xFF00F5FF);
  static const _hint = Color(0xFF8AADBE);
  static const _bgText = Color(0xFF000814);

  @override
  void initState() {
    super.initState();
    _refreshSessionState();
    unawaited(_initVideo());
  }

  Future<void> _initVideo() async {
    final c = VideoPlayerController.asset('assets/video_bg.mp4');
    _video = c;
    try {
      await c.initialize();
      await c.setLooping(true);
      await c.setVolume(0);
      await c.play();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _video?.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    final videoReady = v != null && v.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (videoReady)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: v.value.size.width,
                  height: v.value.size.height,
                  child: VideoPlayer(v),
                ),
              ),
            ),
          if (videoReady)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withValues(alpha: 0.55)),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_sessionActive) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kGreen.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        'SESSÃO ATIVA · ${supabaseCurrentUserEmail ?? 'UTILIZADOR'}',
                        style: mono(9, c: kGreen, ls: 0.8),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  Text(
                    'AQUANAUTIX',
                    style: GoogleFonts.orbitron(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _cyan,
                      letterSpacing: 3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'INSTRUMENTO DE PESCA DE ELITE',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 13,
                      color: _hint,
                      letterSpacing: 2.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'BEM-VINDO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra para aceder aos melhores spots de pesca da Ibéria',
                    style: ibm(13, c: Colors.white.withValues(alpha: 0.82)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _socialButton(
                    label: 'CONTINUAR COM GOOGLE',
                    icon: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleMarkPainter()),
                    ),
                    onTap: _signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _socialButton(
                    label: 'CONTINUAR COM APPLE',
                    icon: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _AppleMarkPainter()),
                    ),
                    onTap: () => _showSnack('Em breve'),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text('OU', style: ibm(11, c: _hint, ls: 1.2)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EMAIL',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _inputField(
                    hint: 'teu.email@aquanautix.com',
                    icon: Icons.mail_outline_rounded,
                    controller: _emailCtrl,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PASSWORD',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _inputField(
                    hint: '********',
                    icon: Icons.lock_outline_rounded,
                    obscure: !_showPassword,
                    controller: _passwordCtrl,
                    trailing: IconButton(
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                      icon: Icon(
                        _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: _hint,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: _rememberMe ? _cyan : _hint,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text('Lembrar sessão', style: ibm(12, c: Colors.white.withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loading ? null : _signIn,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _cyan,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: _cyan.withValues(alpha: 0.22), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_bgText),
                                  ),
                                )
                              : Text(
                                  'INICIAR SESSÃO',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _bgText,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _loading ? null : _signUp,
                          child: Text.rich(
                            TextSpan(
                              style: ibm(12, c: Colors.white54),
                              children: [
                                const TextSpan(text: 'Sem conta? '),
                                TextSpan(
                                  text: 'Registar',
                                  style: ibm(12, c: _cyan, fw: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : _recoverPassword,
                        child: Text('Recuperar password', style: ibm(12, c: _cyan, fw: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _loading ? null : _enterAsGuest,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _white10),
                        ),
                        child: Center(
                          child: Text(
                            'ENTRAR COMO CONVIDADO',
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: _white06,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _white15),
          ),
          child: Row(
            children: [
              icon,
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.shareTechMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _white06,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _white12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 20, color: _hint),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: ibm(13, c: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: ibm(13, c: _hint.withValues(alpha: 0.55)),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  SupabaseClient? _ensureClient() {
    if (!isSupabaseConfigured) {
      _showSnack('Supabase não configurado. A entrar em modo convidado.');
      return null;
    }
    return supabaseClientOrNull;
  }

  String? _validateInputs({required bool requirePassword}) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || !email.contains('@')) {
      return 'Insere um email válido.';
    }
    if (requirePassword && password.length < 6) {
      return 'A password deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  Future<void> _signIn() async {
    // DEBUG — remover antes de produção
    debugPrint('[AUTH] _signIn called — email: ${_emailCtrl.text.trim()}');

    final validationError = _validateInputs(requirePassword: true);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    final client = _ensureClient();
    if (client == null) {
      _enterAsGuest();
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      debugPrint('[AUTH] signInWithPassword result — user: ${response.user?.email}');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AquanautixHome()),
        );
      }
    } on AuthException catch (e) {
      debugPrint('[AUTH] AuthException: ${e.message} | statusCode: ${e.statusCode}');
      if (mounted) setState(() => _loading = false);
      await _showAuthError(_translateAuthError(e.message));
      return;
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      if (mounted) setState(() => _loading = false);
      await _showAuthError('Erro inesperado: $e');
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final validationError = _validateInputs(requirePassword: true);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    final client = _ensureClient();
    if (client == null) {
      _enterAsGuest();
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        emailRedirectTo: null,
      );
      if (response.user == null) throw Exception('Registo falhou');
      _showSnack('Conta criada. Confirma o teu email para continuar.');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Falha ao criar conta.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _recoverPassword() async {
    final validationError = _validateInputs(requirePassword: false);
    if (validationError != null) {
      _showSnack(validationError);
      return;
    }

    final client = _ensureClient();
    if (client == null) return;

    setState(() => _loading = true);
    try {
      await client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
        redirectTo: resetRedirectUrl,
      );
      _showSnack('Email de recuperação enviado.');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Falha ao enviar recuperação.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    try {
      final gsi = GoogleSignIn(
        clientId: '141446877512-vjt42b2otvsch6292i2mrb129koko7jj.apps.googleusercontent.com',
        serverClientId: '141446877512-0ibqum1ik8hkpao5mquohe14eu42kmtb.apps.googleusercontent.com',
        scopes: ['email'],
      );
      await gsi.signOut(); // força o picker a aparecer sempre
      final googleUser = await gsi.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        _showSnack('Google Sign-In: idToken não disponível.');
        return;
      }
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AquanautixHome()),
        );
      }
    } catch (e) {
      _showSnack('Erro Google: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAuthError(String msg) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF071428),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Erro de autenticação',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(msg, style: const TextStyle(color: Color(0xFF8AADBE), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00F5FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _translateAuthError(String supabaseMsg) {
    final msg = supabaseMsg.toLowerCase();
    if (msg.contains('email not confirmed')) {
      return 'Email não confirmado. Verifica a tua caixa de entrada.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid password')) {
      return 'Email ou password incorrectos.';
    }
    if (msg.contains('user not found')) {
      return 'Conta não encontrada. Faz registo primeiro.';
    }
    if (msg.contains('too many requests') || msg.contains('rate limit')) {
      return 'Demasiadas tentativas. Aguarda alguns minutos.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Sem ligação à internet. Verifica a tua rede.';
    }
    return supabaseMsg;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: kCard,
      ),
    );
  }

  void _enterAsGuest() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AquanautixHome()),
    );
  }

  void _refreshSessionState() {
    if (!mounted) return;
    setState(() {
      _sessionActive = isSupabaseAuthenticated;
    });
  }
}

/// Ícone Google — paths SVG oficiais (viewBox 24×24) escalados para o canvas.
class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final fill = Paint()..style = PaintingStyle.fill;

    // Azul — lado direito + barra horizontal
    fill.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(22.56 * s, 12.25 * s)
        ..cubicTo(22.56 * s, 11.47 * s, 22.49 * s, 10.72 * s, 22.36 * s, 10.0 * s)
        ..lineTo(12.0 * s, 10.0 * s)
        ..lineTo(12.0 * s, 14.26 * s)
        ..lineTo(17.92 * s, 14.26 * s)
        ..cubicTo(17.66 * s, 15.63 * s, 16.88 * s, 16.79 * s, 15.71 * s, 17.57 * s)
        ..lineTo(15.71 * s, 20.34 * s)
        ..lineTo(19.28 * s, 20.34 * s)
        ..cubicTo(21.36 * s, 18.42 * s, 22.56 * s, 15.6 * s, 22.56 * s, 12.25 * s)
        ..close(),
      fill,
    );

    // Verde — parte inferior
    fill.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(12.0 * s, 23.0 * s)
        ..cubicTo(14.97 * s, 23.0 * s, 17.46 * s, 22.02 * s, 19.28 * s, 20.34 * s)
        ..lineTo(15.71 * s, 17.57 * s)
        ..cubicTo(14.73 * s, 18.23 * s, 13.48 * s, 18.63 * s, 12.0 * s, 18.63 * s)
        ..cubicTo(9.14 * s, 18.63 * s, 6.71 * s, 16.7 * s, 5.84 * s, 14.1 * s)
        ..lineTo(2.18 * s, 14.1 * s)
        ..lineTo(2.18 * s, 16.94 * s)
        ..cubicTo(3.99 * s, 20.53 * s, 7.7 * s, 23.0 * s, 12.0 * s, 23.0 * s)
        ..close(),
      fill,
    );

    // Amarelo — lado esquerdo
    fill.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(5.84 * s, 14.09 * s)
        ..cubicTo(5.62 * s, 13.43 * s, 5.49 * s, 12.73 * s, 5.49 * s, 12.0 * s)
        ..cubicTo(5.49 * s, 11.27 * s, 5.62 * s, 10.57 * s, 5.84 * s, 9.91 * s)
        ..lineTo(5.84 * s, 7.07 * s)
        ..lineTo(2.18 * s, 7.07 * s)
        ..cubicTo(1.43 * s, 8.55 * s, 1.0 * s, 10.22 * s, 1.0 * s, 12.0 * s)
        ..cubicTo(1.0 * s, 13.78 * s, 1.43 * s, 15.45 * s, 2.18 * s, 16.93 * s)
        ..lineTo(5.84 * s, 14.09 * s)
        ..close(),
      fill,
    );

    // Vermelho — canto superior esquerdo
    fill.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(12.0 * s, 5.38 * s)
        ..cubicTo(13.62 * s, 5.38 * s, 15.06 * s, 5.94 * s, 16.21 * s, 7.02 * s)
        ..lineTo(19.36 * s, 3.87 * s)
        ..cubicTo(17.45 * s, 2.09 * s, 14.97 * s, 1.0 * s, 12.0 * s, 1.0 * s)
        ..cubicTo(7.7 * s, 1.0 * s, 3.99 * s, 3.47 * s, 2.18 * s, 7.07 * s)
        ..lineTo(5.84 * s, 9.91 * s)
        ..cubicTo(6.71 * s, 7.31 * s, 9.14 * s, 5.38 * s, 12.0 * s, 5.38 * s)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Ícone Apple — paths SVG oficiais (viewBox 24×24) em branco.
class _AppleMarkPainter extends CustomPainter {
  const _AppleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    // Corpo da maçã
    canvas.drawPath(
      Path()
        ..moveTo(18.71 * s, 19.5 * s)
        ..cubicTo(17.88 * s, 20.74 * s, 17.0 * s, 21.95 * s, 15.66 * s, 21.97 * s)
        ..cubicTo(14.32 * s, 22.0 * s, 13.89 * s, 21.18 * s, 12.37 * s, 21.18 * s)
        ..cubicTo(10.84 * s, 21.18 * s, 10.37 * s, 21.95 * s, 9.1 * s, 22.0 * s)
        ..cubicTo(7.79 * s, 22.05 * s, 6.8 * s, 20.68 * s, 5.96 * s, 19.47 * s)
        ..cubicTo(4.25 * s, 17.0 * s, 2.94 * s, 12.45 * s, 4.7 * s, 9.39 * s)
        ..cubicTo(5.57 * s, 7.87 * s, 7.13 * s, 6.91 * s, 8.82 * s, 6.88 * s)
        ..cubicTo(10.1 * s, 6.86 * s, 11.32 * s, 7.75 * s, 12.11 * s, 7.75 * s)
        ..cubicTo(12.89 * s, 7.75 * s, 14.37 * s, 6.68 * s, 15.91 * s, 6.84 * s)
        ..cubicTo(16.56 * s, 6.87 * s, 18.38 * s, 7.1 * s, 19.55 * s, 8.82 * s)
        ..cubicTo(19.46 * s, 8.88 * s, 17.38 * s, 10.1 * s, 17.4 * s, 12.63 * s)
        ..cubicTo(17.43 * s, 15.65 * s, 20.05 * s, 16.66 * s, 20.08 * s, 16.67 * s)
        ..cubicTo(20.05 * s, 16.74 * s, 19.66 * s, 18.11 * s, 18.7 * s, 19.5 * s)
        ..close(),
      fill,
    );

    // Folha
    canvas.drawPath(
      Path()
        ..moveTo(13.0 * s, 3.5 * s)
        ..cubicTo(13.73 * s, 2.67 * s, 14.94 * s, 2.04 * s, 15.94 * s, 2.0 * s)
        ..cubicTo(16.07 * s, 3.17 * s, 15.6 * s, 4.35 * s, 14.9 * s, 5.19 * s)
        ..cubicTo(14.21 * s, 6.04 * s, 13.07 * s, 6.7 * s, 11.95 * s, 6.61 * s)
        ..cubicTo(11.8 * s, 5.46 * s, 12.36 * s, 4.26 * s, 13.0 * s, 3.5 * s)
        ..close(),
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
