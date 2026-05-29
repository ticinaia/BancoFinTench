import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/routes/routes.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/app_theme_controller.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_plugins.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/services/auth_session_service.dart';

final _appNavigatorKey = GlobalKey<NavigatorState>();
final _appRouteObserver = _AppRouteObserver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação (apenas portrait para app bancário)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurar StatusBar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await AppPlugins.initialize();
  await AppThemeController.initialize();

  runApp(const BancoFinTechApp());
}

class BancoFinTechApp extends StatelessWidget {
  const BancoFinTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          navigatorKey: _appNavigatorKey,
          navigatorObservers: [_appRouteObserver],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          initialRoute: AppRoutes.splash,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            return _SessionTimeoutGuard(
              navigatorKey: _appNavigatorKey,
              routeObserver: _appRouteObserver,
              child: child ?? const SizedBox.shrink(),
            );
          },
          locale: const Locale('pt', 'BR'),
        );
      },
    );
  }
}

class _AppRouteObserver extends NavigatorObserver {
  String? currentRoute;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = route.settings.name;
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    currentRoute = previousRoute?.settings.name;
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    currentRoute = newRoute?.settings.name;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class _SessionTimeoutGuard extends StatefulWidget {
  const _SessionTimeoutGuard({
    required this.navigatorKey,
    required this.routeObserver,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final _AppRouteObserver routeObserver;
  final Widget child;

  @override
  State<_SessionTimeoutGuard> createState() => _SessionTimeoutGuardState();
}

class _SessionTimeoutGuardState extends State<_SessionTimeoutGuard> {
  Timer? _timer;
  final _authRepository = AuthRepository();

  static const _publicRoutes = {
    AppRoutes.splash,
    AppRoutes.login,
    AppRoutes.cadastro,
    AppRoutes.emailVerification,
    AppRoutes.authLock,
    AppRoutes.pinSetup,
  };

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetTimer() {
    _timer?.cancel();

    if (_authRepository.currentUser == null) return;

    _timer = Timer(AppConstants.sessionTimeout, _expireSession);
  }

  Future<void> _expireSession() async {
    final currentRoute = widget.routeObserver.currentRoute;
    if (_authRepository.currentUser == null ||
        _publicRoutes.contains(currentRoute)) {
      return;
    }

    AuthSessionService.lock();

    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.authLock,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
