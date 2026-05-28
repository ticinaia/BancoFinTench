import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixTransferPage extends StatefulWidget {
  const PixTransferPage({super.key});

  @override
  State<PixTransferPage> createState() => _PixTransferPageState();
}

class _PixTransferPageState extends State<PixTransferPage> {
  final _formKey = GlobalKey<FormState>();
  final _chaveController = TextEditingController();
  final _valorController = TextEditingController();
  final _pixRepository = PixRepository();

  String _tipoChave = 'E-mail';
  bool _enviando = false;

  @override
  void dispose() {
    _chaveController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPix() async {
    if (!_formKey.currentState!.validate()) return;

    final valorCentavos = BrFormatters.parseCurrencyToCentavos(
      _valorController.text,
    );
    final confirmado = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar PIX',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _ResumoLinha(
                  label: 'Valor',
                  value: BrFormatters.currencyFromCentavos(valorCentavos),
                ),
                _ResumoLinha(label: 'Tipo de chave', value: _tipoChave),
                _ResumoLinha(
                    label: 'Chave', value: _chaveController.text.trim()),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Confirmar com segurança'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmado != true) return;
    await _enviarPix(valorCentavos);
  }

  Future<void> _enviarPix(int valorCentavos) async {
    setState(() => _enviando = true);

    try {
      final autenticado = await _autenticarAcaoSensivel();
      if (!autenticado) {
        _mostrarMensagem('Autenticação cancelada.');
        return;
      }

      await _pixRepository.enviarPix(
        chave: _chaveController.text.trim(),
        valorCentavos: valorCentavos,
      );

      if (!mounted) return;
      _mostrarMensagem('PIX enviado com sucesso.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível enviar o PIX.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<bool> _autenticarAcaoSensivel() async {
    final biometriaDisponivel = await AppPlugins.localAuth.canCheckBiometrics;
    final dispositivoSuporta = await AppPlugins.localAuth.isDeviceSupported();

    if (!biometriaDisponivel && !dispositivoSuporta) return true;

    return AppPlugins.localAuth.authenticate(
      localizedReason: 'Confirme sua identidade para enviar o PIX',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferência PIX'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.pix_rounded,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Enviar PIX',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Confira os dados antes de confirmar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _tipoChave,
                items: const [
                  DropdownMenuItem(value: 'E-mail', child: Text('E-mail')),
                  DropdownMenuItem(value: 'CPF', child: Text('CPF')),
                  DropdownMenuItem(value: 'Telefone', child: Text('Telefone')),
                  DropdownMenuItem(
                    value: 'Aleatória',
                    child: Text('Chave aleatória'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Tipo de chave',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _tipoChave = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chaveController,
                decoration: const InputDecoration(
                  labelText: 'Chave PIX',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe a chave PIX';
                  if (_tipoChave == 'E-mail' && !text.contains('@')) {
                    return 'Informe um e-mail válido';
                  }
                  if (_tipoChave == 'CPF' &&
                      text.replaceAll(RegExp(r'[^0-9]'), '').length != 11) {
                    return 'Informe um CPF com 11 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Valor',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
                validator: (value) {
                  final centavos = BrFormatters.parseCurrencyToCentavos(
                    value ?? '',
                  );
                  if (centavos <= 0) return 'Informe um valor válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  _mostrarMensagem('Leitura de QR Code ainda não configurada.');
                },
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Ler QR Code'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _enviando ? null : _confirmarPix,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_rounded),
                label: Text(_enviando ? 'Enviando...' : 'Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumoLinha extends StatelessWidget {
  const _ResumoLinha({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
