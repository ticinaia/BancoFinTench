import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/validators/br_auth_validators.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _carregando = false;
  bool _aceitouTermos = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_authRepository.isAvailable) {
      _mostrarErro(
          'Serviço indisponível no momento. Tente novamente mais tarde.');
      return;
    }

    setState(() => _carregando = true);

    try {
      await _authRepository.createUser(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
        name: _nomeController.text.trim(),
        cpf: _onlyDigits(_cpfController.text),
        phone: _onlyDigits(_telefoneController.text),
        acceptedTerms: _aceitouTermos,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.emailVerification);
    } on FirebaseAuthException catch (erro) {
      if (!mounted) return;
      _mostrarErro(_mensagemFirebaseAuth(erro));
    } on FirebaseException catch (erro) {
      if (!mounted) return;
      _mostrarErro(
        'Serviço temporariamente indisponível. Tente novamente em instantes.',
      );
    } catch (erro) {
      if (!mounted) return;
      _mostrarErro('Não foi possível criar a conta. Tente novamente em instantes.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagemFirebaseAuth(FirebaseAuthException erro) {
    switch (erro.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está cadastrado. Volte para o login.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'operation-not-allowed':
        return 'Cadastro não disponível no momento. Tente mais tarde.';
      case 'weak-password':
        return 'Senha muito fraca. Use pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Não foi possível criar a conta. Tente novamente em instantes.';
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  String _onlyDigits(String value) {
    return BrAuthValidators.onlyDigits(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Crie sua conta',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Leva menos de um minuto para começar a usar o BancoFinTech.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (valor) {
                      final text = valor?.trim() ?? '';
                      if (text.isEmpty) return 'Informe seu nome';
                      if (text.split(' ').length < 2) {
                        return 'Informe nome e sobrenome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
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
                      if (!BrAuthValidators.isValidEmail(valor)) {
                        return 'Use um e-mail válido com @ e .com';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      prefixIcon: Icon(Icons.credit_card_outlined),
                    ),
                    validator: (valor) {
                      final digits = _onlyDigits(valor ?? '');
                      if (digits.isEmpty) return 'Informe seu CPF';
                      if (!BrAuthValidators.isValidCpf(digits)) {
                        return 'Informe um CPF válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (valor) {
                      final digits = _onlyDigits(valor ?? '');
                      if (digits.isEmpty) return 'Informe seu celular';
                      if (!BrAuthValidators.isValidBrPhone(digits)) {
                        return 'Informe um celular com 9 dígitos';
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
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _aceitouTermos,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Li e aceito os termos de uso e a política de privacidade.',
                    ),
                    onChanged: (value) {
                      setState(() => _aceitouTermos = value ?? false);
                    },
                    subtitle: !_aceitouTermos
                        ? const Text('Obrigatório para criar a conta')
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _carregando || !_aceitouTermos ? null : _cadastrar,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Já tem conta?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}