import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';

// Páginas
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_history_page.dart';
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_transfer_page.dart';
import 'package:banco_fin_tech/features/splash/presentation/pages/splash_page.dart';
import 'package:banco_fin_tech/features/auth/presentation/pages/cotacao_page.dart';
import 'package:banco_fin_tech/features/auth/presentation/pages/login_page.dart';
import 'package:banco_fin_tech/features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomePage(), settings);

      case AppRoutes.cadastro:
        return _buildRoute(const CadastroPage(), settings);

      case AppRoutes.cotacao:
        return _buildRoute(const CotacaoPage(), settings);

      case AppRoutes.pixTransfer:
        return MaterialPageRoute(
          builder: (_) => const PixTransferPage(),
        );

      case AppRoutes.pixHistory:
        return MaterialPageRoute(
          builder: (_) => const PixHistoryPage(),
        );

      default:
        return _buildRoute(
          const _NotFoundPage(),
          settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute(
    Widget page,
    RouteSettings settings,
  ) {
    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: settings,
    );
  }

  // Navegação com fade
  static PageRouteBuilder<dynamic> fadeRoute(Widget page) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // Navegação com slide
  static PageRouteBuilder<dynamic> slideRoute(Widget page) {
    return PageRouteBuilder<dynamic>(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;

        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(
          CurveTween(curve: Curves.easeInOut),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.splash,
                (_) => false,
              ),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}
