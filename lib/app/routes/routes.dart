import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/cadastro_page.dart';
import '../../features/auth/presentation/pages/auth_lock_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/pages/pin_setup_page.dart';
import '../../features/auth/presentation/pages/security_page.dart';
import '../../features/auth/data/services/auth_session_service.dart';
import '../../core/services/app_repositories.dart';

// Páginas
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_history_page.dart';
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_qr_scanner_page.dart';
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_receive_page.dart';
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_receipt_page.dart';
import 'package:banco_fin_tech/features/pix/presentation/pages/pix_transfer_page.dart';
import 'package:banco_fin_tech/features/splash/presentation/pages/splash_page.dart';
import 'package:banco_fin_tech/features/auth/presentation/pages/cotacao_page.dart';
import 'package:banco_fin_tech/features/auth/presentation/pages/login_page.dart';
import 'package:banco_fin_tech/features/home/presentation/pages/home_page.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final guardedSettings = _guard(settings);
    if (guardedSettings.name != settings.name) {
      return onGenerateRoute(guardedSettings);
    }

    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashPage(), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginPage(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomePage(), settings);

      case AppRoutes.cadastro:
        return _buildRoute(const CadastroPage(), settings);

      case AppRoutes.emailVerification:
        return _buildRoute(const EmailVerificationPage(), settings);

      case AppRoutes.authLock:
        return _buildRoute(const AuthLockPage(), settings);

      case AppRoutes.pinSetup:
        return _buildRoute(const PinSetupPage(), settings);

      case AppRoutes.security:
        return _buildRoute(const SecurityPage(), settings);

      case AppRoutes.cotacao:
        return _buildRoute(const CotacaoPage(), settings);

      case AppRoutes.pixTransfer:
        return _buildRoute(const PixTransferPage(), settings);

      case AppRoutes.pixReceive:
        return _buildRoute(const PixReceivePage(), settings);

      case AppRoutes.pixHistory:
        return _buildRoute(const PixHistoryPage(), settings);

      case AppRoutes.pixReceipt:
        return _buildRoute(
          PixReceiptPage.fromRouteSettings(settings),
          settings,
        );

      case AppRoutes.pixQrScanner:
        return _buildRoute(const PixQrScannerPage(), settings);

      default:
        return _buildRoute(
          const _NotFoundPage(),
          settings,
        );
    }
  }

  static RouteSettings _guard(RouteSettings settings) {
    final routeName = settings.name ?? AppRoutes.splash;
    final authRepository = AppRepositories.auth;
    final user = authRepository.currentUser;

    const publicRoutes = {
      AppRoutes.splash,
      AppRoutes.login,
      AppRoutes.cadastro,
    };

    if (publicRoutes.contains(routeName)) return settings;

    if (user == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    if (!user.emailVerified && routeName != AppRoutes.emailVerification) {
      return const RouteSettings(name: AppRoutes.emailVerification);
    }

    if (routeName == AppRoutes.emailVerification ||
        routeName == AppRoutes.pinSetup ||
        routeName == AppRoutes.authLock) {
      return settings;
    }

    if (!AuthSessionService.isUnlocked) {
      return const RouteSettings(name: AppRoutes.authLock);
    }

    return settings;
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
