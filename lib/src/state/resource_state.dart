import '../error/fkernal_error.dart';

/// Represents the state of a resource fetched from an endpoint.
///
/// This is a sealed class that can be one of:
/// - [ResourceLoading]: Data is being fetched
/// - [ResourceData]: Data was successfully loaded
/// - [ResourceError]: An error occurred
///
/// Use pattern matching to handle all states:
///
/// ```dart
/// switch (state) {
///   case ResourceLoading():
///     return CircularProgressIndicator();
///   case ResourceData(:final data):
///     return UserList(users: data);
///   case ResourceError(:final error):
///     return ErrorWidget(error: error);
/// }
/// ```
sealed class ResourceState<T> {
  const ResourceState();

  /// Whether data is currently loading.
  bool get isLoading => this is ResourceLoading<T>;

  /// Whether data has been loaded successfully.
  bool get hasData => this is ResourceData<T>;

  /// Whether an error occurred.
  bool get hasError => this is ResourceError<T>;

  /// Gets the data if available, or null.
  T? get dataOrNull {
    if (this is ResourceData<T>) {
      return (this as ResourceData<T>).data;
    }
    return null;
  }

  /// Gets the error if present, or null.
  FKernalError? get errorOrNull {
    if (this is ResourceError<T>) {
      return (this as ResourceError<T>).error;
    }
    return null;
  }

  /// Maps the state to a value using the provided functions.
  R when<R>({
    required R Function() loading,
    required R Function(T data) onData,
    required R Function(FKernalError error) onError,
    R Function()? initial,
  }) {
    return switch (this) {
      ResourceInitial() => initial?.call() ?? loading(),
      ResourceLoading() => loading(),
      ResourceData(data: final d) => onData(d),
      ResourceError(error: final e) => onError(e),
    };
  }

  /// Maps the state, with optional handlers (returns null for unhandled cases).
  R? maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? onData,
    R Function(FKernalError error)? onError,
    R Function()? initial,
    R Function()? orElse,
  }) {
    return switch (this) {
      ResourceInitial() => initial?.call() ?? orElse?.call(),
      ResourceLoading() => loading?.call() ?? orElse?.call(),
      ResourceData(data: final d) => onData?.call(d) ?? orElse?.call(),
      ResourceError(error: final e) => onError?.call(e) ?? orElse?.call(),
    };
  }
}

/// Loading state - data is being fetched.
class ResourceLoading<T> extends ResourceState<T> {
  /// Optional previous data (for refresh scenarios).
  final T? previousData;

  const ResourceLoading({this.previousData});
}

/// Data state - data was successfully loaded.
class ResourceData<T> extends ResourceState<T> {
  /// The fetched data.
  final T data;

  /// Whether the data came from cache.
  final bool fromCache;

  /// When the data was fetched.
  final DateTime fetchedAt;

  ResourceData({
    required this.data,
    this.fromCache = false,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();
}

/// Error state - an error occurred while fetching.
class ResourceError<T> extends ResourceState<T> {
  /// The error that occurred.
  final FKernalError error;

  /// Optional previous data (allows showing stale data with error toast).
  final T? previousData;

  const ResourceError({required this.error, this.previousData});
}

/// Initial state - no fetch has been attempted.
class ResourceInitial<T> extends ResourceState<T> {
  const ResourceInitial();
}
