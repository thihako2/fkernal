import 'package:flutter/material.dart';

/// Theme configuration for the application.
///
/// Define colors, typography, and other design tokens:
///
/// ```dart
/// const themeConfig = ThemeConfig(
///   primaryColor: Color(0xFF6366F1),
///   secondaryColor: Color(0xFF8B5CF6),
///   fontFamily: 'Inter',
///   useMaterial3: true,
/// );
/// ```
class ThemeConfig {
  /// Primary brand color.
  final Color primaryColor;

  /// Secondary brand color.
  final Color secondaryColor;

  /// Accent color for highlights.
  final Color? accentColor;

  /// Background color.
  final Color? backgroundColor;

  /// Surface color.
  final Color? surfaceColor;

  /// Error color.
  final Color? errorColor;

  /// Primary font family.
  final String? fontFamily;

  /// Whether to use Material 3 design.
  final bool useMaterial3;

  /// Default theme mode.
  final ThemeMode defaultThemeMode;

  /// Custom light theme data (overrides generated theme).
  final ThemeData? lightTheme;

  /// Custom dark theme data (overrides generated theme).
  final ThemeData? darkTheme;

  /// Border radius for cards and buttons.
  final double borderRadius;

  /// Default padding value.
  final double defaultPadding;

  /// Elevation for cards.
  final double cardElevation;

  const ThemeConfig({
    this.primaryColor = const Color(0xFF6366F1),
    this.secondaryColor = const Color(0xFF8B5CF6),
    this.accentColor,
    this.backgroundColor,
    this.surfaceColor,
    this.errorColor,
    this.fontFamily,
    this.useMaterial3 = true,
    this.defaultThemeMode = ThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.borderRadius = 12.0,
    this.defaultPadding = 16.0,
    this.cardElevation = 2.0,
  });

  /// Generates a light theme from this configuration.
  ThemeData buildLightTheme() {
    if (lightTheme != null) return lightTheme!;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.light,
      surface: surfaceColor ?? Colors.white,
      error: errorColor ?? Colors.red,
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  /// Generates a dark theme from this configuration.
  ThemeData buildDarkTheme() {
    if (darkTheme != null) return darkTheme!;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: Brightness.dark,
      surface: surfaceColor ?? const Color(0xFF1E1E1E),
      error: errorColor ?? Colors.redAccent,
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: useMaterial3,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: backgroundColor,
      cardTheme: CardThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: defaultPadding * 1.5,
            vertical: defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: defaultPadding * 1.5,
            vertical: defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: defaultPadding,
            vertical: defaultPadding * 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        contentPadding: EdgeInsets.all(defaultPadding),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: brightness == Brightness.light
            ? colorScheme.surface
            : colorScheme.surface,
        foregroundColor: brightness == Brightness.light
            ? colorScheme.onSurface
            : colorScheme.onSurface,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Creates a copy with updated values.
  ThemeConfig copyWith({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? errorColor,
    String? fontFamily,
    bool? useMaterial3,
    ThemeMode? defaultThemeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    double? borderRadius,
    double? defaultPadding,
    double? cardElevation,
  }) {
    return ThemeConfig(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      errorColor: errorColor ?? this.errorColor,
      fontFamily: fontFamily ?? this.fontFamily,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      defaultThemeMode: defaultThemeMode ?? this.defaultThemeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      borderRadius: borderRadius ?? this.borderRadius,
      defaultPadding: defaultPadding ?? this.defaultPadding,
      cardElevation: cardElevation ?? this.cardElevation,
    );
  }
}
