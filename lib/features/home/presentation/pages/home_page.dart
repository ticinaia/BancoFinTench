import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/app_plugins.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../auth/data/repositories/auth_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authRepository = AuthRepository();
  bool _biometriaDisponivel = false;

  @override
  void initState() {
    super.initState();
    _verificarBiometria();
  }

  Future<void> _verificarBiometria() async {
    final disponivel = await AppPlugins.localAuth.canCheckBiometrics;

    if (mounted) {
      setState(() => _biometriaDisponivel = disponivel);
    }
  }

  Future<void> _autenticarComBiometria() async {
    try {
      final autenticado = await AppPlugins.localAuth.authenticate(
        localizedReason: 'Use sua digital para acessar o BancoFinTech',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (autenticado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria autenticada com sucesso!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometria nao reconhecida.'),
          ),
        );
      }
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao autenticar com biometria.'),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _authRepository.signOut();

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.home_outlined,
                        color: AppColors.primary,
                        size: 56,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Dashboard inicial',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        FirebaseService.isReady
                            ? 'Firebase inicializado com sucesso.'
                            : 'Firebase ainda nao inicializou.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_biometriaDisponivel)
                ElevatedButton.icon(
                  onPressed: _autenticarComBiometria,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Autenticar com Digital'),
                ),
              if (_biometriaDisponivel) const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pixTransfer,
                  );
                },
                child: const Text('Transferência PIX'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.pixHistory,
                  );
                },
                child: const Text('Histórico PIX'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.cotacao,
                  );
                },
                child: const Text('Cotações'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
