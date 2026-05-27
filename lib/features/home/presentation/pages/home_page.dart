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
  bool _biometriaDisponivel = false;
  bool _saldoVisivel = false;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    final disponivel = await AppPlugins.localAuth.canCheckBiometrics;
    final suportado = await AppPlugins.localAuth.isDeviceSupported();

    if (mounted) {
      setState(() => _biometriaDisponivel = disponivel || suportado);
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
    if (!_biometriaDisponivel) return true;

    try {
      return AppPlugins.localAuth.authenticate(
        localizedReason: motivo,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      if (mounted) _mostrarMensagem('Erro ao autenticar.');
      return false;
    }
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
            Text(
              'Olá, $name',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            _BalanceCard(
              saldoVisivel: _saldoVisivel,
              biometriaDisponivel: _biometriaDisponivel,
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
    required this.onToggleSaldo,
  });

  final bool saldoVisivel;
  final bool biometriaDisponivel;
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
            saldoVisivel ? 'R\$ 2.450,00' : 'R\$ ••••••',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
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
                      : 'Protegido pelo bloqueio do aparelho',
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
