class AppConstants {
  AppConstants._();

  static const String appName = 'BancoFinTech';
  static const String appVersion = '1.0.0';

  // Duração máxima usada apenas por testes legados e documentação.
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration sessionTimeout = Duration(minutes: 5);

  static const String awesomeApiBaseUrl = 'https://economia.awesomeapi.com.br';

  // Conta
  static const int initialBalanceCentavos = 245000;
  static const int pixDailyLimitCentavos = 500000;

  // Timeouts de rede
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Chaves de armazenamento seguro
  static const String userIdKey = 'user_id';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String appPinKey = 'app_pin';

  // Coleções do Firestore
  static const String usersCollection = 'users';
}
