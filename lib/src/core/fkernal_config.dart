import '../storage/cache_config.dart';
import '../theme/theme_config.dart';
import 'environment.dart';

/// Feature flags for enabling/disabling functionality.
class FeatureFlags {
  /// Whether to enable response caching.
  final bool enableCache;

  /// Whether to enable offline mode support.
  final bool enableOffline;

  /// Whether to enable automatic retry on failure.
  final bool enableAutoRetry;

  /// Maximum number of retry attempts.
  final int maxRetryAttempts;

  /// Whether to enable request/response logging.
  final bool enableLogging;

  const FeatureFlags({
    this.enableCache = true,
    this.enableOffline = false,
    this.enableAutoRetry = true,
    this.maxRetryAttempts = 3,
    this.enableLogging = true,
  });
}

/// Authentication configuration.
class AuthConfig {
  /// The authentication token (if using token-based auth).
  final String? token;

  /// Custom headers to include in all requests.
  final Map<String, String> headers;

  /// API key for key-based authentication.
  final String? apiKey;

  /// Header name for the API key.
  final String apiKeyHeader;

  /// Token refresh callback.
  final Future<String?> Function()? onTokenRefresh;

  const AuthConfig({
    this.token,
    this.headers = const {},
    this.apiKey,
    this.apiKeyHeader = 'X-API-Key',
    this.onTokenRefresh,
  });

  /// Creates auth config with bearer token.
  factory AuthConfig.bearer(String token, {Map<String, String>? extraHeaders}) {
    return AuthConfig(
      token: token,
      headers: {'Authorization': 'Bearer $token', ...?extraHeaders},
    );
  }

  /// Creates auth config with API key.
  factory AuthConfig.apiKey(String key, {String header = 'X-API-Key'}) {
    return AuthConfig(
      apiKey: key,
      apiKeyHeader: header,
      headers: {header: key},
    );
  }
}

/// Main configuration container for FKernal.
class FKernalConfig {
  /// Base URL for all API requests.
  final String baseUrl;

  /// Current environment.
  final Environment environment;

  /// Feature flags.
  final FeatureFlags features;

  /// Authentication configuration.
  final AuthConfig? auth;

  /// Default cache configuration.
  final CacheConfig defaultCacheConfig;

  /// Theme configuration.
  final ThemeConfig? theme;

  /// Connection timeout in milliseconds.
  final int connectTimeout;

  /// Receive timeout in milliseconds.
  final int receiveTimeout;

  /// Default pagination size.
  final int defaultPageSize;

  const FKernalConfig({
    required this.baseUrl,
    this.environment = Environment.development,
    this.features = const FeatureFlags(),
    this.auth,
    this.defaultCacheConfig = const CacheConfig(),
    this.theme,
    this.connectTimeout = 30000,
    this.receiveTimeout = 30000,
    this.defaultPageSize = 20,
  });

  /// Creates a copy with updated values.
  FKernalConfig copyWith({
    String? baseUrl,
    Environment? environment,
    FeatureFlags? features,
    AuthConfig? auth,
    CacheConfig? defaultCacheConfig,
    ThemeConfig? theme,
    int? connectTimeout,
    int? receiveTimeout,
    int? defaultPageSize,
  }) {
    return FKernalConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      environment: environment ?? this.environment,
      features: features ?? this.features,
      auth: auth ?? this.auth,
      defaultCacheConfig: defaultCacheConfig ?? this.defaultCacheConfig,
      theme: theme ?? this.theme,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      defaultPageSize: defaultPageSize ?? this.defaultPageSize,
    );
  }
}
