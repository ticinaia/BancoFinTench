import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixHistoryPage extends StatelessWidget {
  const PixHistoryPage({super.key});

  void _compartilharComprovante({
    required String chave,
    required String valor,
    required String data,
    required String codigo,
  }) {
    Share.share(
      'Comprovante PIX\n\nValor: $valor\nChave: $chave\nData: $data\nCódigo: $codigo',
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

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: ListTile(
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
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Compartilhar comprovante',
                    onPressed: () {
                      _compartilharComprovante(
                        chave: chave,
                        valor: valor,
                        data: dataFormatada,
                        codigo: doc.id,
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
    final centavos = data['valorCentavos'];
    if (centavos is int) return BrFormatters.currencyFromCentavos(centavos);
    if (centavos is num) {
      return BrFormatters.currencyFromCentavos(centavos.round());
    }

    final valorAntigo = data['valor'];
    if (valorAntigo != null) return 'R\$ $valorAntigo';
    return 'R\$ 0,00';
  }

  static String _formatDate(Object? value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;

    if (date == null) return 'Data pendente';
    return BrFormatters.dateTime(date);
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'concluido':
        return 'Concluído';
      case 'pendente':
        return 'Pendente';
      case 'falhou':
        return 'Falhou';
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
