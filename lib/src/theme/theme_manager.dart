import 'package:flutter/material.dart';

import 'theme_config.dart';

/// Manages theming for the application.
///
/// Provides light and dark themes based on configuration,
/// with support for dynamic theme switching.
class ThemeManager extends ChangeNotifier {
  final ThemeConfig? config;
  ThemeMode _themeMode;

  ThemeManager({this.config})
    : _themeMode = config?.defaultThemeMode ?? ThemeMode.system;

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Sets the theme mode.
  set themeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  /// The light theme.
  ThemeData get lightTheme {
    return config?.buildLightTheme() ?? _defaultLightTheme;
  }

  /// The dark theme.
  ThemeData get darkTheme {
    return config?.buildDarkTheme() ?? _defaultDarkTheme;
  }

  /// Gets the appropriate theme based on brightness.
  ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.light ? lightTheme : darkTheme;
  }

  /// Toggles between light and dark mode.
  void toggleTheme() {
    themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  /// Sets to light mode.
  void setLightMode() => themeMode = ThemeMode.light;

  /// Sets to dark mode.
  void setDarkMode() => themeMode = ThemeMode.dark;

  /// Sets to system mode.
  void setSystemMode() => themeMode = ThemeMode.system;

  static final ThemeData _defaultLightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.light,
    ),
  );

  static final ThemeData _defaultDarkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    ),
  );
}
