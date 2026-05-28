class AppConstants {
  AppConstants._();

  static const String appName = 'BancoFinTech';
  static const String appVersion = '1.0.0';

  // Duração da Splash Screen
  static const Duration splashDuration = Duration(seconds: 3);

  static const String awesomeApiBaseUrl = 'https://economia.awesomeapi.com.br';

  // Timeouts de rede
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Chaves de armazenamento seguro
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String biometricEnabledKey = 'biometric_enabled';

  // Colecoes do Firestore
  static const String usersCollection = 'users';
}
