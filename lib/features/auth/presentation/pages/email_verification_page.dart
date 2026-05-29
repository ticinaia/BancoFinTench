import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_repositories.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authRepository = AppRepositories.auth;
  bool _checking = false;
  bool _sending = false;

  Future<void> _checkVerification() async {
    setState(() => _checking = true);

    try {
      await _authRepository.reloadCurrentUser();
      if (!mounted) return;

      if (_authRepository.isEmailVerified) {
        final nextRoute = await _authRepository.hasAppPin()
            ? AppRoutes.authLock
            : AppRoutes.pinSetup;
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, nextRoute);
        return;
      }

      _showMessage('Ainda não encontramos a confirmação desse e-mail.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resendEmail() async {
    setState(() => _sending = true);

    try {
      await _authRepository.sendEmailVerification();
      if (!mounted) return;
      _showMessage('Enviamos um novo e-mail de confirmação.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage('Não foi possível reenviar (${error.code}).');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível reenviar agora.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _authRepository.currentUser?.email ?? 'seu e-mail';

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sair'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Confirme seu e-mail',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enviamos uma confirmação para $email. Depois de confirmar, volte aqui para liberar sua conta.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _checking ? null : _checkVerification,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(_checking ? 'Verificando...' : 'Já confirmei'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _sending ? null : _resendEmail,
              icon: const Icon(Icons.send_outlined),
              label: Text(_sending ? 'Enviando...' : 'Reenviar e-mail'),
            ),
          ],
        ),
      ),
    );
  }
}
