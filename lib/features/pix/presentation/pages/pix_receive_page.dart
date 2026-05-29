import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../../../core/services/app_repositories.dart';
import '../../../../core/utils/br_formatters.dart';
import '../widgets/pix_transfer_widgets.dart';

class PixReceivePage extends StatefulWidget {
  const PixReceivePage({super.key});

  @override
  State<PixReceivePage> createState() => _PixReceivePageState();
}

class _PixReceivePageState extends State<PixReceivePage> {
  static final RegExp _nonDigitsRegex = RegExp(r'[^\d]');

  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _pixRepository = AppRepositories.pix;
  final _authRepository = AppRepositories.auth;

  bool _simulando = false;
  String _selectedPixKeyType = 'E-mail';
  String? _profileCpf;
  String? _profilePhone;

  @override
  void initState() {
    super.initState();
    _loadPixKeyOptions();
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String get _pixKey {
    final selectedType = _effectiveSelectedPixKeyType;
    final option = _pixKeyOptions().where(
      (option) => option.type == selectedType,
    );
    if (option.isNotEmpty) return option.first.value;

    return _fallbackRandomKey;
  }

  String get _effectiveSelectedPixKeyType {
    final options = _pixKeyOptions();
    if (options.any((option) => option.type == _selectedPixKeyType)) {
      return _selectedPixKeyType;
    }
    return options.first.type;
  }

  String get _fallbackRandomKey {
    final user = _authRepository.currentUser;
    return '${_accountCodeFromUid(user?.uid)}@bancofintech.com';
  }

  int get _valorCentavos {
    return int.tryParse(_onlyDigits(_valorController.text)) ?? 0;
  }

  String get _pixPayload {
    return _buildPixPayload(
      key: _pixKey,
      merchantName: _merchantName,
      amountCentavos: _valorCentavos,
    );
  }

  String get _merchantName {
    final user = _authRepository.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user?.email?.split('@').first ?? 'Cliente';
  }

  Future<void> _loadPixKeyOptions() async {
    try {
      final appUser = await _authRepository.currentAppUser();
      if (!mounted) return;

      setState(() {
        _profileCpf = _onlyDigits(appUser?.cpf ?? '');
        _profilePhone = _onlyDigits(appUser?.phone ?? '');
        final options = _pixKeyOptions();
        if (!options.any((option) => option.type == _selectedPixKeyType)) {
          _selectedPixKeyType = options.first.type;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final options = _pixKeyOptions();
        if (!options.any((option) => option.type == _selectedPixKeyType)) {
          _selectedPixKeyType = options.first.type;
        }
      });
    }
  }

  List<_PixKeyOption> _pixKeyOptions() {
    final user = _authRepository.currentUser;
    final email = user?.email?.trim();
    final cpf = _profileCpf?.trim();
    final phone = _profilePhone?.trim();

    return [
      if (email != null && email.isNotEmpty)
        _PixKeyOption(type: 'E-mail', label: 'E-mail cadastrado', value: email),
      if (cpf != null && cpf.isNotEmpty)
        _PixKeyOption(type: 'CPF', label: 'CPF cadastrado', value: cpf),
      if (phone != null && phone.isNotEmpty)
        _PixKeyOption(
            type: 'Telefone', label: 'Celular cadastrado', value: phone),
      _PixKeyOption(
        type: 'Aleatória',
        label: 'Chave aleatória do app',
        value: _fallbackRandomKey,
      ),
    ];
  }

  Future<void> _copyPixKey() async {
    await Clipboard.setData(ClipboardData(text: _pixKey));
    if (!mounted) return;
    _showMessage('Chave Pix copiada.');
  }

  Future<void> _simularRecebimento() async {
    if (!_formKey.currentState!.validate()) return;

    final valorCentavos = _valorCentavos;
    final confirmado = await _confirmarRecebimento();
    if (!mounted) return;
    if (confirmado != true) return;

    setState(() => _simulando = true);

    try {
      final receipt = await _pixRepository.receberPix(
        chave: _pixKey,
        tipoChave: _effectiveSelectedPixKeyType,
        valorCentavos: valorCentavos,
        payerName: 'Cliente pagador',
        payerBank: 'Banco de origem',
      );

      if (!mounted) return;
      _showMessage('Pix recebido e saldo atualizado.');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.pixReceipt,
        arguments: receipt,
      );
    } on StateError catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Não conseguimos simular o recebimento agora.');
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool?> _confirmarRecebimento() {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar entrada Pix',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PixResumoLinha(
                  label: 'Valor',
                  value: BrFormatters.currencyFromCentavos(_valorCentavos),
                ),
                const PixResumoLinha(
                  label: 'Pagador',
                  value: 'Cliente pagador de demonstração',
                ),
                const PixResumoLinha(
                  label: 'Banco',
                  value: 'Banco de origem de demonstração',
                ),
                PixResumoLinha(label: 'Chave', value: _pixKey),
                PixResumoLinha(
                  label: 'Data',
                  value: BrFormatters.dateTime(DateTime.now()),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirmar recebimento'),
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
  }

  void _preencherSimulacao() {
    const centavos = 8750;
    final formatted = BrFormatters.currencyInputFromCentavos(centavos);

    setState(() {
      _valorController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
    _showMessage('Preenchi um recebimento de demonstração.');
  }

  void _onValorChanged(String rawText) {
    final digits = _onlyDigits(rawText);
    if (digits.isEmpty) {
      _valorController.value = const TextEditingValue(text: '');
      setState(() {});
      return;
    }

    final centavos = int.tryParse(digits) ?? 0;
    final formatted = BrFormatters.currencyInputFromCentavos(centavos);
    _valorController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  String _onlyDigits(String value) {
    return value.replaceAll(_nonDigitsRegex, '');
  }

  String _accountCodeFromUid(String? uid) {
    final normalized = uid?.trim();
    if (normalized == null || normalized.isEmpty) return 'cliente';
    final length = normalized.length < 8 ? normalized.length : 8;
    return normalized.substring(0, length).toLowerCase();
  }

  String _buildPixPayload({
    required String key,
    required String merchantName,
    required int amountCentavos,
  }) {
    final amount =
        amountCentavos <= 0 ? null : (amountCentavos / 100).toStringAsFixed(2);
    final merchantAccount = _tlv('00', 'br.gov.bcb.pix') + _tlv('01', key);
    final payload = StringBuffer()
      ..write(_tlv('00', '01'))
      ..write(_tlv('26', merchantAccount))
      ..write(_tlv('52', '0000'))
      ..write(_tlv('53', '986'));

    if (amount != null) payload.write(_tlv('54', amount));

    payload
      ..write(_tlv('58', 'BR'))
      ..write(_tlv('59', _normalizeMerchantName(merchantName)))
      ..write(_tlv('60', 'SAO PAULO'))
      ..write(_tlv('62', _tlv('05', 'FinTech')));

    return '${payload}6304${_crc16('$payload' '6304')}';
  }

  String _tlv(String id, String value) {
    final normalized = value.length > 99 ? value.substring(0, 99) : value;
    return '$id${normalized.length.toString().padLeft(2, '0')}$normalized';
  }

  String _normalizeMerchantName(String value) {
    final normalized = value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return 'CLIENTE';
    return normalized.length > 25 ? normalized.substring(0, 25) : normalized;
  }

  String _crc16(String value) {
    var crc = 0xFFFF;
    for (final unit in value.codeUnits) {
      crc ^= unit << 8;
      for (var i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  @override
  Widget build(BuildContext context) {
    final valor = _valorCentavos;
    final pixKeyOptions = _pixKeyOptions();
    final selectedPixKeyType = _effectiveSelectedPixKeyType;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber Pix'),
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
                      Icons.qr_code_2_rounded,
                      color: AppColors.secondaryLight,
                      size: 36,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Receba por QR Code',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Informe um valor, compartilhe o código e registre a entrada no saldo.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: selectedPixKeyType,
                items: pixKeyOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.type,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Chave para receber',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedPixKeyType = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: _onValorChanged,
                decoration: const InputDecoration(
                  labelText: 'Valor a receber',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(Icons.payments_rounded),
                  hintText: '0,00',
                  helperText: 'Digite apenas os números',
                ),
                validator: (value) {
                  final centavos = int.tryParse(_onlyDigits(value ?? '')) ?? 0;
                  if (centavos <= 0) return 'Informe um valor válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: QrImageView(
                    data: _pixPayload,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ReceiveInfoLine(
                label: 'Tipo de chave',
                value: selectedPixKeyType,
              ),
              _ReceiveInfoLine(label: 'Chave', value: _pixKey),
              _ReceiveInfoLine(
                label: 'Valor',
                value: valor > 0
                    ? BrFormatters.currencyFromCentavos(valor)
                    : 'Defina um valor',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _copyPixKey,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar chave Pix'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _preencherSimulacao,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Preencher demonstração'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _simulando ? null : _simularRecebimento,
                icon: _simulando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.south_west_rounded),
                label: Text(
                  _simulando ? 'Recebendo...' : 'Simular recebimento',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiveInfoLine extends StatelessWidget {
  const _ReceiveInfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outline),
        ),
      ),
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

class _PixKeyOption {
  const _PixKeyOption({
    required this.type,
    required this.label,
    required this.value,
  });

  final String type;
  final String label;
  final String value;
}
