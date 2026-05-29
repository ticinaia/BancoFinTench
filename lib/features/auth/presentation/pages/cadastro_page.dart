import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_repositories.dart';
import '../../../../core/utils/br_input_formatters.dart';
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
  final _authRepository = AppRepositories.auth;

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
        'Não conseguimos abrir o cadastro agora. Tente novamente em instantes.',
      );
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
    } on FirebaseException {
      if (!mounted) return;
      _mostrarErro(
        'O serviço ficou indisponível por um momento. Tente novamente em instantes.',
      );
    } catch (_) {
      if (!mounted) return;
      _mostrarErro(
        'Não conseguimos criar sua conta agora. Tente novamente em instantes.',
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _mensagemFirebaseAuth(FirebaseAuthException erro) {
    switch (erro.code) {
      case 'email-already-in-use':
        return 'Esse e-mail já tem uma conta. Entre pelo login.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'operation-not-allowed':
        return 'O cadastro está temporariamente indisponível.';
      case 'weak-password':
        return 'Essa senha ainda está fraca. Use pelo menos 8 caracteres.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      default:
        return 'Não conseguimos criar sua conta agora. Tente novamente em instantes.';
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

  String? _validarNome(String? valor) {
    final text = valor?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    if (text.isEmpty) return 'Informe seu nome';
    if (text.length < 5) return 'Informe seu nome completo';
    final nomes = text.split(' ');
    if (nomes.length < 2 || nomes.any((nome) => nome.length < 2)) {
      return 'Informe nome e sobrenome';
    }
    if (!RegExp(r"^[A-Za-zÀ-ÖØ-öø-ÿ' ]+$").hasMatch(text)) {
      return 'Use apenas letras no nome';
    }
    return null;
  }

  String? _validarSenha(String? valor) {
    final senha = valor ?? '';
    if (senha.isEmpty) return 'Informe sua senha';
    if (senha.contains(RegExp(r'\s'))) {
      return 'A senha não pode conter espaços';
    }
    if (senha.length < 8) {
      return 'A senha deve ter pelo menos 8 caracteres';
    }
    if (!RegExp(r'[A-ZÀ-Ö]').hasMatch(senha)) {
      return 'Use pelo menos uma letra maiúscula';
    }
    if (!RegExp(r'[a-zà-öø-ÿ]').hasMatch(senha)) {
      return 'Use pelo menos uma letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(senha)) {
      return 'Use pelo menos um número';
    }
    return null;
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
              'Vamos criar sua conta',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Preencha seus dados para começar a usar o FinTech com segurança.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _validarNome,
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
                      if (!BrAuthValidators.isValidEmail(valor.trim())) {
                        return 'Digite um e-mail válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [BrInputFormatters.cpf],
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
                    inputFormatters: [BrInputFormatters.brMobilePhone],
                    decoration: const InputDecoration(
                      labelText: 'Celular',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (valor) {
                      final digits = _onlyDigits(valor ?? '');
                      if (digits.isEmpty) return 'Informe seu celular';
                      if (!BrAuthValidators.isValidBrPhone(digits)) {
                        return 'Digite um celular válido com DDD';
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
                    validator: _validarSenha,
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
                      if (valor == null || valor.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      if (valor != _senhaController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  FormField<bool>(
                    initialValue: _aceitouTermos,
                    validator: (_) {
                      if (!_aceitouTermos) {
                        return 'Aceite os termos para continuar';
                      }
                      return null;
                    },
                    builder: (field) {
                      return CheckboxListTile(
                        value: _aceitouTermos,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Li e aceito os termos de uso e a política de privacidade.',
                        ),
                        onChanged: (value) {
                          setState(() => _aceitouTermos = value ?? false);
                          field.didChange(value ?? false);
                        },
                        subtitle: field.hasError
                            ? Text(
                                field.errorText!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            : null,
                      );
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
              label: Text(_carregando ? 'Criando conta...' : 'Criar conta'),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
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
