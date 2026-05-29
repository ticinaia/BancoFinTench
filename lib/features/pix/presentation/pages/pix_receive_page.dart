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

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String get _pixKey {
    final user = _authRepository.currentUser;
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return '${user?.uid.substring(0, 8) ?? 'cliente'}@bancofintech.com';
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

  Future<void> _copyPayload() async {
    await Clipboard.setData(ClipboardData(text: _pixPayload));
    if (!mounted) return;
    _showMessage('Código PIX copiado.');
  }

  Future<void> _simularRecebimento() async {
    if (!_formKey.currentState!.validate()) return;

    final valorCentavos = _valorCentavos;
    final confirmado = await _confirmarRecebimento();
    if (confirmado != true) return;

    setState(() => _simulando = true);

    try {
      final receipt = await _pixRepository.receberPix(
        chave: _pixKey,
        tipoChave: 'E-mail',
        valorCentavos: valorCentavos,
        payerName: 'Cliente pagador',
        payerBank: 'Banco de origem',
      );

      if (!mounted) return;
      _showMessage('PIX recebido e saldo atualizado.');
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
      _showMessage('Não foi possível simular o recebimento.');
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
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Confirmar entrada PIX',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PixResumoLinha(
                  label: 'Valor',
                  value: BrFormatters.currencyFromCentavos(_valorCentavos),
                ),
                const PixResumoLinha(
                  label: 'Pagador',
                  value: 'Cliente pagador simulado',
                ),
                const PixResumoLinha(
                  label: 'Banco',
                  value: 'Banco de origem simulado',
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
    final formatted = BrFormatters.currencyFromCentavos(centavos)
        .replaceAll('R\$\u00a0', '')
        .replaceAll('R\$ ', '')
        .trim();

    setState(() {
      _valorController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    });
    _showMessage('Recebimento simulado preenchido.');
  }

  void _onValorChanged(String rawText) {
    final digits = _onlyDigits(rawText);
    if (digits.isEmpty) {
      _valorController.value = const TextEditingValue(text: '');
      setState(() {});
      return;
    }

    final centavos = int.tryParse(digits) ?? 0;
    final formatted = BrFormatters.currencyFromCentavos(centavos)
        .replaceAll('R\$\u00a0', '')
        .replaceAll('R\$ ', '')
        .trim();
    _valorController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  String _onlyDigits(String value) {
    return value.replaceAll(_nonDigitsRegex, '');
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber PIX'),
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
                      'Informe um valor, compartilhe o código e simule a entrada no saldo.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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
              _ReceiveInfoLine(label: 'Chave', value: _pixKey),
              _ReceiveInfoLine(
                label: 'Valor',
                value: valor > 0
                    ? BrFormatters.currencyFromCentavos(valor)
                    : 'Defina um valor',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _copyPayload,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copiar código PIX'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _preencherSimulacao,
                icon: const Icon(Icons.auto_fix_high_rounded),
                label: const Text('Preencher simulação'),
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
