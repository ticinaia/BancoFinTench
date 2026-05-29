import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixReceiptPage extends StatelessWidget {
  const PixReceiptPage({
    super.key,
    required this.receipt,
  });

  factory PixReceiptPage.fromRouteSettings(RouteSettings settings) {
    final args = settings.arguments;
    if (args is PixReceipt) {
      return PixReceiptPage(receipt: args);
    }
    if (args is Map<String, Object?>) {
      return PixReceiptPage(receipt: PixReceipt.fromMap(args));
    }
    return PixReceiptPage(
      receipt: PixReceipt(
        id: 'indisponivel',
        chave: 'Chave não informada',
        tipoChave: 'PIX',
        recipientName: 'Destinatário',
        recipientBank: 'Banco não informado',
        recipientDocument: 'Documento não informado',
        valorCentavos: 0,
        status: 'concluido',
        createdAt: DateTime.now(),
      ),
    );
  }

  final PixReceipt receipt;

  void _share() {
    Share.share(_shareText());
  }

  String _shareText() {
    return '''
Comprovante PIX

Valor: ${BrFormatters.currencyFromCentavos(receipt.valorCentavos)}
Destinatário: ${receipt.recipientName}
Banco: ${receipt.recipientBank}
Documento: ${receipt.recipientDocument}
Tipo de chave: ${receipt.tipoChave}
Chave: ${receipt.chave}
Status: ${_statusLabel(receipt.status)}
Data: ${BrFormatters.dateTime(receipt.createdAt)}
Código: ${receipt.id}
''';
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'concluido':
        return 'Concluído';
      case 'pendente':
        return 'Pendente';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprovante'),
        actions: [
          IconButton(
            onPressed: _share,
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Compartilhar',
          ),
        ],
      ),
      body: SafeArea(
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
                    Icons.check_circle_rounded,
                    color: AppColors.secondaryLight,
                    size: 36,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    BrFormatters.currencyFromCentavos(receipt.valorCentavos),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'PIX ${_statusLabel(receipt.status).toLowerCase()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ReceiptLine(label: 'Destinatário', value: receipt.recipientName),
            _ReceiptLine(label: 'Banco', value: receipt.recipientBank),
            _ReceiptLine(label: 'Documento', value: receipt.recipientDocument),
            _ReceiptLine(label: 'Tipo de chave', value: receipt.tipoChave),
            _ReceiptLine(label: 'Chave', value: receipt.chave),
            _ReceiptLine(
                label: 'Data', value: BrFormatters.dateTime(receipt.createdAt)),
            _ReceiptLine(label: 'Código', value: receipt.id),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Compartilhar comprovante'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
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
