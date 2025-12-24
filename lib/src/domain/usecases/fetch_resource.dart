import '../entities/endpoint_config.dart';
import '../repositories/resource_repository.dart';
import 'use_case.dart';

/// Parameters for fetching a resource.
class FetchResourceParams {
  /// The endpoint to fetch from.
  final Endpoint endpoint;

  /// Optional query parameters.
  final Map<String, dynamic>? queryParams;

  /// Optional path parameters.
  final Map<String, String>? pathParams;

  /// Whether to bypass cache and fetch fresh data.
  final bool forceRefresh;

  const FetchResourceParams({
    required this.endpoint,
    this.queryParams,
    this.pathParams,
    this.forceRefresh = false,
  });
}

/// Use case for fetching a resource.
///
/// This encapsulates the business logic for data retrieval,
/// including caching strategy and error handling.
class FetchResourceUseCase<T> implements UseCase<FetchResourceParams, T> {
  final ResourceRepository _repository;

  FetchResourceUseCase(this._repository);

  @override
  Future<Result<T>> call(FetchResourceParams params) {
    return _repository.fetch<T>(
      params.endpoint,
      queryParams: params.queryParams,
      pathParams: params.pathParams,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// Parameters for watching a resource.
class WatchResourceParams {
  /// The endpoint to watch.
  final Endpoint endpoint;

  /// Optional query parameters.
  final Map<String, dynamic>? queryParams;

  /// Optional path parameters.
  final Map<String, String>? pathParams;

  const WatchResourceParams({
    required this.endpoint,
    this.queryParams,
    this.pathParams,
  });
}

/// Use case for watching a resource for real-time updates.
class WatchResourceUseCase<T> implements StreamUseCase<WatchResourceParams, T> {
  final ResourceRepository _repository;

  WatchResourceUseCase(this._repository);

  @override
  Stream<T> call(WatchResourceParams params) {
    return _repository.watch<T>(
      params.endpoint,
      queryParams: params.queryParams,
      pathParams: params.pathParams,
    );
  }
}
