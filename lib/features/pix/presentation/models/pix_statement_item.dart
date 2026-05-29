import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixStatementItem {
  const PixStatementItem({
    required this.id,
    required this.key,
    required this.keyType,
    required this.counterpartyName,
    required this.counterpartyBank,
    required this.counterpartyDocument,
    required this.amountCentavos,
    required this.direction,
    required this.transactionType,
    required this.status,
    required this.date,
  });

  factory PixStatementItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return PixStatementItem(
      id: doc.id,
      key: (data['chave'] ?? 'Chave não informada').toString(),
      keyType: (data['tipoChave'] ?? 'PIX').toString(),
      counterpartyName:
          (data['recipientName'] ?? 'Pessoa não informada').toString(),
      counterpartyBank:
          (data['recipientBank'] ?? 'Banco não informado').toString(),
      counterpartyDocument: (data['recipientDocument'] ?? '').toString(),
      amountCentavos: _centavosFrom(data),
      direction: (data['direction'] ?? 'sent').toString(),
      transactionType: (data['transactionType'] ?? 'pix').toString(),
      status: (data['status'] ?? 'concluido').toString(),
      date: _dateFrom(data['data'] ?? data['createdAt']),
    );
  }

  factory PixStatementItem.initialBalance() {
    return PixStatementItem(
      id: 'saldo-inicial',
      key: 'Conta BancoFinTech',
      keyType: 'Saldo',
      counterpartyName: 'Saldo inicial',
      counterpartyBank: 'BancoFinTech',
      counterpartyDocument: '',
      amountCentavos: PixRepository.initialBalanceCentavos,
      direction: 'received',
      transactionType: 'initial',
      status: 'concluido',
      date: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String key;
  final String keyType;
  final String counterpartyName;
  final String counterpartyBank;
  final String counterpartyDocument;
  final int amountCentavos;
  final String direction;
  final String transactionType;
  final String status;
  final DateTime date;

  bool get canOpenReceipt => transactionType == 'pix';
  bool get canShare => transactionType == 'pix';
  bool get isMoneyIn => direction == 'received' || transactionType == 'initial';

  String get title {
    if (transactionType == 'initial') return 'Saldo inicial da conta';
    if (transactionType == 'deposit') return 'Depósito';
    if (transactionType == 'payment') return 'Pagamento';
    return direction == 'received'
        ? 'PIX recebido de $counterpartyName'
        : 'PIX enviado para $counterpartyName';
  }

  String get typeLabel {
    if (transactionType == 'initial') return 'Saldo inicial';
    if (transactionType == 'deposit') return 'Depósito';
    if (transactionType == 'payment') return 'Pagamento';
    return direction == 'received' ? 'PIX recebido' : 'PIX enviado';
  }

  String get formattedAmount {
    return BrFormatters.currencyFromCentavos(amountCentavos);
  }

  String get signedAmount {
    final signal = isMoneyIn ? '+' : '-';
    return '$signal $formattedAmount';
  }

  String get formattedDate {
    if (transactionType == 'initial') return 'Abertura da conta';
    return BrFormatters.dateTime(date);
  }

  String get statusLabel {
    switch (status) {
      case 'concluido':
        return 'Concluído';
      case 'pendente':
        return 'Pendente';
      case 'falhou':
        return 'Falhou';
      case 'cancelado':
        return 'Cancelado/estornado';
      default:
        return status;
    }
  }

  IconData get icon {
    if (transactionType == 'initial') return Icons.account_balance_wallet;
    if (transactionType == 'deposit') return Icons.savings_rounded;
    if (transactionType == 'payment') return Icons.receipt_rounded;
    if (status == 'cancelado') return Icons.undo_rounded;
    return isMoneyIn ? Icons.south_west_rounded : Icons.north_east_rounded;
  }

  Color get color {
    if (status == 'cancelado') return AppColors.textSecondary;
    return isMoneyIn ? AppColors.success : AppColors.error;
  }

  Color get amountColor {
    if (status == 'cancelado') return AppColors.textSecondary;
    return isMoneyIn ? AppColors.success : AppColors.error;
  }

  PixReceipt toReceipt() {
    return PixReceipt(
      id: id,
      chave: key,
      tipoChave: keyType,
      recipientName: counterpartyName,
      recipientBank: counterpartyBank,
      recipientDocument: counterpartyDocument,
      valorCentavos: amountCentavos,
      direction: direction,
      transactionType: transactionType,
      status: status,
      createdAt: date,
    );
  }

  static int _centavosFrom(Map<String, dynamic> data) {
    final centavos = data['valorCentavos'];
    if (centavos is int) return centavos;
    if (centavos is num) return centavos.round();

    final valorAntigo = data['valor'];
    if (valorAntigo is num) return (valorAntigo * 100).round();
    return 0;
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
