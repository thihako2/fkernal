import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/environment.dart';
import '../core/fkernal_config.dart';
import '../core/interfaces.dart';
import '../core/models/fkernal_model.dart';
import '../error/error_handler.dart';
import '../error/fkernal_error.dart';
import '../storage/storage_manager.dart';
import 'endpoint.dart';
import 'http_method.dart';

/// REST Implementation of INetworkClient using Dio.
///
/// Features (all opt-in based on configuration):
/// - Automatic token refresh on 401 (if [AuthConfig.onTokenRefresh] provided)
/// - Dynamic token injection (if [AuthConfig.tokenProvider] provided)
/// - Request deduplication for concurrent identical requests
/// - Per-request cancellation support
/// - Comprehensive error mapping
class ApiClient implements INetworkClient {
  @override
  final String baseUrl;
  final FKernalConfig config;
  final StorageManager storageManager;
  final ErrorHandler errorHandler;

  late final Dio _dio;

  /// Tracks in-flight requests for deduplication.
  final Map<String, Future<dynamic>> _inflightRequests = {};

  /// Cancel tokens for each endpoint for per-request cancellation.
  final Map<String, CancelToken> _cancelTokens = {};

  /// Current auth token (may be updated at runtime).
  String? _currentToken;

  /// Gets the current auth token.
  String? get currentToken => _currentToken;

  ApiClient({
    required this.baseUrl,
    required this.config,
    required this.storageManager,
    required this.errorHandler,
  }) {
    _currentToken = config.auth?.token;

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: Duration(milliseconds: config.connectTimeout),
        receiveTimeout: Duration(milliseconds: config.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?config.auth?.headers,
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Logging interceptor (only if enabled)
    if (config.features.enableLogging && config.environment.shouldLog) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (log) => debugPrint('[FKernal API] $log'),
        ),
      );
    }

    // Dynamic token injection interceptor (only if tokenProvider is set)
    if (config.auth?.tokenProvider != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            try {
              final token = await config.auth!.tokenProvider!();
              if (token != null) {
                options.headers['Authorization'] = 'Bearer $token';
                _currentToken = token;
              }
            } catch (e) {
              debugPrint('[FKernal] Token provider error: $e');
            }
            handler.next(options);
          },
        ),
      );
    }

    // Token refresh interceptor (only if onTokenRefresh is set)
    if (config.auth?.onTokenRefresh != null) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              try {
                final newToken = await config.auth!.onTokenRefresh!();
                if (newToken != null) {
                  _currentToken = newToken;
                  // Retry the request with new token
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                }
              } catch (refreshError) {
                debugPrint('[FKernal] Token refresh failed: $refreshError');
              }
              // If refresh fails, notify via callback if provided
              config.auth?.onTokenExpired?.call();
            }
            handler.next(error);
          },
        ),
      );
    } else if (config.auth?.onTokenExpired != null) {
      // Just notify on 401, no refresh attempt
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            if (error.response?.statusCode == 401) {
              config.auth!.onTokenExpired!();
            }
            handler.next(error);
          },
        ),
      );
    }

    // Caching interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) async {
          if (response.requestOptions.method == 'GET' &&
              response.statusCode == 200) {
            final cacheKey = _buildCacheKey(response.requestOptions);
            final duration =
                response.requestOptions.extra['cacheDuration'] as Duration?;
            await storageManager.setCache(
              cacheKey,
              response.data,
              duration: duration ?? config.defaultCacheConfig.duration,
            );
          }
          handler.next(response);
        },
      ),
    );
  }

  /// Updates the auth token at runtime.
  void updateToken(String? token) {
    _currentToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  String _buildCacheKey(RequestOptions options) {
    final queryString = options.queryParameters.isNotEmpty
        ? '?${options.queryParameters.entries.map((e) => "${e.key}=${e.value}").join("&")}'
        : '';
    return '${options.path}$queryString';
  }

  @override
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  }) async {
    final path = endpoint.buildPath(pathParams);
    final cacheKey = _buildCacheKeyFromParams(path, queryParams);

    // Request deduplication for GET requests
    if (endpoint.method == HttpMethod.get) {
      final inflightKey = 'GET:$cacheKey';
      if (_inflightRequests.containsKey(inflightKey)) {
        debugPrint('[FKernal] Deduplicating request: $inflightKey');
        return _inflightRequests[inflightKey] as Future<T>;
      }

      final future = _doRequest<T>(endpoint, path, queryParams, body, cacheKey);
      _inflightRequests[inflightKey] = future;

      try {
        final result = await future;
        return result;
      } finally {
        _inflightRequests.remove(inflightKey);
      }
    }

    return _doRequest<T>(endpoint, path, queryParams, body, cacheKey);
  }

  Future<T> _doRequest<T>(
    Endpoint endpoint,
    String path,
    Map<String, dynamic>? queryParams,
    dynamic body,
    String cacheKey,
  ) async {
    final methodString = endpoint.method.value;

    // Create or reuse cancel token for this endpoint
    final cancelToken = _cancelTokens.putIfAbsent(
      endpoint.id,
      () => CancelToken(),
    );

    final options = Options(
      method: methodString,
      extra: {
        if (endpoint.cacheConfig != null)
          'cacheDuration': endpoint.cacheConfig!.duration,
      },
    );

    try {
      // Check cache first for GET requests
      if (endpoint.method == HttpMethod.get) {
        final cached = await storageManager.getCache(cacheKey);
        if (cached != null) {
          return endpoint.parser != null
              ? endpoint.parser!(cached) as T
              : cached as T;
        }
      }

      final response = await _dio.request<dynamic>(
        path,
        data: body is FKernalModel ? body.toJson() : body,
        queryParameters: {...endpoint.defaultQueryParams, ...?queryParams},
        options: options,
        cancelToken: cancelToken,
      );

      return endpoint.parser != null
          ? endpoint.parser!(response.data) as T
          : response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _buildCacheKeyFromParams(String path, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return path;
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    final query =
        sortedParams.entries.map((e) => "${e.key}=${e.value}").join("&");
    return "$path?$query";
  }

  @override
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  }) {
    throw UnimplementedError('watch() is not supported by ApiClient (REST)');
  }

  /// Comprehensive error mapping from DioException to FKernalError.
  FKernalError _handleDioError(DioException error) {
    // Handle cancellation
    if (error.type == DioExceptionType.cancel) {
      return FKernalError.cancelled(
        message: 'Request was cancelled',
        originalError: error,
      );
    }

    // Handle timeouts
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return FKernalError(
        type: FKernalErrorType.timeout,
        message: _getTimeoutMessage(error.type),
        originalError: error,
      );
    }

    // Handle connection errors
    if (error.type == DioExceptionType.connectionError) {
      return FKernalError.network(
        message: 'Connection failed. Please check your internet connection.',
        originalError: error,
      );
    }

    // Handle response errors with status codes
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final serverMessage = _extractServerMessage(responseData);

    switch (statusCode) {
      case 400:
        return FKernalError.validation(
          message: serverMessage ?? 'Invalid request',
          statusCode: 400,
          originalError: error,
          data: responseData is Map<String, dynamic> ? responseData : null,
        );
      case 401:
        return FKernalError.unauthorized(
          message: serverMessage ?? 'Authentication required',
          statusCode: 401,
          originalError: error,
        );
      case 403:
        return FKernalError.forbidden(
          message: serverMessage ?? 'Access denied',
          statusCode: 403,
          originalError: error,
        );
      case 404:
        return FKernalError.notFound(
          message: serverMessage ?? 'Resource not found',
          statusCode: 404,
          originalError: error,
        );
      case 409:
        return FKernalError.conflict(
          message: serverMessage ?? 'Resource conflict',
          statusCode: 409,
          originalError: error,
        );
      case 422:
        return FKernalError.validation(
          message: serverMessage ?? 'Validation failed',
          statusCode: 422,
          originalError: error,
          data: responseData is Map<String, dynamic> ? responseData : null,
        );
      case 429:
        return FKernalError.rateLimited(
          message:
              serverMessage ?? 'Too many requests. Please try again later.',
          statusCode: 429,
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return FKernalError.server(
          message: serverMessage ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return FKernalError.unknown(
          message:
              serverMessage ?? error.message ?? 'An unexpected error occurred',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  String _getTimeoutMessage(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending data.';
      case DioExceptionType.receiveTimeout:
        return 'Request timed out waiting for response.';
      default:
        return 'Request timed out.';
    }
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData == null) return null;
    if (responseData is Map) {
      // Common API response patterns
      return responseData['message'] as String? ??
          responseData['error'] as String? ??
          responseData['error_description'] as String?;
    }
    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }
    return null;
  }

  /// Cancels a specific endpoint's in-flight request.
  void cancelEndpoint(String endpointId) {
    final token = _cancelTokens[endpointId];
    if (token != null && !token.isCancelled) {
      token.cancel('Cancelled by user');
      _cancelTokens.remove(endpointId);
    }
  }

  @override
  void cancelAll() {
    for (final token in _cancelTokens.values) {
      if (!token.isCancelled) {
        token.cancel('All requests cancelled');
      }
    }
    _cancelTokens.clear();
    _inflightRequests.clear();
  }

  @override
  void dispose() {
    cancelAll();
    _dio.close();
  }
}
