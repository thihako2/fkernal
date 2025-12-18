import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/environment.dart';
import '../core/fkernal_config.dart';
import '../error/error_handler.dart';
import '../error/fkernal_error.dart';
import '../storage/storage_manager.dart';
import 'endpoint.dart';
import 'http_method.dart';

/// HTTP client wrapper providing a unified API for network requests.
///
/// Handles authentication, caching, error handling, and request/response
/// transformation automatically based on configuration.
class ApiClient {
  final String baseUrl;
  final FKernalConfig config;
  final StorageManager storageManager;
  final ErrorHandler errorHandler;

  late final Dio _dio;

  ApiClient({
    required this.baseUrl,
    required this.config,
    required this.storageManager,
    required this.errorHandler,
  }) {
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
    // Logging interceptor
    if (config.features.enableLogging && config.environment.shouldLog) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (log) => debugPrint('[FKernal API] $log'),
        ),
      );
    }

    // Auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth headers if configured
          if (config.auth != null) {
            options.headers.addAll(config.auth!.headers);
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token refresh on 401
          if (error.response?.statusCode == 401 &&
              config.auth?.onTokenRefresh != null) {
            try {
              final newToken = await config.auth!.onTokenRefresh!();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newToken';
                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              }
            } catch (e) {
              // Token refresh failed, continue with error
            }
          }
          handler.next(error);
        },
      ),
    );

    // Retry interceptor
    if (config.features.enableAutoRetry) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) async {
            if (_shouldRetry(error)) {
              final options = error.requestOptions;
              final retryCount = options.extra['retryCount'] ?? 0;

              if (retryCount < config.features.maxRetryAttempts) {
                options.extra['retryCount'] = retryCount + 1;
                await Future.delayed(
                  Duration(milliseconds: 1000 * ((retryCount as int) + 1)),
                );
                try {
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                } catch (e) {
                  return handler.next(error);
                }
              }
            }
            handler.next(error);
          },
        ),
      );
    }

    // Cache interceptor
    if (config.features.enableCache) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            if (options.method == 'GET') {
              final cacheKey = _buildCacheKey(options);
              final cached = await storageManager.getCache(cacheKey);
              if (cached != null) {
                _log('Cache hit for $cacheKey');
                return handler.resolve(
                  Response(
                    requestOptions: options,
                    data: cached,
                    statusCode: 200,
                    extra: {'fromCache': true},
                  ),
                );
              }
            }
            handler.next(options);
          },
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
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  String _buildCacheKey(RequestOptions options) {
    final queryString = options.queryParameters.isNotEmpty
        ? '?${options.queryParameters.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : '';
    return '${options.path}$queryString';
  }

  void _log(String message) {
    if (config.features.enableLogging && config.environment.shouldLog) {
      debugPrint('[FKernal API] $message');
    }
  }

  /// Executes a request for the given endpoint.
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  }) async {
    final path = endpoint.buildPath(pathParams);
    final options = Options(
      method: endpoint.method.value,
      headers: endpoint.headers.isNotEmpty ? endpoint.headers : null,
      extra: {
        if (endpoint.cacheConfig != null)
          'cacheDuration': endpoint.cacheConfig!.duration,
      },
    );

    final mergedQueryParams = {...endpoint.defaultQueryParams, ...?queryParams};

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters:
            mergedQueryParams.isNotEmpty ? mergedQueryParams : null,
        options: options,
      );

      if (endpoint.parser != null) {
        return endpoint.parser!(response.data) as T;
      }

      return response.data as T;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  FKernalError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return FKernalError.network(
          message: 'Connection timed out. Please try again.',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        return _handleResponseError(error);
      case DioExceptionType.cancel:
        return FKernalError.cancelled(
          message: 'Request was cancelled.',
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return FKernalError.network(
          message: 'No internet connection. Please check your network.',
          originalError: error,
        );
      default:
        return FKernalError.unknown(
          message: 'An unexpected error occurred.',
          originalError: error,
        );
    }
  }

  FKernalError _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'Request failed';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (data is Map && data['error'] != null) {
      message = data['error'].toString();
    }

    switch (statusCode) {
      case 400:
        return FKernalError.validation(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
      case 401:
        return FKernalError.unauthorized(
          message: 'Session expired. Please log in again.',
          statusCode: statusCode,
          originalError: error,
        );
      case 403:
        return FKernalError.forbidden(
          message: 'You do not have permission to perform this action.',
          statusCode: statusCode,
          originalError: error,
        );
      case 404:
        return FKernalError.notFound(
          message: 'The requested resource was not found.',
          statusCode: statusCode,
          originalError: error,
        );
      case 409:
        return FKernalError.conflict(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
      case 422:
        return FKernalError.validation(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
      case 429:
        return FKernalError.rateLimited(
          message: 'Too many requests. Please try again later.',
          statusCode: statusCode,
          originalError: error,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return FKernalError.server(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
          originalError: error,
        );
      default:
        return FKernalError.unknown(
          message: message,
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  /// Invalidates cache for the given endpoint IDs.
  Future<void> invalidateCache(List<String> endpointIds) async {
    for (final id in endpointIds) {
      await storageManager.invalidateCache(id);
    }
  }

  /// Clears all cached data.
  Future<void> clearCache() async {
    await storageManager.clearCache();
  }

  /// Disposes the client.
  void dispose() {
    _dio.close();
  }
}
