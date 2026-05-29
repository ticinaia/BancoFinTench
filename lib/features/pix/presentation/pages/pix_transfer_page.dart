import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../../../core/services/app_repositories.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';
import '../../domain/validators/pix_key_validator.dart';
import '../utils/pix_payload_parser.dart';
import '../widgets/pix_transfer_widgets.dart';

class PixTransferPage extends StatefulWidget {
  const PixTransferPage({super.key});

  @override
  State<PixTransferPage> createState() => _PixTransferPageState();
}

class _PixTransferPageState extends State<PixTransferPage> {
  static final RegExp _nonDigitsRegex = RegExp(r'[^\d]');

  final _formKey = GlobalKey<FormState>();
  final _chaveController = TextEditingController();
  final _valorController = TextEditingController();
  final _pixRepository = AppRepositories.pix;
  final _authRepository = AppRepositories.auth;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _favoritesStream;

  String _tipoChave = 'E-mail';
  bool _enviando = false;
  PixRecipient? _recipient;

  @override
  void initState() {
    super.initState();
    _favoritesStream = _pixRepository.watchFavoriteRecipients();
  }

  // Formata o campo de valor como moeda brasileira em tempo real
  void _onValorChanged(String rawText) {
    final digits = _onlyDigits(rawText);
    if (digits.isEmpty) {
      _valorController.value = const TextEditingValue(text: '');
      return;
    }
    final centavos = int.tryParse(digits) ?? 0;
    final formatted = BrFormatters.currencyFromCentavos(centavos)
        .replaceAll('R\$\u00a0', '')
        .trim();
    _valorController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void dispose() {
    _chaveController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPix() async {
    if (!_formKey.currentState!.validate()) return;

    final digits = _onlyDigits(_valorController.text);
    final valorCentavos = int.tryParse(digits) ?? 0;

    try {
      final saldo = await _pixRepository.getBalanceCentavos();
      if (valorCentavos > saldo) {
        _mostrarMensagem('Seu saldo não cobre esse PIX. Confira o valor.');
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
                  PixResumoLinha(
                    label: 'Valor',
                    value: BrFormatters.currencyFromCentavos(valorCentavos),
                  ),
                  PixResumoLinha(label: 'Destinatário', value: recipient.name),
                  PixResumoLinha(label: 'Banco', value: recipient.bank),
                  PixResumoLinha(label: 'Tipo de chave', value: _tipoChave),
                  PixResumoLinha(
                      label: 'Chave', value: _chaveController.text.trim()),
                  PixResumoLinha(
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
      _mostrarMensagem('Não conseguimos conferir os dados do PIX agora.');
    }
  }

  Future<void> _enviarPix(int valorCentavos, PixRecipient recipient) async {
    setState(() => _enviando = true);

    try {
      final autenticado = await _autenticarAcaoSensivel();
      if (!autenticado) {
        _mostrarMensagem('Autenticação cancelada. Nenhum valor foi enviado.');
        return;
      }

      final receipt = await _pixRepository.enviarPix(
        chave: _chaveController.text.trim(),
        tipoChave: _tipoChave,
        valorCentavos: valorCentavos,
        recipient: recipient,
      );

      if (!mounted) return;
      _mostrarMensagem('PIX enviado com sucesso. Comprovante gerado.');
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
      _mostrarMensagem('Não foi possível enviar o PIX. Tente novamente.');
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
      _mostrarMensagem('Não encontrei um código PIX na área de transferência.');
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
    final parsed = PixPayloadParser.parse(payload);
    setState(() {
      _tipoChave = parsed.keyType;
      _chaveController.text = parsed.key;
      if (parsed.valorCentavos != null && parsed.valorCentavos! > 0) {
        final centavos = parsed.valorCentavos!;
        final formatted = BrFormatters.currencyFromCentavos(centavos)
            .replaceAll('R\$ ', '')
            .replaceAll('R\$ ', '')
            .trim();
        _valorController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
    _mostrarMensagem('Dados PIX preenchidos.');
  }

  void _applyFavoriteRecipient(PixFavoriteRecipient favorite) {
    final recipient = favorite.toRecipient();
    setState(() {
      _tipoChave = recipient.keyType;
      _chaveController.text = recipient.key;
      _recipient = recipient;
    });
    _mostrarMensagem('Contato frequente preenchido.');
  }

  Future<void> _saveRecipientAsFavorite(PixRecipient recipient) async {
    final nameController = TextEditingController(
      text: recipient.isVerified ? recipient.name : '',
    );
    final bankController = TextEditingController(
      text: recipient.isVerified ? recipient.bank : '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showModalBottomSheet<PixRecipient>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Salvar contato PIX',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nome do destinatário',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe o nome do contato';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Banco',
                      prefixIcon: Icon(Icons.account_balance_outlined),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe o banco';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        PixRecipient(
                          name: nameController.text.trim(),
                          bank: bankController.text.trim(),
                          key: recipient.key,
                          keyType: recipient.keyType,
                          document: recipient.document == 'Não verificado'
                              ? 'Salvo pelo usuário'
                              : recipient.document,
                          isFavorite: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Salvar favorito'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    nameController.dispose();
    bankController.dispose();

    if (saved == null) return;

    try {
      await _pixRepository.saveFavoriteRecipient(saved);
      if (!mounted) return;
      setState(() => _recipient = saved);
      _mostrarMensagem('Contato PIX salvo.');
    } catch (_) {
      if (!mounted) return;
      _mostrarMensagem('Não foi possível salvar o contato.');
    }
  }

  String _onlyDigits(String value) {
    return value.replaceAll(_nonDigitsRegex, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transferência PIX'),
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
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
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _favoritesStream,
                builder: (context, snapshot) {
                  final favorites = snapshot.data?.docs
                          .map(PixFavoriteRecipient.fromDoc)
                          .where((favorite) => favorite.key.isNotEmpty)
                          .toList() ??
                      const <PixFavoriteRecipient>[];

                  if (favorites.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: FavoriteRecipientsStrip(
                      favorites: favorites,
                      onSelected: _applyFavoriteRecipient,
                    ),
                  );
                },
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(_tipoChave),
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
                RecipientPreview(
                  recipient: _recipient!,
                  onSave: _recipient!.isFavorite
                      ? null
                      : () => _saveRecipientAsFavorite(_recipient!),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: _onValorChanged,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                  helperText: 'Digite apenas os números',
                  helperStyle: Theme.of(context).textTheme.labelSmall,
                ),
                validator: (value) {
                  final digits = _onlyDigits(value ?? '');
                  final centavos = int.tryParse(digits) ?? 0;
                  if (centavos <= 0) return 'Informe um valor válido';
                  if (centavos < 1) return 'Valor mínimo: R\$ 0,01';
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
