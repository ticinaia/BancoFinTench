class AuthSessionService {
  AuthSessionService._();

  static bool _isUnlocked = false;

  static bool get isUnlocked => _isUnlocked;

  static void unlock() {
    _isUnlocked = true;
  }

  static void lock() {
    _isUnlocked = false;
  }
}
