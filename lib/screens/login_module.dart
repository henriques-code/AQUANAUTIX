import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '_shared.dart';
import '../core/auth/login_session_store.dart';
import '../core/auth/password_recovery_service.dart';
import '../core/l10n/aqx_l10n.dart';
import '../core/state/app_locale_store.dart';
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
    unawaited(_bootstrapLogin());
    unawaited(_initVideo());
  }

  Future<void> _bootstrapLogin() async {
    await LoginSessionStore.applySessionPolicy();
    if (!mounted) return;

    final remember = await LoginSessionStore.getRememberSession();
    final email = await LoginSessionStore.getSavedEmail();
    if (!mounted) return;

    setState(() {
      _rememberMe = remember;
      if (email != null && email.isNotEmpty) {
        _emailCtrl.text = email;
      }
    });

    if (!canUseSupabase) return;
    final session = supabaseClientOrNull?.auth.currentSession;
    if (session != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AquanautixHome()),
      );
    }
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

  AqxL10n get _t => AqxL10n(AppLocaleStore.instance.locale.languageCode);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleStore.instance,
      builder: (context, _) => _buildLogin(context),
    );
  }

  Widget _buildLogin(BuildContext context) {
    final t = _t;
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
                  Row(
                    children: [
                      const Spacer(),
                      _LoginLangPicker(
                        current: AppLocaleStore.instance.locale.languageCode,
                        onSelect: (code) =>
                            unawaited(AppLocaleStore.instance.setLocale(code)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
                    t.loginEliteTagline,
                    style: GoogleFonts.shareTechMono(
                      fontSize: 13,
                      color: _hint,
                      letterSpacing: 2.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t.loginWelcome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.loginSubtitle,
                    style: ibm(13, c: Colors.white.withValues(alpha: 0.82)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _socialButton(
                    label: t.loginContinueGoogle,
                    icon: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _GoogleMarkPainter()),
                    ),
                    onTap: _signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _socialButton(
                    label: t.loginContinueApple,
                    icon: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CustomPaint(painter: _AppleMarkPainter()),
                    ),
                    onTap: () => _showSnack(t.loginComingSoon),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(t.loginOr, style: ibm(11, c: _hint, ls: 1.2)),
                      ),
                      Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.loginEmailLabel,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _inputField(
                    hint: t.loginEmailHint,
                    icon: Icons.mail_outline_rounded,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.loginPasswordLabel,
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
                      onTap: () async {
                        final next = !_rememberMe;
                        setState(() => _rememberMe = next);
                        await LoginSessionStore.setRememberSession(next);
                        if (!next) {
                          await LoginSessionStore.setSavedEmail(null);
                          if (canUseSupabase) {
                            await supabaseClientOrNull?.auth.signOut();
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            color: _rememberMe ? _cyan : _hint,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(t.loginRememberSession, style: ibm(12, c: Colors.white.withValues(alpha: 0.75))),
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
                                  t.loginSignIn,
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
                          onTap: _loading ? null : _showRegisterDialog,
                          child: Text.rich(
                            TextSpan(
                              style: ibm(12, c: Colors.white54),
                              children: [
                                TextSpan(text: t.loginNoAccount),
                                TextSpan(
                                  text: t.loginRegister,
                                  style: ibm(12, c: _cyan, fw: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading ? null : _showResetPasswordDialog,
                        child: Text(t.loginRecoverPassword, style: ibm(12, c: _cyan, fw: FontWeight.w600)),
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
                            t.loginGuest,
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
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
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
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              autocorrect: keyboardType == TextInputType.emailAddress ? false : true,
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
      _showSnack(_t.loginSupabaseGuestFallback);
      return null;
    }
    return supabaseClientOrNull;
  }

  String? _validateInputs({required bool requirePassword}) {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || !email.contains('@')) {
      return _t.loginInvalidEmail;
    }
    if (requirePassword && password.length < 6) {
      return _t.loginPasswordMinLength;
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
      await LoginSessionStore.persistAfterLogin(
        rememberSession: _rememberMe,
        email: _emailCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AquanautixHome()),
        );
      }
    } on AuthException catch (e) {
      debugPrint('[AUTH] AuthException: ${e.message} | statusCode: ${e.statusCode}');
      if (mounted) setState(() => _loading = false);
      await _showAuthError(_t.loginAuthErrorMessage(e.message));
      return;
    } catch (e) {
      debugPrint('[AUTH] Unexpected error: $e');
      if (mounted) setState(() => _loading = false);
      await _showAuthError('${_t.loginUnexpectedError}$e');
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRegisterDialog() {
    final t = _t;
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool loading = false;
        bool showPass = false;
        bool showConfirm = false;

        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.loginCreateAccountTitle,
                    style: GoogleFonts.orbitron(fontSize: 16, color: kCyan, letterSpacing: 2)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t.loginEmailLabel,
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: kCyan),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: !showPass,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t.loginPasswordLabel,
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: kCyan),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(showPass ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54, size: 20),
                      onPressed: () => setModalState(() => showPass = !showPass),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: !showConfirm,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t.loginConfirmPassword,
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: kCyan),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white54, size: 20),
                      onPressed: () => setModalState(() => showConfirm = !showConfirm),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: loading ? null : () async {
                      if (emailCtrl.text.trim().isEmpty) {
                        _showSnack(t.loginEnterEmail);
                        return;
                      }
                      if (passCtrl.text.length < 6) {
                        _showSnack(t.loginPasswordMinLength);
                        return;
                      }
                      if (passCtrl.text != confirmCtrl.text) {
                        _showSnack(t.loginPasswordsMismatch);
                        return;
                      }
                      setModalState(() => loading = true);
                      try {
                        final client = supabaseClientOrNull;
                        if (client == null) {
                          _showSnack(t.loginSupabaseGuestFallback);
                          return;
                        }
                        final response = await client.auth.signUp(
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text,
                          emailRedirectTo: null,
                        );
                        debugPrint('[REGISTER] user: ${response.user?.email}');
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _showSnack(t.loginAccountCreated);
                      } on AuthException catch (e) {
                        debugPrint('[REGISTER] AuthException: ${e.message}');
                        _showSnack(t.loginAuthErrorMessage(e.message));
                      } catch (e) {
                        debugPrint('[REGISTER] Error: $e');
                        _showSnack('${t.loginCreateAccountError}$e');
                      } finally {
                        if (ctx.mounted) setModalState(() => loading = false);
                      }
                    },
                    child: loading
                        ? const SizedBox(height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text(t.loginCreateAccountTitle,
                            style: GoogleFonts.orbitron(fontSize: 12, letterSpacing: 1.5)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResetPasswordDialog() {
    final t = _t;
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        bool loading = false;
        bool sent = false;
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.loginResetTitle,
                    style: GoogleFonts.orbitron(fontSize: 14, color: kCyan, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  t.loginResetBody,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !sent,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: t.loginEmailLabel,
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: kCyan.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: kCyan),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ),
                if (sent)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${t.loginResetSent}\n\n${t.loginResetSpamHint}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: loading ? null : () async {
                        final email = emailCtrl.text.trim();
                        setModalState(() {
                          loading = true;
                          errorText = null;
                        });
                        try {
                          await PasswordRecoveryService.instance.sendResetLink(email);
                          if (ctx.mounted) {
                            setModalState(() {
                              loading = false;
                              sent = true;
                            });
                          }
                        } on PasswordRecoveryException catch (e) {
                          if (ctx.mounted) {
                            setModalState(() {
                              loading = false;
                              errorText = e.message;
                            });
                          }
                        } catch (e) {
                          debugPrint('[RESET] Error: $e');
                          if (ctx.mounted) {
                            setModalState(() {
                              loading = false;
                              errorText = t.loginResetEmailError;
                            });
                          }
                        }
                      },
                      child: loading
                          ? const SizedBox(height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : Text(t.loginSendLink,
                              style: GoogleFonts.orbitron(fontSize: 12, letterSpacing: 1.5)),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
        _showSnack(_t.loginGoogleTokenError);
        return;
      }
      final client = supabaseClientOrNull;
      if (client == null) {
        _showSnack(_t.loginSupabaseGuestFallback);
        return;
      }
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      final googleEmail = googleUser.email;
      await LoginSessionStore.persistAfterLogin(
        rememberSession: _rememberMe,
        email: googleEmail,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AquanautixHome()),
        );
      }
    } catch (e) {
      _showSnack('${_t.loginGoogleError}$e');
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
        title: Text(
          _t.loginAuthErrorTitle,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
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

}

class _LoginLangPicker extends StatelessWidget {
  const _LoginLangPicker({
    required this.current,
    required this.onSelect,
  });

  final String current;
  final ValueChanged<String> onSelect;

  static const _cyan = Color(0xFF00F5FF);
  static const _hint = Color(0xFF8AADBE);
  static const _white06 = Color.fromRGBO(255, 255, 255, 0.06);
  static const _white12 = Color.fromRGBO(255, 255, 255, 0.12);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final code in const ['pt', 'es', 'en']) ...[
          if (code != 'pt') const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onSelect(code),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: current == code
                    ? _cyan.withValues(alpha: 0.18)
                    : _white06,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: current == code
                      ? _cyan.withValues(alpha: 0.5)
                      : _white12,
                ),
              ),
              child: Text(
                code.toUpperCase(),
                style: GoogleFonts.shareTechMono(
                  fontSize: 9,
                  color: current == code ? _cyan : _hint,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ],
    );
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
