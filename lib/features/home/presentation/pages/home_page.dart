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
import '../../../../core/services/app_repositories.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/utils/br_formatters.dart';
import '../../../pix/data/repositories/pix_repository.dart';
import '../widgets/home_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepository = AppRepositories.auth;
  final _pixRepository = AppRepositories.pix;
  bool _autenticacaoLocalDisponivel = false;
  bool _biometriaDisponivel = false;
  bool _saldoVisivel = false;
  Uint8List? _imagemPerfilBytes;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _accountStream;
  late final Stream<PixSummary> _monthlySummaryStream;

  @override
  void initState() {
    super.initState();
    _accountStream = _pixRepository.watchAccount();
    _monthlySummaryStream = _pixRepository.watchMonthlySummary();
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
    if (!mounted) return;

    if (autenticado) {
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
        _mostrarMensagem('Não foi possível confirmar sua identidade agora.');
      }
      return false;
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final imagem = await AppPlugins.imagePicker.pickImage(
        source: source,
        maxWidth: 160,
        maxHeight: 160,
        imageQuality: 45,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagemPerfilBytes = bytes;
      });

      await _authRepository.updateProfileImageBytes(bytes);

      if (!mounted) return;
      _mostrarMensagem('Foto de perfil atualizada.');
    } catch (_) {
      if (mounted) {
        _mostrarMensagem(
            'Não conseguimos atualizar a foto. Tente outra imagem.');
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
    final accountCode = _accountCodeFromUid(user?.uid);
    final text = '''
FinTech
Titular: ${user?.displayName ?? user?.email ?? 'Cliente'}
Agência: 0001
Conta: $accountCode
''';
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    _mostrarMensagem('Dados da conta copiados para a área de transferência.');
  }

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final displayName = _displayNameFor(user?.displayName, user?.email);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTech'),
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
          stream: _accountStream,
          builder: (context, accountSnapshot) {
            if (accountSnapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: HomeInfoPanel(
                  icon: Icons.cloud_off_rounded,
                  title: 'Não foi possível carregar sua conta',
                  message:
                      'Verifique sua conexão e tente novamente em instantes.',
                ),
              );
            }

            if (accountSnapshot.connectionState == ConnectionState.waiting &&
                !accountSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final accountData = accountSnapshot.data?.data();
            final saldoCentavos = _intFrom(
              accountData?['balanceCentavos'],
              fallback: PixRepository.initialBalanceCentavos,
            );
            final profileImageProvider = _profileImageProvider(accountData);
            final isUsingCachedAccount =
                accountSnapshot.data?.metadata.isFromCache ?? false;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                if (isUsingCachedAccount) ...[
                  const _OfflineAccountBanner(),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    GestureDetector(
                      onTap: _abrirSeletorImagem,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        backgroundImage: profileImageProvider,
                        child: profileImageProvider == null
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
                            'Toque na foto para deixar a conta com a sua cara',
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
                BalanceCard(
                  saldoVisivel: _saldoVisivel,
                  saldoCentavos: saldoCentavos,
                  biometriaDisponivel: _biometriaDisponivel,
                  autenticacaoLocalDisponivel: _autenticacaoLocalDisponivel,
                  onToggleSaldo: _mostrarSaldoComBiometria,
                ),
                const SizedBox(height: 24),
                StreamBuilder<PixSummary>(
                  stream: _monthlySummaryStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const HomeInfoPanel(
                        icon: Icons.cloud_off_rounded,
                        title: 'Resumo indisponível',
                        message:
                            'Não foi possível atualizar as entradas e saídas.',
                      );
                    }

                    final summary = snapshot.data ??
                        const PixSummary(
                          entradasCentavos: 0,
                          saidasCentavos: 0,
                        );

                    return Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
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
                          child: SummaryCard(
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
                    ActionTile(
                      icon: Icons.currency_exchange_rounded,
                      label: 'Cotação',
                      color: AppColors.accent,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.cotacao,
                      ),
                    ),
                    ActionTile(
                      icon: Icons.pix_rounded,
                      label: 'Transferência',
                      color: AppColors.secondary,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixTransfer,
                      ),
                    ),
                    ActionTile(
                      icon: Icons.qr_code_2_rounded,
                      label: 'Receber PIX',
                      color: AppColors.success,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixReceive,
                      ),
                    ),
                    ActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Histórico',
                      color: AppColors.info,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.pixHistory,
                      ),
                    ),
                    ActionTile(
                      icon: Icons.copy_rounded,
                      label: 'Dados da conta',
                      color: AppColors.primaryLight,
                      onTap: _copiarDadosConta,
                    ),
                    ActionTile(
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
                RecentPixList(repository: _pixRepository),
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

  ImageProvider? _profileImageProvider(Map<String, dynamic>? accountData) {
    if (_imagemPerfilBytes != null) return MemoryImage(_imagemPerfilBytes!);

    final bytes = _decodeProfileImage(accountData?['profileImageBase64']);
    if (bytes != null) return MemoryImage(bytes);

    return null;
  }

  Uint8List? _decodeProfileImage(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  String _displayNameFor(String? rawDisplayName, String? rawEmail) {
    final displayName = rawDisplayName?.trim();
    final emailName = rawEmail?.split('@').first.trim();
    final name = displayName?.isNotEmpty == true
        ? displayName!
        : emailName?.isNotEmpty == true
            ? emailName!
            : 'cliente';

    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  String _accountCodeFromUid(String? uid) {
    final normalized = uid?.trim();
    if (normalized == null || normalized.isEmpty) return '00000000';
    final length = normalized.length < 8 ? normalized.length : 8;
    return normalized.substring(0, length).toUpperCase().padRight(8, '0');
  }
}

class _OfflineAccountBanner extends StatelessWidget {
  const _OfflineAccountBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mostrando dados salvos. A conta será atualizada quando a conexão voltar.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
