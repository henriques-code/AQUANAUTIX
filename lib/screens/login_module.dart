import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '_shared.dart';
import '../core/supabase_bootstrap.dart';

/// Módulo de Login sem alterar o design base da app.
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

  @override
  void initState() {
    super.initState();
    _refreshSessionState();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        centerTitle: false,
        title: Text('LOGIN', style: mono(11, c: kCyan, ls: 1.4)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kCyan.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ENTRA NA TUA CONTA', style: orb(13, c: kCyan, ls: 1.2)),
                  const SizedBox(height: 6),
                  Text(
                    _sessionActive
                        ? 'Sessão ativa. O teu histórico está sincronizado.'
                        : 'Sincroniza missões, histórico e alertas legais em todos os dispositivos.',
                    style: ibm(11, c: Colors.white70),
                  ),
                  if (_sessionActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kGreen.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        'SESSÃO ATIVA · ${supabaseCurrentUserEmail ?? 'UTILIZADOR'}',
                        style: mono(9, c: kGreen, ls: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('EMAIL'),
            const SizedBox(height: 6),
            _inputField(
              hint: 'teu.email@aquanautix.com',
              icon: Icons.alternate_email_rounded,
              controller: _emailCtrl,
            ),
            const SizedBox(height: 12),
            _fieldLabel('PASSWORD'),
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
                  color: kHint,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      Icon(
                        _rememberMe ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                        color: _rememberMe ? kCyan : kHint,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text('Lembrar sessão', style: ibm(11, c: Colors.white70)),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _loading ? null : _recoverPassword,
                  child: Text('Recuperar password', style: ibm(11, c: kCyan)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _loading ? null : _signIn,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: kCyan,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: kCyan.withValues(alpha: 0.24), blurRadius: 8)],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : Text('INICIAR SESSÃO', style: orb(11, c: Colors.black, ls: 1.4)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loading ? null : _signUp,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kHint.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text('CRIAR NOVA CONTA', style: orb(11, c: kHint, ls: 1.2)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _loading ? null : _enterAsGuest,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kCyan.withValues(alpha: 0.18)),
                ),
                child: Center(
                  child: Text('ENTRAR COMO CONVIDADO', style: orb(11, c: kCyan, ls: 1.2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) => Text(label, style: mono(10, c: kHint, ls: 1.1));

  Widget _inputField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF06101E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kCyan.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(icon, size: 17, color: kHint),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: ibm(12),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: ibm(12, c: kHint.withValues(alpha: 0.6)),
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
      await client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      _refreshSessionState();
      _showSnack('Sessão iniciada com sucesso.');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Falha ao iniciar sessão.');
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
      await client.auth.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      _refreshSessionState();
      _showSnack('Conta criada. Verifica o email para confirmação.');
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
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
    _showSnack('Modo convidado ativo.');
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _refreshSessionState() {
    if (!mounted) return;
    setState(() {
      _sessionActive = isSupabaseAuthenticated;
    });
  }
}
