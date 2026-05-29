import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../../../core/services/app_repositories.dart';
import '../../../../core/utils/br_formatters.dart';
import '../models/pix_statement_item.dart';
import '../widgets/pix_history_widgets.dart';

class PixHistoryPage extends StatefulWidget {
  const PixHistoryPage({super.key});

  @override
  State<PixHistoryPage> createState() => _PixHistoryPageState();
}

class _PixHistoryPageState extends State<PixHistoryPage> {
  static const int _historyPageSize = 50;

  final _pixRepository = AppRepositories.pix;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _historyStream;
  int _historyLimit = _historyPageSize;
  bool _loadingMoreHistory = false;
  String _typeFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  int? _minCentavos;
  int? _maxCentavos;

  @override
  void initState() {
    super.initState();
    _historyStream = _pixRepository.watchPixHistory(limit: _historyLimit);
  }

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

  void _compartilharComprovante(PixStatementItem item) {
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

  bool _handleScroll(ScrollNotification notification, {required bool hasMore}) {
    if (!hasMore) return false;
    if (_loadingMoreHistory) return false;
    if (notification.metrics.extentAfter > 320) return false;

    _scheduleLoadMoreHistory();
    return false;
  }

  void _scheduleLoadMoreHistory() {
    if (_loadingMoreHistory) return;
    _loadingMoreHistory = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _loadingMoreHistory = false;
        return;
      }

      setState(() {
        _historyLimit += _historyPageSize;
        _historyStream = _pixRepository.watchPixHistory(limit: _historyLimit);
        _loadingMoreHistory = false;
      });
    });
  }

  List<PixStatementItem> _itemsFromDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = docs.map(PixStatementItem.fromDoc).toList();

    if (!_hasFilters || _typeFilter == 'initial') {
      items.add(PixStatementItem.initialBalance());
    }

    return items.where(_matchesFilters).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  bool _matchesFilters(PixStatementItem item) {
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
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const CenteredState(
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
          final loadedDocs = snapshot.data?.docs.length ?? 0;
          final hasMore = loadedDocs >= _historyLimit;

          if (_hasFilters && hasMore) {
            _scheduleLoadMoreHistory();
          }

          if (_hasFilters && items.isEmpty && hasMore) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (items.isEmpty) {
            return CenteredState(
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

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              return _handleScroll(notification, hasMore: hasMore);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              itemCount: items.length + (_hasFilters ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (_hasFilters && index == 0) {
                  return ActiveFiltersBanner(onClear: _clearFilters);
                }

                final item = items[_hasFilters ? index - 1 : index];

                return PixStatementTile(
                  item: item,
                  onOpenReceipt: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.pixReceipt,
                      arguments: item.toReceipt(),
                    );
                  },
                  onCancel: () => _cancelarPixPendente(
                    context: context,
                    id: item.id,
                  ),
                  onShare: () => _compartilharComprovante(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
