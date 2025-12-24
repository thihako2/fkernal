import '../error/fkernal_error.dart';
import '../storage/cache_config.dart';
import '../theme/theme_config.dart';
import 'environment.dart';
import 'interfaces.dart';

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
///
/// All authentication features are opt-in. Use the configuration that fits your needs:
/// - [AuthConfig.bearer] for static bearer token
/// - [AuthConfig.apiKey] for API key authentication
/// - Custom [tokenProvider] for dynamic tokens (e.g., from secure storage)
class AuthConfig {
  /// The authentication token (if using token-based auth).
  final String? token;

  /// Custom headers to include in all requests.
  final Map<String, String> headers;

  /// API key for key-based authentication.
  final String? apiKey;

  /// Header name for the API key.
  final String apiKeyHeader;

  /// Optional: Token refresh callback.
  ///
  /// If provided, this will be called when a 401 response is received,
  /// and the request will be retried with the new token.
  final Future<String?> Function()? onTokenRefresh;

  /// Optional: Dynamic token provider.
  ///
  /// If provided, this will be called before each request to get the current token.
  /// Useful for tokens stored in secure storage that may change.
  final Future<String?> Function()? tokenProvider;

  /// Optional: Callback when token expires (receives 401).
  ///
  /// Called when a 401 is received and no [onTokenRefresh] is provided,
  /// allowing the app to handle logout/redirect.
  final void Function()? onTokenExpired;

  const AuthConfig({
    this.token,
    this.headers = const {},
    this.apiKey,
    this.apiKeyHeader = 'X-API-Key',
    this.onTokenRefresh,
    this.tokenProvider,
    this.onTokenExpired,
  });

  /// Creates auth config with bearer token.
  factory AuthConfig.bearer(
    String token, {
    Map<String, String>? extraHeaders,
    Future<String?> Function()? onTokenRefresh,
  }) {
    return AuthConfig(
      token: token,
      headers: {'Authorization': 'Bearer $token', ...?extraHeaders},
      onTokenRefresh: onTokenRefresh,
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

  /// Creates auth config with dynamic token provider.
  ///
  /// Useful when tokens are stored in secure storage and may change:
  /// ```dart
  /// AuthConfig.dynamic(
  ///   tokenProvider: () => secureStorage.read('access_token'),
  ///   onTokenRefresh: () => authService.refreshToken(),
  ///   onTokenExpired: () => router.go('/login'),
  /// )
  /// ```
  factory AuthConfig.dynamic({
    required Future<String?> Function() tokenProvider,
    Future<String?> Function()? onTokenRefresh,
    void Function()? onTokenExpired,
  }) {
    return AuthConfig(
      tokenProvider: tokenProvider,
      onTokenRefresh: onTokenRefresh,
      onTokenExpired: onTokenExpired,
    );
  }

  /// Creates a copy with updated token.
  AuthConfig copyWithToken(String? newToken) {
    final newHeaders = Map<String, String>.from(headers);
    if (newToken != null) {
      newHeaders['Authorization'] = 'Bearer $newToken';
    } else {
      newHeaders.remove('Authorization');
    }
    return AuthConfig(
      token: newToken,
      headers: newHeaders,
      apiKey: apiKey,
      apiKeyHeader: apiKeyHeader,
      onTokenRefresh: onTokenRefresh,
      tokenProvider: tokenProvider,
      onTokenExpired: onTokenExpired,
    );
  }
}

/// Pagination configuration.
class PaginationConfig {
  /// Default page size.
  final int pageSize;

  /// Default page parameter name.
  final String pageParam;

  /// Default limit parameter name.
  final String limitParam;

  const PaginationConfig({
    this.pageSize = 20,
    this.pageParam = 'page',
    this.limitParam = 'limit',
  });
}

/// Error behavior configuration.
class ErrorConfig {
  /// Whether to show a default error snackbar.
  final bool showSnackbars;

  /// Whether to automatically log errors to the console.
  final bool logToConsole;

  /// Global interceptor for errors.
  final void Function(FKernalError error)? onGlobalError;

  const ErrorConfig({
    this.showSnackbars = true,
    this.logToConsole = true,
    this.onGlobalError,
  });
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

  /// Pagination configuration.
  final PaginationConfig pagination;

  /// Error behavior configuration.
  final ErrorConfig errorConfig;

  /// Connection timeout in milliseconds.
  final int connectTimeout;

  /// Receive timeout in milliseconds.
  final int receiveTimeout;

  /// Custom storage providers.
  final IStorageProvider? cacheProviderOverride;
  final IStorageProvider? dataProviderOverride;
  final ISecureStorageProvider? secureProviderOverride;

  /// Custom network client override.
  final INetworkClient? networkClientOverride;

  const FKernalConfig({
    required this.baseUrl,
    this.environment = Environment.development,
    this.features = const FeatureFlags(),
    this.auth,
    this.defaultCacheConfig = const CacheConfig(),
    this.theme,
    this.pagination = const PaginationConfig(),
    this.errorConfig = const ErrorConfig(),
    this.connectTimeout = 30000,
    this.receiveTimeout = 30000,
    this.cacheProviderOverride,
    this.dataProviderOverride,
    this.secureProviderOverride,
    this.networkClientOverride,
  });

  /// Validates the configuration.
  void validate() {
    if (baseUrl.isEmpty) {
      throw StateError('[FKernalConfig] baseUrl cannot be empty');
    }

    if (!baseUrl.startsWith('http') && networkClientOverride == null) {
      throw StateError('[FKernalConfig] baseUrl must start with http or https');
    }
  }

  /// Creates a copy with updated values.
  FKernalConfig copyWith({
    String? baseUrl,
    Environment? environment,
    FeatureFlags? features,
    AuthConfig? auth,
    CacheConfig? defaultCacheConfig,
    ThemeConfig? theme,
    PaginationConfig? pagination,
    ErrorConfig? errorConfig,
    int? connectTimeout,
    int? receiveTimeout,
    IStorageProvider? cacheProviderOverride,
    IStorageProvider? dataProviderOverride,
    ISecureStorageProvider? secureProviderOverride,
    INetworkClient? networkClientOverride,
  }) {
    return FKernalConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      environment: environment ?? this.environment,
      features: features ?? this.features,
      auth: auth ?? this.auth,
      defaultCacheConfig: defaultCacheConfig ?? this.defaultCacheConfig,
      theme: theme ?? this.theme,
      pagination: pagination ?? this.pagination,
      errorConfig: errorConfig ?? this.errorConfig,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      cacheProviderOverride:
          cacheProviderOverride ?? this.cacheProviderOverride,
      dataProviderOverride: dataProviderOverride ?? this.dataProviderOverride,
      secureProviderOverride:
          secureProviderOverride ?? this.secureProviderOverride,
      networkClientOverride:
          networkClientOverride ?? this.networkClientOverride,
    );
  }
}
