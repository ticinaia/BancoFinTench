import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _carregando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_authRepository.isAvailable) {
      _mostrarErro(
          'Firebase indisponivel. Habilite Authentication no console.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await _authRepository.createUser(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;
      _mostrarErro(_mensagemFirebaseAuth(erro));
    } on FirebaseException catch (erro) {
      if (!mounted) return;
      _mostrarErro(
        'Erro no Firebase (${erro.plugin}/${erro.code}). Confira as regras e servicos habilitados.',
      );
    } catch (erro) {
      if (!mounted) return;
      _mostrarErro('Nao foi possivel criar a conta: $erro');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagemFirebaseAuth(FirebaseAuthException erro) {
    switch (erro.code) {
      case 'email-already-in-use':
        return 'Este e-mail ja esta cadastrado. Volte para o login.';
      case 'invalid-email':
        return 'Informe um e-mail valido.';
      case 'operation-not-allowed':
        return 'Login por e-mail/senha nao foi habilitado no Firebase Authentication.';
      case 'weak-password':
        return 'A senha e muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexao com o Firebase. Verifique sua internet.';
      default:
        return 'Erro no Firebase Auth (${erro.code}).';
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const Icon(
              Icons.person_add_rounded,
              color: AppColors.primary,
              size: 72,
            ),
            const SizedBox(height: 24),
            Text(
              'Criar Conta',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
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
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!valor.contains('@')) {
                        return 'Informe um e-mail valido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe sua senha';
                      }
                      if (valor.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (valor) {
                      if (valor != _senhaController.text) {
                        return 'As senhas nao coincidem';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregando ? null : _cadastrar,
              icon: _carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: Text(_carregando ? 'Cadastrando...' : 'Cadastrar'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ja tenho uma conta'),
            ),
          ],
        ),
      ),
    );
  }
}
