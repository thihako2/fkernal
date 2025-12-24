import '../repositories/resource_repository.dart';

/// Base class for use cases.
///
/// Use cases represent application-specific business rules.
/// Each use case should have a single responsibility.
abstract class UseCase<Params, ResultType> {
  /// Executes the use case with the given parameters.
  Future<Result<ResultType>> call(Params params);
}

/// Use case that requires no parameters.
abstract class NoParamsUseCase<ResultType> {
  /// Executes the use case.
  Future<Result<ResultType>> call();
}

/// Use case that returns a stream.
abstract class StreamUseCase<Params, ResultType> {
  /// Executes the use case and returns a stream of results.
  Stream<ResultType> call(Params params);
}
