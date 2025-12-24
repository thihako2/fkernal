import 'dart:async';
import '../entities/endpoint_config.dart';
import '../failure.dart';

/// Result type for repository operations.
///
/// Uses a simple Either-like pattern for error handling.
sealed class Result<T> {
  const Result();
}

/// Successful result containing data.
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Failed result containing an error.
class Failure<T> extends Result<T> {
  final FKernalError error;
  const Failure(this.error);
}

/// Extension methods for Result type.
extension ResultExtension<T> on Result<T> {
  /// Returns true if this is a Success.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a Failure.
  bool get isFailure => this is Failure<T>;

  /// Gets the data if Success, throws if Failure.
  T get data => (this as Success<T>).data;

  /// Gets the error if Failure, throws if Success.
  FKernalError get error => (this as Failure<T>).error;

  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T) mapper) {
    return switch (this) {
      Success(:final data) => Success(mapper(data)),
      Failure(:final error) => Failure(error),
    };
  }

  /// Folds the result to a single value.
  R fold<R>(R Function(FKernalError) onFailure, R Function(T) onSuccess) {
    return switch (this) {
      Success(:final data) => onSuccess(data),
      Failure(:final error) => onFailure(error),
    };
  }
}

/// Abstract repository for fetching and managing resources.
///
/// This interface defines the contract for data operations in the domain layer.
/// Implementations handle the actual data fetching, caching, and error handling.
abstract class ResourceRepository {
  /// Fetches a resource from the given endpoint.
  ///
  /// Returns a [Result] containing either the data or an error.
  Future<Result<T>> fetch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    bool forceRefresh = false,
  });

  /// Performs a mutation (POST, PUT, DELETE) on the given endpoint.
  ///
  /// Returns a [Result] containing either the response data or an error.
  Future<Result<T>> mutate<T>(
    Endpoint endpoint, {
    dynamic body,
    Map<String, String>? pathParams,
  });

  /// Watches a resource for real-time updates.
  ///
  /// Returns a stream of data changes.
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  });

  /// Invalidates cached data for the given endpoint IDs.
  Future<void> invalidate(List<String> endpointIds);

  /// Disposes of resources.
  void dispose();
}
