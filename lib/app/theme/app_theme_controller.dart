import 'package:flutter/material.dart';

import '../../core/services/app_plugins.dart';

class AppThemeController {
  AppThemeController._();

  static const _storageKey = 'theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> initialize() async {
    final saved = await AppPlugins.secureStorage.read(key: _storageKey);
    mode.value = _modeFromStorage(saved);
  }

  static Future<void> setMode(ThemeMode themeMode) async {
    mode.value = themeMode;
    await AppPlugins.secureStorage.write(
      key: _storageKey,
      value: themeMode.name,
    );
  }

  static ThemeMode _modeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
