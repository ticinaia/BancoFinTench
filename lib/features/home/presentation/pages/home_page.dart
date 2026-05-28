import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  Uint8List? _imagemPerfilBytes;

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
        imageQuality: 75,
      );

      if (imagem == null) return;

      final bytes = await imagem.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imagemPerfilBytes = bytes;
      });

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

  @override
  Widget build(BuildContext context) {
    final user = _authRepository.currentUser;
    final name = user?.email?.split('@').first ?? 'cliente';
    final displayName = '${name[0].toUpperCase()}${name.substring(1)}';

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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _abrirSeletorImagem,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    backgroundImage: _imagemPerfilBytes != null
                        ? MemoryImage(_imagemPerfilBytes!)
                        : null,
                    child: _imagemPerfilBytes == null
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        'Toque na foto para personalizar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              crossAxisCount: 3,
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
                  icon: Icons.receipt_long_rounded,
                  label: 'Histórico',
                  color: AppColors.info,
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.pixHistory,
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
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.outline),
              ),
              child: Column(
                children: _ultimasTransferencias.map(
                  (transferencia) {
                    final recebido = transferencia['tipo'] == 'recebido';
                    final isLast = transferencia == _ultimasTransferencias.last;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isLast ? Colors.transparent : AppColors.outline,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: recebido
                                  ? AppColors.secondary.withValues(alpha: 0.12)
                                  : AppColors.error.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
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
                              ],
                            ),
                          ),
                          Text(
                            '${recebido ? '+' : '-'} ${NumberFormat.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            ).format(transferencia['valor'])}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: recebido
                                  ? AppColors.secondaryDark
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ).toList(),
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
          Text(
            saldoVisivel ? 'R\$ 2.450,00' : 'R\$ • • • • •',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Conta corrente',
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
