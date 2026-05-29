import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixHistoryPage extends StatelessWidget {
  const PixHistoryPage({super.key});

  Future<void> _cancelarPixPendente({
    required BuildContext context,
    required PixRepository pixRepository,
    required String id,
  }) async {
    try {
      await pixRepository.cancelPendingPix(id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIX pendente cancelado.')),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível cancelar o PIX.')),
      );
    }
  }

  void _compartilharComprovante({
    required String chave,
    required String valor,
    required String data,
    required String codigo,
    required String destinatario,
    required String banco,
    required String status,
  }) {
    Share.share(
      'Comprovante PIX\n\nValor: $valor\nDestinatário: $destinatario\nBanco: $banco\nChave: $chave\nData: $data\nStatus: $status\nCódigo: $codigo',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pixRepository = PixRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico PIX'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pixRepository.watchPixHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CenteredState(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar histórico',
              subtitle: 'Confira sua conexão e tente novamente.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const _CenteredState(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhuma transferência encontrada',
              subtitle: 'Seus PIX enviados aparecerão aqui.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final chave = (data['chave'] ?? 'Chave não informada').toString();
              final valor = _formatValor(data);
              final dataFormatada =
                  _formatDate(data['data'] ?? data['createdAt']);
              final status = (data['status'] ?? 'concluido').toString();
              final destinatario =
                  (data['recipientName'] ?? 'Destinatário não informado')
                      .toString();
              final banco =
                  (data['recipientBank'] ?? 'Banco não informado').toString();

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.pixReceipt,
                      arguments: PixReceipt(
                        id: doc.id,
                        chave: chave,
                        tipoChave: (data['tipoChave'] ?? 'PIX').toString(),
                        recipientName: destinatario,
                        recipientBank: banco,
                        recipientDocument:
                            (data['recipientDocument'] ?? '').toString(),
                        valorCentavos: _centavosFrom(data),
                        status: status,
                        createdAt: _dateFrom(data['data'] ?? data['createdAt']),
                      ),
                    );
                  },
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.pix_rounded,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  title: Text(
                    valor,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(chave),
                        const SizedBox(height: 4),
                        Text(
                          '$dataFormatada • ${_statusLabel(status)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      status == 'pendente'
                          ? Icons.cancel_outlined
                          : Icons.ios_share_rounded,
                    ),
                    tooltip: status == 'pendente'
                        ? 'Cancelar PIX'
                        : 'Compartilhar comprovante',
                    onPressed: () {
                      if (status == 'pendente') {
                        _cancelarPixPendente(
                          context: context,
                          pixRepository: pixRepository,
                          id: doc.id,
                        );
                        return;
                      }
                      _compartilharComprovante(
                        chave: chave,
                        valor: valor,
                        data: dataFormatada,
                        codigo: doc.id,
                        destinatario: destinatario,
                        banco: banco,
                        status: _statusLabel(status),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatValor(Map<String, dynamic> data) {
    return BrFormatters.currencyFromCentavos(_centavosFrom(data));
  }

  static int _centavosFrom(Map<String, dynamic> data) {
    final centavos = data['valorCentavos'];
    if (centavos is int) return centavos;
    if (centavos is num) return centavos.round();

    final valorAntigo = data['valor'];
    if (valorAntigo is num) return (valorAntigo * 100).round();
    return 0;
  }

  static String _formatDate(Object? value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;

    if (date == null) return 'Data pendente';
    return BrFormatters.dateTime(date);
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'concluido':
        return 'Concluído';
      case 'pendente':
        return 'Pendente';
      case 'falhou':
        return 'Falhou';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
