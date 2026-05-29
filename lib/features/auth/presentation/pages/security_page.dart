import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme_controller.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/validators/br_auth_validators.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _loading = true;
  bool _savingProfile = false;
  bool _sendingPassword = false;
  bool _sendingEmail = false;
  bool _changingPin = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final appUser = await _authRepository.currentAppUser();
    final firebaseUser = _authRepository.currentUser;

    if (!mounted) return;

    _nameController.text = appUser?.name ?? firebaseUser?.displayName ?? '';
    _cpfController.text = appUser?.cpf ?? '';
    _phoneController.text = appUser?.phone ?? '';
    _emailController.text = firebaseUser?.email ?? '';

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _confirmPin()) return;

    setState(() => _savingProfile = true);

    try {
      await _authRepository.updateProfile(
        name: _nameController.text.trim(),
        cpf: BrAuthValidators.onlyDigits(_cpfController.text),
        phone: BrAuthValidators.onlyDigits(_phoneController.text),
      );
      if (!mounted) return;
      _showMessage('Dados atualizados.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível atualizar seus dados.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _requestPasswordReset() async {
    setState(() => _sendingPassword = true);

    try {
      await _authRepository.sendPasswordResetForCurrentUser();
      if (!mounted) return;
      _showMessage('Enviamos um link para alterar sua senha.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível enviar o link de senha.');
    } finally {
      if (mounted) setState(() => _sendingPassword = false);
    }
  }

  Future<void> _changePin() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final payload = await showDialog<({String currentPin, String newPin})>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trocar PIN'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'PIN atual',
                    counterText: '',
                  ),
                  validator: _pinValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Novo PIN',
                    counterText: '',
                  ),
                  validator: _pinValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Confirmar novo PIN',
                    counterText: '',
                  ),
                  validator: (value) {
                    final error = _pinValidator(value);
                    if (error != null) return error;
                    if (value != newController.text) {
                      return 'Os PINs não coincidem';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  (
                    currentPin: currentController.text.trim(),
                    newPin: newController.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    currentController.dispose();
    newController.dispose();
    confirmController.dispose();

    if (payload == null) return;

    setState(() => _changingPin = true);
    try {
      await _authRepository.changeAppPin(
        currentPin: payload.currentPin,
        newPin: payload.newPin,
      );
      if (!mounted) return;
      _showMessage('PIN atualizado.');
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível trocar o PIN.');
    } finally {
      if (mounted) setState(() => _changingPin = false);
    }
  }

  String? _pinValidator(String? value) {
    final pin = value?.trim() ?? '';
    if (pin.length < 4) return 'Use pelo menos 4 dígitos';
    if (RegExp(r'^(\d)\1*$').hasMatch(pin)) {
      return 'Evite sequências repetidas';
    }
    return null;
  }

  Future<void> _requestEmailChange() async {
    final newEmail = _emailController.text.trim();
    if (!BrAuthValidators.isValidEmail(newEmail)) {
      _showMessage('Informe um e-mail válido terminado em .com ou .com.br.');
      return;
    }
    if (!await _confirmPin()) return;

    setState(() => _sendingEmail = true);

    try {
      await _authRepository.requestEmailChange(newEmail);
      if (!mounted) return;
      _showMessage('Enviamos uma confirmação para o novo e-mail.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível solicitar a troca de e-mail.');
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir conta?'),
          content: const Text(
            'Essa ação remove seu acesso e não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!await _confirmPin()) return;

    setState(() => _deleting = true);

    try {
      await _authRepository.deleteCurrentAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não foi possível excluir a conta.');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    if (error.code == 'requires-recent-login') {
      return 'Entre novamente antes de fazer essa alteração.';
    }
    if (error.code == 'email-already-in-use') {
      return 'Esse e-mail já está em uso.';
    }
    if (error.code == 'invalid-email') {
      return 'Informe um e-mail válido.';
    }
    return 'Erro no Firebase Auth (${error.code}).';
  }

  Future<bool> _confirmPin() async {
    final pinController = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar identidade'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'PIN do app',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                pinController.text.trim(),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    pinController.dispose();
    if (pin == null || pin.isEmpty) return false;

    final valid = await _authRepository.validateAppPin(pin);
    if (!valid && mounted) _showMessage('PIN incorreto.');
    return valid;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segurança'),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 3),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    'Dados da conta',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nome completo',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            final name = value?.trim() ?? '';
                            if (name.isEmpty) return 'Informe seu nome';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CPF',
                            prefixIcon: Icon(Icons.credit_card_outlined),
                          ),
                          validator: (value) {
                            if (!BrAuthValidators.isValidCpf(value ?? '')) {
                              return 'Informe um CPF válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Celular',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) {
                            if (!BrAuthValidators.isValidBrPhone(value ?? '')) {
                              return 'Informe um celular com 9 dígitos';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _savingProfile ? null : _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      _savingProfile ? 'Salvando...' : 'Salvar dados',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Acesso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Novo e-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _sendingEmail ? null : _requestEmailChange,
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text(
                      _sendingEmail
                          ? 'Enviando...'
                          : 'Solicitar troca de e-mail',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _sendingPassword ? null : _requestPasswordReset,
                    icon: const Icon(Icons.lock_reset_rounded),
                    label: Text(
                      _sendingPassword
                          ? 'Enviando...'
                          : 'Alterar senha por e-mail',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _changingPin ? null : _changePin,
                    icon: const Icon(Icons.pin_outlined),
                    label: Text(_changingPin ? 'Salvando...' : 'Trocar PIN'),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Preferências',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: AppThemeController.mode,
                    builder: (context, themeMode, _) {
                      return DropdownButtonFormField<ThemeMode>(
                        initialValue: themeMode,
                        decoration: const InputDecoration(
                          labelText: 'Aparência',
                          prefixIcon: Icon(Icons.dark_mode_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Usar tema do sistema'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Modo claro'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Modo escuro'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          AppThemeController.setMode(value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Zona sensível',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _deleting ? null : _deleteAccount,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(_deleting ? 'Excluindo...' : 'Excluir conta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
