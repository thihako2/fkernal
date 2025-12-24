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
class ApiClient implements INetworkClient {
  @override
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
    if (config.features.enableLogging && config.environment.shouldLog) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (log) => debugPrint('[FKernal API] $log'),
        ),
      );
    }

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

    // Explicitly using the extension method value
    final methodString = endpoint.method.value;

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
        final cacheKey = _buildCacheKeyFromParams(path, queryParams);
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
    final query = params.entries.map((e) => "${e.key}=${e.value}").join("&");
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

  FKernalError _handleDioError(DioException error) {
    // Basic mapping for now, full mapping was previously shown
    return FKernalError.network(message: error.message ?? 'Network error');
  }

  @override
  void cancelAll() => _dio.close(force: true);

  @override
  void dispose() => _dio.close();
}
