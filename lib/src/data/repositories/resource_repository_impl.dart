import 'dart:async';
import '../../domain/entities/endpoint_config.dart';
import '../../domain/failure.dart';
import '../../domain/repositories/resource_repository.dart';
import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';

/// Concrete implementation of [ResourceRepository].
///
/// This implementation coordinates between remote and local data sources
/// to provide caching, offline support, and error handling.
class ResourceRepositoryImpl implements ResourceRepository {
  final RemoteDataSource _remoteDataSource;
  final LocalDataSource? _localDataSource;

  ResourceRepositoryImpl({
    required RemoteDataSource remoteDataSource,
    LocalDataSource? localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<T>> fetch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(endpoint.id, queryParams, pathParams);

    // Try cache first if not forcing refresh
    if (!forceRefresh && _localDataSource != null && endpoint.isCacheable) {
      try {
        final cached = await _localDataSource!.get<T>(cacheKey);
        if (cached != null && await _localDataSource!.isValid(cacheKey)) {
          return Success(cached);
        }
      } catch (_) {
        // Cache miss or error, proceed to remote
      }
    }

    // Fetch from remote
    try {
      final data = await _remoteDataSource.request<T>(
        endpoint,
        queryParams: queryParams,
        pathParams: pathParams,
      );

      // Cache the result if cacheable
      if (_localDataSource != null && endpoint.isCacheable) {
        await _localDataSource!.put(cacheKey, data);
      }

      return Success(data);
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);
      return Failure(error);
    }
  }

  @override
  Future<Result<T>> mutate<T>(
    Endpoint endpoint, {
    dynamic body,
    Map<String, String>? pathParams,
  }) async {
    try {
      final data = await _remoteDataSource.request<T>(
        endpoint,
        pathParams: pathParams,
        body: body,
      );
      return Success(data);
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);
      return Failure(error);
    }
  }

  @override
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  }) {
    return _remoteDataSource.watch<T>(
      endpoint,
      queryParams: queryParams,
      pathParams: pathParams,
    );
  }

  @override
  Future<void> invalidate(List<String> endpointIds) async {
    if (_localDataSource == null) return;

    for (final id in endpointIds) {
      // Delete all cache entries that start with this endpoint id
      final keysToDelete = _localDataSource!.keys
          .where((key) => key.toString().startsWith(id))
          .toList();

      for (final key in keysToDelete) {
        await _localDataSource!.delete(key.toString());
      }
    }
  }

  @override
  void dispose() {
    _remoteDataSource.dispose();
  }

  String _buildCacheKey(
    String endpointId,
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  ) {
    final parts = [endpointId];

    if (pathParams != null && pathParams.isNotEmpty) {
      parts.add(pathParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }

    if (queryParams != null && queryParams.isNotEmpty) {
      parts
          .add(queryParams.entries.map((e) => '${e.key}=${e.value}').join('&'));
    }

    return parts.join(':');
  }
}
