/// Environment configuration for the app.
enum Environment {
  /// Development environment with verbose logging.
  development,

  /// Staging environment for testing.
  staging,

  /// Production environment with minimal logging.
  production,
}

/// Extension methods for Environment.
extension EnvironmentX on Environment {
  /// Whether this is a development environment.
  bool get isDevelopment => this == Environment.development;

  /// Whether this is a staging environment.
  bool get isStaging => this == Environment.staging;

  /// Whether this is a production environment.
  bool get isProduction => this == Environment.production;

  /// Whether verbose logging should be enabled.
  bool get shouldLog => this != Environment.production;
}
