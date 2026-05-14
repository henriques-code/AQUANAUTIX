import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '_shared.dart';
import '../core/supabase_bootstrap.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: Text('NOVA PASSWORD', style: mono(11, c: kCyan, ls: 1.4)),
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
              child: Text(
                'Define uma password nova para concluir a recuperação da conta.',
                style: ibm(11, c: Colors.white70),
              ),
            ),
            const SizedBox(height: 14),
            _fieldLabel('NOVA PASSWORD'),
            const SizedBox(height: 6),
            _inputField(
              controller: _newPasswordCtrl,
              icon: Icons.lock_outline_rounded,
              hint: '********',
              obscure: !_showPass,
            ),
            const SizedBox(height: 12),
            _fieldLabel('CONFIRMAR PASSWORD'),
            const SizedBox(height: 6),
            _inputField(
              controller: _confirmPasswordCtrl,
              icon: Icons.verified_user_outlined,
              hint: '********',
              obscure: !_showPass,
              trailing: IconButton(
                onPressed: () => setState(() => _showPass = !_showPass),
                icon: Icon(
                  _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: kHint,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _loading ? null : _submitReset,
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
                      : Text('GUARDAR PASSWORD', style: orb(11, c: Colors.black, ls: 1.4)),
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
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool obscure,
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

  Future<void> _submitReset() async {
    final pass = _newPasswordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;
    if (pass.length < 6) {
      _showSnack('A password deve ter pelo menos 6 caracteres.');
      return;
    }
    if (pass != confirm) {
      _showSnack('As passwords não coincidem.');
      return;
    }

    final client = supabaseClientOrNull;
    if (client == null || !isSupabaseConfigured) {
      _showSnack('Supabase não configurado.');
      return;
    }

    setState(() => _loading = true);
    try {
      await client.auth.updateUser(UserAttributes(password: pass));
      _showSnack('Password atualizada com sucesso.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Falha ao atualizar password.');
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
}

