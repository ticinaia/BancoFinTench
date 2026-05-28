import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/routes/routes.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_plugins.dart';

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
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await AppPlugins.initialize();

  runApp(const BancoFinTechApp());
}

class BancoFinTechApp extends StatelessWidget {
  const BancoFinTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Rota inicial
      initialRoute: AppRoutes.splash,

      // Gerador de rotas nomeadas
      onGenerateRoute: AppRouter.onGenerateRoute,

      // Locale
      locale: const Locale('pt', 'BR'),
    );
  }
}
