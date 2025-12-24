import '../storage/cache_config.dart';
import 'http_method.dart';

/// Response parser function type.
typedef ResponseParser<T> = T Function(dynamic json);

/// Declarative endpoint definition.
///
/// Define your API endpoints as constants:
///
/// ```dart
/// const endpoints = [
///   Endpoint(
///     id: 'getUsers',
///     path: '/users',
///     method: HttpMethod.get,
///     cacheConfig: CacheConfig(duration: Duration(minutes: 5)),
///   ),
///   Endpoint(
///     id: 'getUser',
///     path: '/users/{id}',
///     method: HttpMethod.get,
///   ),
///   Endpoint(
///     id: 'createUser',
///     path: '/users',
///     method: HttpMethod.post,
///   ),
/// ];
/// ```
class Endpoint {
  /// Unique identifier for this endpoint.
  ///
  /// This is used to reference the endpoint in UI code:
  /// ```dart
  /// FKernalBuilder(resource: 'getUsers', ...)
  /// ```
  final String id;

  /// The URL path for this endpoint.
  ///
  /// Supports path parameters using `{paramName}` syntax:
  /// ```dart
  /// Endpoint(path: '/users/{userId}/posts/{postId}', ...)
  /// ```
  final String path;

  /// The HTTP method for this endpoint.
  final HttpMethod method;

  /// Cache configuration for this endpoint.
  ///
  /// If null, uses the default cache config from [FKernalConfig].
  final CacheConfig? cacheConfig;

  /// List of endpoint IDs to invalidate when this endpoint is called.
  ///
  /// Useful for mutations that affect other cached data:
  /// ```dart
  /// Endpoint(
  ///   id: 'createUser',
  ///   method: HttpMethod.post,
  ///   invalidates: ['getUsers', 'getUserCount'],
  /// )
  /// ```
  final List<String> invalidates;

  /// Custom headers for this endpoint.
  final Map<String, String> headers;

  /// Query parameters to always include.
  final Map<String, String> defaultQueryParams;

  /// Whether to require authentication for this endpoint.
  final bool requiresAuth;

  /// Custom response parser.
  ///
  /// If null, the raw JSON response is returned.
  final ResponseParser? parser;

  /// Description for documentation.
  final String? description;

  const Endpoint({
    required this.id,
    required this.path,
    this.method = HttpMethod.get,
    this.cacheConfig,
    this.invalidates = const [],
    this.headers = const {},
    this.defaultQueryParams = const {},
    this.requiresAuth = true,
    this.parser,
    this.description,
  });

  /// Returns the path with path parameters substituted.
  ///
  /// ```dart
  /// final endpoint = Endpoint(path: '/users/{id}');
  /// endpoint.buildPath({'id': '123'}); // Returns '/users/123'
  /// ```
  String buildPath(Map<String, String>? pathParams) {
    if (pathParams == null || pathParams.isEmpty) {
      return path;
    }

    String result = path;
    for (final entry in pathParams.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  /// Whether this endpoint supports caching.
  bool get isCacheable => method.isReadOnly && cacheConfig != null;

  /// Creates a copy with updated values.
  Endpoint copyWith({
    String? id,
    String? path,
    HttpMethod? method,
    CacheConfig? cacheConfig,
    List<String>? invalidates,
    Map<String, String>? headers,
    Map<String, String>? defaultQueryParams,
    bool? requiresAuth,
    ResponseParser? parser,
    String? description,
  }) {
    return Endpoint(
      id: id ?? this.id,
      path: path ?? this.path,
      method: method ?? this.method,
      cacheConfig: cacheConfig ?? this.cacheConfig,
      invalidates: invalidates ?? this.invalidates,
      headers: headers ?? this.headers,
      defaultQueryParams: defaultQueryParams ?? this.defaultQueryParams,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      parser: parser ?? this.parser,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'Endpoint($id: ${method.value} $path)';

  /// Resolves the path by substituting path parameters.
  static String resolvePath(String path, Map<String, String>? pathParams) {
    if (pathParams == null || pathParams.isEmpty) return path;
    var resolvedPath = path;
    pathParams.forEach((key, value) {
      resolvedPath = resolvedPath.replaceAll('{$key}', value);
    });
    return resolvedPath;
  }

  /// Builds a cache key (or unique resource ID) from a path and query parameters.
  static String buildCacheKey(
      String resolvedPath, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return resolvedPath;
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final query =
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$resolvedPath?$query';
  }

  /// Generates a unique resource ID for an endpoint request.
  static String generateKey(
    Endpoint endpoint, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    final resolvedPath = resolvePath(endpoint.path, pathParams);
    return buildCacheKey(resolvedPath, params);
  }
}
