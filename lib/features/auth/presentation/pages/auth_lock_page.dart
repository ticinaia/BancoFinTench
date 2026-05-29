import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_repositories.dart';
import '../../../../core/services/app_plugins.dart';
import '../../data/services/auth_session_service.dart';

class AuthLockPage extends StatefulWidget {
  const AuthLockPage({super.key});

  @override
  State<AuthLockPage> createState() => _AuthLockPageState();
}

class _AuthLockPageState extends State<AuthLockPage> {
  final _authRepository = AppRepositories.auth;
  final _pinController = TextEditingController();
  bool _unlocking = false;
  bool _checkingPin = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    setState(() => _unlocking = true);

    try {
      if (!await _authRepository.hasAppPin()) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AppRoutes.pinSetup);
        return;
      }

      final unlocked = await _authenticate();
      if (!mounted) return;

      if (unlocked) {
        _finishUnlock();
      } else {
        _showMessage('Use seu PIN para desbloquear.');
      }
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.length < 4) {
      _showMessage('Informe seu PIN.');
      return;
    }

    setState(() => _checkingPin = true);

    try {
      final isValid = await _authRepository.validateAppPin(pin);
      if (!mounted) return;

      if (isValid) {
        _finishUnlock();
      } else {
        _showMessage('PIN incorreto.');
      }
    } finally {
      if (mounted) setState(() => _checkingPin = false);
    }
  }

  void _finishUnlock() {
    AuthSessionService.unlock();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  Future<bool> _authenticate() async {
    if (kIsWeb) return false;

    try {
      final canCheckBiometrics = await AppPlugins.localAuth.canCheckBiometrics;
      final isSupported = await AppPlugins.localAuth.isDeviceSupported();

      if (!canCheckBiometrics && !isSupported) return false;

      return AppPlugins.localAuth.authenticate(
        localizedReason: 'Desbloqueie para acessar sua conta',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
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
    final userName =
        _authRepository.currentUser?.displayName?.trim().isNotEmpty == true
            ? _authRepository.currentUser!.displayName!.trim()
            : 'Cliente';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.viewInsetsOf(context).bottom + 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Conta protegida',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Olá, $userName. Confirme sua identidade para continuar.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'PIN do app',
                        prefixIcon: Icon(Icons.password_rounded),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _unlockWithPin(),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _checkingPin ? null : _unlockWithPin,
                      icon: const Icon(Icons.key_rounded),
                      label: Text(
                        _checkingPin ? 'Conferindo...' : 'Entrar com PIN',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _unlocking ? null : _unlock,
                      icon: _unlocking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        _unlocking ? 'Desbloqueando...' : 'Desbloquear',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
