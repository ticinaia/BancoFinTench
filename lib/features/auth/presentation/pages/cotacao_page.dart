import 'package:flutter/material.dart';
import 'package:banco_fin_tech/app/theme/app_colors.dart';
import 'package:banco_fin_tech/core/services/app_repositories.dart';
import 'package:banco_fin_tech/features/auth/domain/models/cotacao.dart';

class CotacaoPage extends StatefulWidget {
  const CotacaoPage({super.key});

  @override
  State<CotacaoPage> createState() => _CotacaoPageState();
}

class _CotacaoPageState extends State<CotacaoPage> {
  final _repository = AppRepositories.cotacao;

  List<Cotacao> _cotacoes = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarCotacoes();
  }

  Future<void> _carregarCotacoes({bool showFeedback = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cotacoes = await _repository.getCotacoes(
        forceRefresh: showFeedback,
      );
      if (!mounted) return;

      setState(() {
        _cotacoes = cotacoes;
        _isLoading = false;
      });

      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta realizada.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });

      if (showFeedback && _cotacoes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotações de Moedas'),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed:
                _isLoading ? null : () => _carregarCotacoes(showFeedback: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurface.withValues(alpha: 0.72);
    final symbolColor = isDark ? AppColors.secondaryLight : AppColors.primary;
    final symbolBackground =
        symbolColor.withValues(alpha: isDark ? 0.18 : 0.10);
    const positiveLight = Color(0xFF007A5E);
    const positiveDark = Color(0xFF7DE7C7);
    const negativeLight = Color(0xFFC62828);
    const negativeDark = Color(0xFFFF8A94);

    if (_isLoading && _cotacoes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando cotações mais recentes...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _cotacoes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Ops! Algo deu errado.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregarCotacoes,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCotacoes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_cotacoes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Última atualização da API: ${_formatarHorario(_ultimaAtualizacaoApi())}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ),
          ..._cotacoes.map((cotacao) {
            final variationIsPositive = cotacao.variation >= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: symbolBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          _symbolFor(cotacao.code),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: symbolColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cotacao.name.split('/').first,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${cotacao.code}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Builder(
                          builder: (context) {
                            final variationColor = variationIsPositive
                                ? isDark
                                    ? positiveDark
                                    : positiveLight
                                : isDark
                                    ? negativeDark
                                    : negativeLight;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatarPreco(cotacao),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: variationColor.withValues(
                                      alpha: isDark ? 0.18 : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: variationColor.withValues(
                                        alpha: isDark ? 0.46 : 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        variationIsPositive
                                            ? Icons.trending_up_rounded
                                            : Icons.trending_down_rounded,
                                        size: 14,
                                        color: variationColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_formatarVariacao(cotacao.variation)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: variationColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatarHorario(cotacao.updatedAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: textSecondary,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatarHorario(DateTime dateTime) {
    final hora = dateTime.hour.toString().padLeft(2, '0');
    final minuto = dateTime.minute.toString().padLeft(2, '0');
    final segundo = dateTime.second.toString().padLeft(2, '0');

    return '$hora:$minuto:$segundo';
  }

  String _formatarPreco(Cotacao cotacao) {
    final casasDecimais = cotacao.code == 'BTC' ? 2 : 4;

    return 'R\$ ${cotacao.buyPrice.toStringAsFixed(casasDecimais)}';
  }

  String _formatarVariacao(double variation) {
    final sinal = variation >= 0 ? '+' : '';

    return '$sinal${variation.toStringAsFixed(2)}';
  }

  String _symbolFor(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'BTC':
        return '₿';
      default:
        return code.isEmpty ? '?' : code.substring(0, 1);
    }
  }

  DateTime _ultimaAtualizacaoApi() {
    return _cotacoes
        .map((cotacao) => cotacao.updatedAt)
        .reduce((atual, proxima) => atual.isAfter(proxima) ? atual : proxima);
  }
}
