import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepository = AuthRepository();
  bool _autenticacaoLocalDisponivel = false;
  bool _biometriaDisponivel = false;
  bool _saldoVisivel = false;
<<<<<<< Updated upstream
=======

  XFile? _imagemPerfil;

  final List<Map<String, dynamic>> _ultimasTransferencias = [
    {
      'nome': 'Maria Silva',
      'valor': 580.00,
      'tipo': 'recebido',
      'data': 'Hoje, 14:22',
    },
    {
      'nome': 'João Pedro',
      'valor': 150.00,
      'tipo': 'enviado',
      'data': 'Ontem, 18:40',
    },
    {
      'nome': 'Netflix',
      'valor': 39.90,
      'tipo': 'enviado',
      'data': 'Ontem, 09:10',
    },
  ];
>>>>>>> Stashed changes

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
<<<<<<< Updated upstream
    final disponivel = await AppPlugins.localAuth.canCheckBiometrics;
    final suportado = await AppPlugins.localAuth.isDeviceSupported();

    if (mounted) {
      setState(() => _biometriaDisponivel = disponivel || suportado);
=======
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
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
    if (!_biometriaDisponivel) return true;

    try {
      return AppPlugins.localAuth.authenticate(
=======
    if (kIsWeb) return true;

    if (!_autenticacaoLocalDisponivel) return true;

    try {
      return await AppPlugins.localAuth.authenticate(
>>>>>>> Stashed changes
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
<<<<<<< Updated upstream
      if (mounted) _mostrarMensagem('Erro ao autenticar.');
      return false;
    }
  }
=======
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
        imageQuality: 75,
      );

      if (imagem == null) return;

      setState(() {
        _imagemPerfil = imagem;
      });

      if (mounted) {
        _mostrarMensagem('Imagem de perfil atualizada.');
      }
    } catch (_) {
      _mostrarMensagem('Erro ao selecionar imagem.');
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
>>>>>>> Stashed changes

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

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final name = user?.email?.split('@').first ?? 'cliente';

    return Scaffold(
      appBar: AppBar(
        title: const Text('BancoFinTech'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
<<<<<<< Updated upstream
            Text(
              'Olá, $name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
=======
            Row(
              children: [
                GestureDetector(
                  onTap: _abrirSeletorImagem,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: _imagemPerfil != null
                        ? (kIsWeb
                            ? NetworkImage(_imagemPerfil!.path)
                            : FileImage(File(_imagemPerfil!.path))
                                as ImageProvider)
                        : null,
                    child: _imagemPerfil == null
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
                        'Olá, ${name[0].toUpperCase()}${name.substring(1)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                      Text(
                        'Toque na foto para alterar',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
>>>>>>> Stashed changes
            ),
            const SizedBox(height: 12),
            _BalanceCard(
              saldoVisivel: _saldoVisivel,
              biometriaDisponivel: _biometriaDisponivel,
              autenticacaoLocalDisponivel: _autenticacaoLocalDisponivel,
              onToggleSaldo: _mostrarSaldoComBiometria,
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
              childAspectRatio: 1.45,
              children: [
                _ActionTile(
                  icon: Icons.pix_rounded,
                  label: 'PIX',
                  color: AppColors.secondary,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.pixTransfer,
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
                  icon: Icons.fingerprint_rounded,
                  label: 'Segurança',
                  color: AppColors.primaryLight,
                  onTap: () async {
                    final ok = await _autenticarComBiometria(
                      'Confirme sua identidade para testar a segurança',
                    );
                    if (ok && mounted) {
                      _mostrarMensagem('Autenticação realizada com sucesso.');
                    }
                  },
                ),
                _ActionTile(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  color: AppColors.accent,
                  onTap: () => _mostrarMensagem('Perfil em desenvolvimento.'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Resumo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
<<<<<<< Updated upstream
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _biometriaDisponivel
                            ? 'Biometria disponível para proteger ações importantes.'
                            : 'Use senha ou bloqueio do aparelho para proteger suas ações.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
=======
            ..._ultimasTransferencias.map(
              (transferencia) {
                final recebido = transferencia['tipo'] == 'recebido';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: recebido
                                ? AppColors.secondary.withValues(alpha: 0.12)
                                : AppColors.error.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            recebido
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: recebido
                                ? AppColors.secondaryDark
                                : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transferencia['nome'],
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transferencia['data'],
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: recebido
                                      ? AppColors.secondary
                                          .withValues(alpha: 0.10)
                                      : AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  recebido ? 'Recebido' : 'Enviado',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: recebido
                                        ? AppColors.secondaryDark
                                        : AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${recebido ? '+' : '-'} ${NumberFormat.currency(
                                locale: 'pt_BR',
                                symbol: 'R\$',
                              ).format(transferencia['valor'])}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: recebido
                                    ? AppColors.secondaryDark
                                    : AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Icon(
                              recebido
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 16,
                              color: recebido
                                  ? AppColors.secondaryDark
                                  : AppColors.error,
                            ),
                          ],
                        ),
                      ],
>>>>>>> Stashed changes
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.saldoVisivel,
    required this.biometriaDisponivel,
    required this.autenticacaoLocalDisponivel,
    required this.onToggleSaldo,
  });

  final bool saldoVisivel;
  final bool biometriaDisponivel;
  final bool autenticacaoLocalDisponivel;
  final VoidCallback onToggleSaldo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Saldo disponível',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
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
          Text(
<<<<<<< Updated upstream
            saldoVisivel ? 'R\$ 2.450,00' : 'R\$ ••••••',
=======
            saldoVisivel ? 'R\$ 2.450,00' : 'R\$ • • • • •',
>>>>>>> Stashed changes
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
<<<<<<< Updated upstream
=======
          const SizedBox(height: 4),
          Text(
            'Conta corrente',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
>>>>>>> Stashed changes
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
                        color: Colors.white70,
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
