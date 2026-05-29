import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/repositories/pix_repository.dart';
import '../../domain/validators/pix_key_validator.dart';

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
  final _authRepository = AuthRepository();

  String _tipoChave = 'E-mail';
  bool _enviando = false;
  PixRecipient? _recipient;

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

    try {
      final saldo = await _pixRepository.getBalanceCentavos();
      if (valorCentavos > saldo) {
        _mostrarMensagem('Saldo insuficiente para enviar este PIX.');
        return;
      }

      final recipient = await _pixRepository.resolveRecipient(
        keyType: _tipoChave,
        key: _chaveController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _recipient = recipient);

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
                  _ResumoLinha(label: 'Destinatário', value: recipient.name),
                  _ResumoLinha(label: 'Banco', value: recipient.bank),
                  _ResumoLinha(label: 'Tipo de chave', value: _tipoChave),
                  _ResumoLinha(
                      label: 'Chave', value: _chaveController.text.trim()),
                  _ResumoLinha(
                    label: 'Data',
                    value: BrFormatters.dateTime(DateTime.now()),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Enviar PIX'),
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
      await _enviarPix(valorCentavos, recipient);
    } on StateError catch (error) {
      if (!mounted) return;
      _mostrarMensagem(error.message);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível confirmar os dados do PIX.');
    }
  }

  Future<void> _enviarPix(int valorCentavos, PixRecipient recipient) async {
    setState(() => _enviando = true);

    try {
      final autenticado = await _autenticarAcaoSensivel();
      if (!autenticado) {
        _mostrarMensagem('Autenticação cancelada.');
        return;
      }

      final receipt = await _pixRepository.enviarPix(
        chave: _chaveController.text.trim(),
        tipoChave: _tipoChave,
        valorCentavos: valorCentavos,
        recipient: recipient,
      );

      if (!mounted) return;
      _mostrarMensagem('PIX enviado com sucesso.');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.pixReceipt,
        arguments: receipt,
      );
    } on StateError catch (error) {
      if (!mounted) return;
      _mostrarMensagem(error.message);
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível enviar o PIX.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<bool> _autenticarAcaoSensivel() async {
    if (kIsWeb) return _confirmarComPin();

    try {
      final biometriaDisponivel = await AppPlugins.localAuth.canCheckBiometrics;
      final dispositivoSuporta = await AppPlugins.localAuth.isDeviceSupported();

      if (!biometriaDisponivel && !dispositivoSuporta) {
        return _confirmarComPin();
      }

      final autenticado = await AppPlugins.localAuth.authenticate(
        localizedReason: 'Confirme sua identidade para enviar o PIX',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (autenticado) return true;
      return _confirmarComPin();
    } catch (_) {
      return _confirmarComPin();
    }
  }

  Future<bool> _confirmarComPin() async {
    final pinController = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar com PIN'),
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
    return _authRepository.validateAppPin(pin);
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _colarCodigoPix() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      _mostrarMensagem(
          'Nenhum código PIX encontrado na área de transferência.');
      return;
    }
    _applyPixPayload(text);
  }

  Future<void> _lerQrCode() async {
    final result = await Navigator.pushNamed(context, AppRoutes.pixQrScanner);
    if (result is String && result.trim().isNotEmpty) {
      _applyPixPayload(result);
    }
  }

  void _applyPixPayload(String payload) {
    final parsed = _parsePixPayload(payload);
    setState(() {
      _tipoChave = parsed.keyType;
      _chaveController.text = parsed.key;
      if (parsed.valorCentavos != null) {
        _valorController.text = BrFormatters.currencyFromCentavos(
          parsed.valorCentavos!,
        ).replaceAll('R\$ ', '');
      }
    });
    _mostrarMensagem('Dados PIX preenchidos.');
  }

  _ParsedPixPayload _parsePixPayload(String payload) {
    final text = payload.trim();
    final emvPayload = _parseEmvPixPayload(text);
    if (emvPayload != null) return emvPayload;

    final uri = Uri.tryParse(text);
    final key = uri?.queryParameters['pixKey'] ??
        uri?.queryParameters['chave'] ??
        uri?.queryParameters['key'];
    final amount = uri?.queryParameters['amount'] ??
        uri?.queryParameters['valor'] ??
        uri?.queryParameters['value'];

    if (key != null && key.isNotEmpty) {
      return _ParsedPixPayload(
        key: key,
        keyType: _detectKeyType(key),
        valorCentavos: amount == null
            ? null
            : BrFormatters.parseCurrencyToCentavos(amount),
      );
    }

    return _ParsedPixPayload(
      key: text,
      keyType: _detectKeyType(text),
    );
  }

  _ParsedPixPayload? _parseEmvPixPayload(String payload) {
    if (!payload.startsWith('000201')) return null;

    final root = _parseTlv(payload);
    final merchantAccount = root['26'];
    final key =
        merchantAccount == null ? null : _parseTlv(merchantAccount)['01'];
    final amount = root['54'];

    if (key == null || key.isEmpty) return null;

    return _ParsedPixPayload(
      key: key,
      keyType: _detectKeyType(key),
      valorCentavos:
          amount == null ? null : BrFormatters.parseCurrencyToCentavos(amount),
    );
  }

  Map<String, String> _parseTlv(String payload) {
    final result = <String, String>{};
    var index = 0;

    while (index + 4 <= payload.length) {
      final id = payload.substring(index, index + 2);
      final length = int.tryParse(payload.substring(index + 2, index + 4));
      if (length == null) break;

      final valueStart = index + 4;
      final valueEnd = valueStart + length;
      if (valueEnd > payload.length) break;

      result[id] = payload.substring(valueStart, valueEnd);
      index = valueEnd;
    }

    return result;
  }

  String _detectKeyType(String key) {
    if (PixKeyValidator.isValid(type: 'E-mail', value: key)) return 'E-mail';
    if (PixKeyValidator.isValid(type: 'CPF', value: key)) return 'CPF';
    if (PixKeyValidator.isValid(type: 'Telefone', value: key)) {
      return 'Telefone';
    }
    return 'Aleatória';
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(24),
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
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Dados da transferência',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
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
                  if (value != null) {
                    setState(() {
                      _tipoChave = value;
                      _recipient = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chaveController,
                onChanged: (_) => setState(() => _recipient = null),
                decoration: const InputDecoration(
                  labelText: 'Chave PIX',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return 'Informe a chave PIX';
                  if (!PixKeyValidator.isValid(
                    type: _tipoChave,
                    value: text,
                  )) {
                    return PixKeyValidator.messageFor(_tipoChave);
                  }
                  return null;
                },
              ),
              if (_recipient != null) ...[
                const SizedBox(height: 12),
                _RecipientPreview(recipient: _recipient!),
              ],
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
                onPressed: _lerQrCode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Ler QR Code'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _colarCodigoPix,
                icon: const Icon(Icons.content_paste_rounded),
                label: const Text('Colar código PIX'),
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

class _RecipientPreview extends StatelessWidget {
  const _RecipientPreview({required this.recipient});

  final PixRecipient recipient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  recipient.bank,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParsedPixPayload {
  const _ParsedPixPayload({
    required this.key,
    required this.keyType,
    this.valorCentavos,
  });

  final String key;
  final String keyType;
  final int? valorCentavos;
}
