import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/app_plugins.dart';

class AuthSecurityService {
  AuthSecurityService._();

  static String _pinKey(String userId) {
    return '${AppConstants.appPinKey}_$userId';
  }

  static Future<bool> hasPin(String userId) async {
    final pin = await AppPlugins.secureStorage.read(key: _pinKey(userId));
    return pin != null && pin.length >= 4;
  }

  static Future<void> savePin({
    required String userId,
    required String pin,
  }) async {
    await AppPlugins.secureStorage.write(
      key: _pinKey(userId),
      value: pin,
    );
  }

  static Future<bool> validatePin({
    required String userId,
    required String pin,
  }) async {
    final savedPin = await AppPlugins.secureStorage.read(key: _pinKey(userId));
    return savedPin != null && savedPin == pin;
  }

  static Future<void> clearPin(String userId) async {
    await AppPlugins.secureStorage.delete(key: _pinKey(userId));
  }
}
