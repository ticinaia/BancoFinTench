import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/firebase_service.dart';
import '../../data/repositories/auth_repository.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_authRepository.isAvailable) {
      _showError(
        'Firebase indisponivel. Confira se Authentication e Firestore foram habilitados no console.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showError(_firebaseAuthMessage(error));
    } catch (error) {
      if (!mounted) return;
      _showError(
          'Nao foi possivel entrar. Verifique e-mail, senha e Firebase.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Informe um e-mail valido.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'E-mail ou senha incorretos.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha nao foi habilitado no Firebase Authentication.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
      case 'network-request-failed':
        return 'Sem conexao com o Firebase. Verifique sua internet.';
      default:
        return 'Erro no Firebase Auth (${error.code}).';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.account_balance_rounded,
              color: AppColors.primary,
              size: 72,
            ),
            const SizedBox(height: 24),
            Text(
              'BancoFinTech',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              FirebaseService.isReady
                  ? 'Firebase inicializado'
                  : 'Firebase configurado, mas indisponivel neste ambiente',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!value.trim().contains('@')) {
                        return 'Informe um e-mail valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe sua senha';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _login,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? 'Entrando...' : 'Entrar'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.cadastro),
              icon: const Icon(Icons.person_add),
              label: const Text('Nao tenho conta. Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}
