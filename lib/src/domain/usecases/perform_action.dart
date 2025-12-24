import '../entities/endpoint_config.dart';
import '../repositories/resource_repository.dart';
import 'use_case.dart';

/// Parameters for performing an action (mutation).
class PerformActionParams {
  /// The endpoint to call.
  final Endpoint endpoint;

  /// The request body/payload.
  final dynamic body;

  /// Optional path parameters.
  final Map<String, String>? pathParams;

  const PerformActionParams({
    required this.endpoint,
    this.body,
    this.pathParams,
  });
}

/// Use case for performing actions (POST, PUT, DELETE).
///
/// This encapsulates mutation logic including cache invalidation
/// and error handling.
class PerformActionUseCase<T> implements UseCase<PerformActionParams, T> {
  final ResourceRepository _repository;

  PerformActionUseCase(this._repository);

  @override
  Future<Result<T>> call(PerformActionParams params) async {
    final result = await _repository.mutate<T>(
      params.endpoint,
      body: params.body,
      pathParams: params.pathParams,
    );

    // Invalidate related caches on success
    if (result.isSuccess && params.endpoint.invalidates.isNotEmpty) {
      await _repository.invalidate(params.endpoint.invalidates);
    }

    return result;
  }
}
