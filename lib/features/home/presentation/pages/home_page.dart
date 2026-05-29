import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/widgets/app_bottom_navigation_bar.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../pix/data/repositories/pix_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepository = AuthRepository();
  final _pixRepository = PixRepository();
  bool _autenticacaoLocalDisponivel = false;
  bool _biometriaDisponivel = false;
  bool _saldoVisivel = false;
  Uint8List? _imagemPerfilBytes;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    if (kIsWeb) {
      setState(() {
        _autenticacaoLocalDisponivel = false;
        _biometriaDisponivel = false;
      });
      return;
    }

    try {
      final disponivel = await AppPlugins.localAuth.canCheckBiometrics;
      final suportado = await AppPlugins.localAuth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _biometriaDisponivel = disponivel;
          _autenticacaoLocalDisponivel = disponivel || suportado;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _autenticacaoLocalDisponivel = false;
          _biometriaDisponivel = false;
        });
      }
    }
  }

  Future<void> _mostrarSaldoComBiometria() async {
    if (_saldoVisivel) {
      setState(() => _saldoVisivel = false);
      return;
    }

    final autenticado = await _autenticarComBiometria(
      'Confirme sua identidade para visualizar o saldo',
    );

    if (autenticado && mounted) {
      setState(() => _saldoVisivel = true);
    }
  }

  Future<bool> _autenticarComBiometria(String motivo) async {
    if (kIsWeb) return true;
    if (!_autenticacaoLocalDisponivel) return true;

    try {
      return await AppPlugins.localAuth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      if (mounted) {
        _mostrarMensagem('Erro ao autenticar.');
      }
      return false;
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final imagem = await AppPlugins.imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagemPerfilBytes = bytes;
      });

      await _authRepository.updateProfileImage(base64Encode(bytes));

      if (!mounted) return;
      _mostrarMensagem('Imagem de perfil atualizada.');
    } catch (_) {
      if (mounted) {
        _mostrarMensagem('Erro ao selecionar imagem.');
      }
    }
  }

  void _abrirSeletorImagem() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Escolher imagem de perfil',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarImagem(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.pop(context);
                    _selecionarImagem(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    await _authRepository.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (_) => false,
    );
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _copiarDadosConta() async {
    final user = _authRepository.currentUser;
    final text = '''
BancoFinTech
Titular: ${user?.displayName ?? user?.email ?? 'Cliente'}
Agência: 0001
Conta: ${user?.uid.substring(0, 8).toUpperCase() ?? '00000000'}
''';
    await Clipboard.setData(ClipboardData(text: text.trim()));
    _mostrarMensagem('Dados da conta copiados.');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user?.email?.split('@').first ?? 'cliente';
    final displayName = '${name[0].toUpperCase()}${name.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BancoFinTech'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.security),
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Segurança',
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 0),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _pixRepository.watchAccount(),
          builder: (context, accountSnapshot) {
            final accountData = accountSnapshot.data?.data();
            final saldoCentavos = _intFrom(
              accountData?['balanceCentavos'],
              fallback: PixRepository.initialBalanceCentavos,
            );
            final profileImageBytes = _imagemPerfilBytes ??
                _decodeProfileImage(accountData?['profileImageBase64']);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _abrirSeletorImagem,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        backgroundImage: profileImageBytes != null
                            ? MemoryImage(profileImageBytes)
                            : null,
                        child: profileImageBytes == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 32,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, $displayName',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            'Toque na foto para personalizar',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BalanceCard(
                  saldoVisivel: _saldoVisivel,
                  saldoCentavos: saldoCentavos,
                  biometriaDisponivel: _biometriaDisponivel,
                  autenticacaoLocalDisponivel: _autenticacaoLocalDisponivel,
                  onToggleSaldo: _mostrarSaldoComBiometria,
                ),
                const SizedBox(height: 24),
                FutureBuilder<PixSummary>(
                  future: _pixRepository.getMonthlySummary(),
                  builder: (context, snapshot) {
                    final summary = snapshot.data ??
                        const PixSummary(
                          entradasCentavos: 0,
                          saidasCentavos: 0,
                        );

                    return Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'Entradas',
                            value: BrFormatters.currencyFromCentavos(
                              summary.entradasCentavos,
                            ),
                            color: AppColors.success,
                            icon: Icons.south_west_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Saídas',
                            value: BrFormatters.currencyFromCentavos(
                              summary.saidasCentavos,
                            ),
                            color: AppColors.error,
                            icon: Icons.north_east_rounded,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Ações rápidas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                  children: [
                    _ActionTile(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Cotação',
                      color: AppColors.accent,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.cotacao,
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.pix_rounded,
                      label: 'Transferência',
                      color: AppColors.secondary,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixTransfer,
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Receber PIX',
                      color: AppColors.success,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixReceive,
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Histórico',
                      color: AppColors.info,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixHistory,
                      ),
                    ),
                    _ActionTile(
                      icon: Icons.copy_rounded,
                      label: 'Dados da conta',
                      color: AppColors.primaryLight,
                      onTap: _copiarDadosConta,
                    ),
                    _ActionTile(
                      icon: Icons.shield_outlined,
                      label: 'Segurança',
                      color: AppColors.warning,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.security,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Últimas transferências',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _RecentPixList(repository: _pixRepository),
              ],
            );
          },
        ),
      ),
    );
  }

  int _intFrom(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  Uint8List? _decodeProfileImage(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.saldoVisivel,
    required this.saldoCentavos,
    required this.biometriaDisponivel,
    required this.autenticacaoLocalDisponivel,
    required this.onToggleSaldo,
  });

  final bool saldoVisivel;
  final int saldoCentavos;
  final bool biometriaDisponivel;
  final bool autenticacaoLocalDisponivel;
  final VoidCallback onToggleSaldo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saldo disponível',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onToggleSaldo,
                icon: Icon(
                  saldoVisivel
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white,
                ),
                tooltip: saldoVisivel ? 'Ocultar saldo' : 'Mostrar saldo',
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onToggleSaldo,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                saldoVisivel
                    ? BrFormatters.currencyFromCentavos(saldoCentavos)
                    : 'R\$ • • • • •',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            saldoVisivel ? 'Conta corrente' : 'Toque no saldo para visualizar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.66),
                ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                biometriaDisponivel
                    ? Icons.fingerprint_rounded
                    : Icons.lock_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  biometriaDisponivel
                      ? 'Protegido por biometria'
                      : autenticacaoLocalDisponivel
                          ? 'Protegido pelo bloqueio do aparelho'
                          : 'Protegido no app',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentPixList extends StatelessWidget {
  const _RecentPixList({required this.repository});

  final PixRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repository.watchRecentPix(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.outline),
            ),
            child: Text(
              'Nenhum PIX por enquanto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          child: Column(
            children: docs.map((doc) {
              final data = doc.data();
              final isLast = doc == docs.last;
              final value = data['valorCentavos'];
              final centavos = value is int
                  ? value
                  : value is num
                      ? value.round()
                      : 0;
              final direction = (data['direction'] ?? 'sent').toString();
              final recebido = direction == 'received';
              final name =
                  (data['recipientName'] ?? data['chave'] ?? 'PIX').toString();
              final date = _formatDate(data['data'] ?? data['createdAt']);

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isLast ? Colors.transparent : AppColors.outline,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      recebido
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: recebido ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          Text(
                            date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${recebido ? '+' : '-'} ${BrFormatters.currencyFromCentavos(centavos)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: recebido ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _formatDate(Object? value) {
    DateTime? date;
    if (value is Timestamp) date = value.toDate();
    if (value is DateTime) date = value;
    if (date == null) return 'Data pendente';
    return BrFormatters.dateTime(date);
  }
}
