import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../data/repositories/pix_repository.dart';

class PixHistoryPage extends StatefulWidget {
  const PixHistoryPage({super.key});

  @override
  State<PixHistoryPage> createState() => _PixHistoryPageState();
}

class _PixHistoryPageState extends State<PixHistoryPage> {
  final _pixRepository = PixRepository();
  String _typeFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minCentavos;
  int? _maxCentavos;

  bool get _hasFilters {
    return _typeFilter != 'all' ||
        _startDate != null ||
        _endDate != null ||
        _minCentavos != null ||
        _maxCentavos != null;
  }

  Future<void> _cancelarPixPendente({
    required BuildContext context,
    required String id,
  }) async {
    try {
      await _pixRepository.cancelPendingPix(id);
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

  void _compartilharComprovante(_StatementItem item) {
    Share.share(
      'Comprovante BancoFinTech\n\nValor: ${item.formattedAmount}\nTipo: ${item.typeLabel}\nPessoa: ${item.counterpartyName}\nBanco: ${item.counterpartyBank}\nChave: ${item.key}\nData: ${item.formattedDate}\nStatus: ${item.statusLabel}\nCódigo: ${item.id}',
    );
  }

  Future<void> _showFilters() async {
    final minController = TextEditingController(
      text: _minCentavos == null
          ? ''
          : BrFormatters.currencyFromCentavos(_minCentavos!)
              .replaceAll('R\$ ', ''),
    );
    final maxController = TextEditingController(
      text: _maxCentavos == null
          ? ''
          : BrFormatters.currencyFromCentavos(_maxCentavos!)
              .replaceAll('R\$ ', ''),
    );
    var selectedType = _typeFilter;
    var selectedStart = _startDate;
    var selectedEnd = _endDate;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate({required bool start}) async {
              final initial = start
                  ? selectedStart ?? DateTime.now()
                  : selectedEnd ?? DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked == null) return;
              setModalState(() {
                if (start) {
                  selectedStart = picked;
                } else {
                  selectedEnd = picked;
                }
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filtrar extrato',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Tipo',
                          prefixIcon: Icon(Icons.tune_rounded),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Todos'),
                          ),
                          DropdownMenuItem(
                            value: 'sent',
                            child: Text('Pix enviados'),
                          ),
                          DropdownMenuItem(
                            value: 'received',
                            child: Text('Pix recebidos'),
                          ),
                          DropdownMenuItem(
                            value: 'initial',
                            child: Text('Saldo inicial'),
                          ),
                          DropdownMenuItem(
                            value: 'deposit',
                            child: Text('Depósitos'),
                          ),
                          DropdownMenuItem(
                            value: 'payment',
                            child: Text('Pagamentos'),
                          ),
                          DropdownMenuItem(
                            value: 'cancelado',
                            child: Text('Estornos/cancelados'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedType = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate(start: true),
                              icon: const Icon(Icons.event_rounded),
                              label: Text(
                                selectedStart == null
                                    ? 'Data inicial'
                                    : BrFormatters.date(selectedStart!),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => pickDate(start: false),
                              icon: const Icon(Icons.event_available_rounded),
                              label: Text(
                                selectedEnd == null
                                    ? 'Data final'
                                    : BrFormatters.date(selectedEnd!),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Valor mínimo',
                                prefixText: 'R\$ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: const InputDecoration(
                                labelText: 'Valor máximo',
                                prefixText: 'R\$ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, true),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aplicar filtros'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            selectedType = 'all';
                            selectedStart = null;
                            selectedEnd = null;
                            minController.clear();
                            maxController.clear();
                          });
                        },
                        child: const Text('Limpar campos'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (applied != true || !mounted) {
      minController.dispose();
      maxController.dispose();
      return;
    }

    setState(() {
      _typeFilter = selectedType;
      _startDate = selectedStart;
      _endDate = selectedEnd;
      _minCentavos = minController.text.trim().isEmpty
          ? null
          : BrFormatters.parseCurrencyToCentavos(minController.text);
      _maxCentavos = maxController.text.trim().isEmpty
          ? null
          : BrFormatters.parseCurrencyToCentavos(maxController.text);
    });

    minController.dispose();
    maxController.dispose();
  }

  void _clearFilters() {
    setState(() {
      _typeFilter = 'all';
      _startDate = null;
      _endDate = null;
      _minCentavos = null;
      _maxCentavos = null;
    });
  }

  List<_StatementItem> _itemsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = docs.map(_StatementItem.fromDoc).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (!_hasFilters || _typeFilter == 'initial') {
      items.add(_StatementItem.initialBalance());
    }

    return items.where(_matchesFilters).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _matchesFilters(_StatementItem item) {
    if (_typeFilter == 'sent' && item.direction != 'sent') return false;
    if (_typeFilter == 'received' && item.direction != 'received') {
      return false;
    }
    if (_typeFilter == 'initial' && item.transactionType != 'initial') {
      return false;
    }
    if (_typeFilter == 'deposit' && item.transactionType != 'deposit') {
      return false;
    }
    if (_typeFilter == 'payment' && item.transactionType != 'payment') {
      return false;
    }
    if (_typeFilter == 'cancelado' && item.status != 'cancelado') {
      return false;
    }
    if (_startDate != null && item.date.isBefore(_startDate!)) return false;
    if (_endDate != null) {
      final endOfDay = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        23,
        59,
        59,
      );
      if (item.date.isAfter(endOfDay)) return false;
    }
    if (_minCentavos != null && item.amountCentavos < _minCentavos!) {
      return false;
    }
    if (_maxCentavos != null && item.amountCentavos > _maxCentavos!) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Extrato'),
        actions: [
          IconButton(
            onPressed: _showFilters,
            icon: Icon(
              _hasFilters
                  ? Icons.filter_alt_rounded
                  : Icons.filter_alt_outlined,
            ),
            tooltip: 'Filtrar',
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 2),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pixRepository.watchPixHistory(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _CenteredState(
              icon: Icons.error_outline_rounded,
              title: 'Erro ao carregar extrato',
              subtitle: 'Confira sua conexão e tente novamente.',
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = _itemsFromDocs(snapshot.data?.docs ?? []);

          if (items.isEmpty) {
            return _CenteredState(
              icon: Icons.receipt_long_outlined,
              title: 'Nenhum lançamento encontrado',
              subtitle: _hasFilters
                  ? 'Ajuste os filtros para ver outros movimentos.'
                  : 'Suas movimentações aparecerão aqui.',
              action: _hasFilters
                  ? TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Limpar filtros'),
                    )
                  : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: items.length + (_hasFilters ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (_hasFilters && index == 0) {
                return _ActiveFiltersBanner(onClear: _clearFilters);
              }

              final item = items[_hasFilters ? index - 1 : index];

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.outline),
                ),
                child: ListTile(
                  onTap: item.canOpenReceipt
                      ? () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.pixReceipt,
                            arguments: item.toReceipt(),
                          );
                        }
                      : null,
                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  leading: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  title: Text(
                    item.signedAmount,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: item.amountColor,
                        ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title),
                        const SizedBox(height: 4),
                        Text(
                          '${item.formattedDate} • ${item.statusLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  trailing: item.status == 'pendente'
                      ? IconButton(
                          icon: const Icon(Icons.cancel_outlined),
                          tooltip: 'Cancelar PIX',
                          onPressed: () => _cancelarPixPendente(
                            context: context,
                            id: item.id,
                          ),
                        )
                      : item.canShare
                          ? IconButton(
                              icon: const Icon(Icons.ios_share_rounded),
                              tooltip: 'Compartilhar comprovante',
                              onPressed: () => _compartilharComprovante(item),
                            )
                          : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatementItem {
  const _StatementItem({
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

  factory _StatementItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _StatementItem(
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

  factory _StatementItem.initialBalance() {
    return _StatementItem(
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

class _ActiveFiltersBanner extends StatelessWidget {
  const _ActiveFiltersBanner({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, color: AppColors.info),
          const SizedBox(width: 10),
          const Expanded(child: Text('Filtros aplicados')),
          TextButton(
            onPressed: onClear,
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

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
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
