import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/firebase_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
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
                            : 'Firebase ainda nao inicializou neste ambiente.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.login,
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Voltar para login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
