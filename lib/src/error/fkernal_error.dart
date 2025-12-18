/// Types of errors that can occur in the framework.
enum FKernalErrorType {
  /// Network connectivity error.
  network,

  /// Server returned an error response.
  server,

  /// Request timed out.
  timeout,

  /// Unauthorized (401).
  unauthorized,

  /// Forbidden (403).
  forbidden,

  /// Resource not found (404).
  notFound,

  /// Validation error (400, 422).
  validation,

  /// Conflict error (409).
  conflict,

  /// Rate limited (429).
  rateLimited,

  /// Request was cancelled.
  cancelled,

  /// Data parsing error.
  parsing,

  /// Storage error.
  storage,

  /// Unknown error.
  unknown,
}

/// Unified error type for the FKernal framework.
///
/// All errors throughout the framework are converted to this type,
/// making error handling consistent across the app.
class FKernalError implements Exception {
  /// The type of error.
  final FKernalErrorType type;

  /// Human-readable error message.
  final String message;

  /// HTTP status code, if applicable.
  final int? statusCode;

  /// The original error that caused this error.
  final Object? originalError;

  /// Additional data about the error.
  final Map<String, dynamic>? data;

  const FKernalError({
    required this.type,
    required this.message,
    this.statusCode,
    this.originalError,
    this.data,
  });

  /// Creates a network error.
  factory FKernalError.network({
    required String message,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.network,
      message: message,
      originalError: originalError,
    );
  }

  /// Creates a server error.
  factory FKernalError.server({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.server,
      message: message,
      statusCode: statusCode,
      originalError: originalError,
    );
  }

  /// Creates an unauthorized error.
  factory FKernalError.unauthorized({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.unauthorized,
      message: message,
      statusCode: statusCode ?? 401,
      originalError: originalError,
    );
  }

  /// Creates a forbidden error.
  factory FKernalError.forbidden({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.forbidden,
      message: message,
      statusCode: statusCode ?? 403,
      originalError: originalError,
    );
  }

  /// Creates a not found error.
  factory FKernalError.notFound({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.notFound,
      message: message,
      statusCode: statusCode ?? 404,
      originalError: originalError,
    );
  }

  /// Creates a validation error.
  factory FKernalError.validation({
    required String message,
    int? statusCode,
    Object? originalError,
    Map<String, dynamic>? data,
  }) {
    return FKernalError(
      type: FKernalErrorType.validation,
      message: message,
      statusCode: statusCode ?? 422,
      originalError: originalError,
      data: data,
    );
  }

  /// Creates a conflict error.
  factory FKernalError.conflict({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.conflict,
      message: message,
      statusCode: statusCode ?? 409,
      originalError: originalError,
    );
  }

  /// Creates a rate limited error.
  factory FKernalError.rateLimited({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.rateLimited,
      message: message,
      statusCode: statusCode ?? 429,
      originalError: originalError,
    );
  }

  /// Creates a cancelled error.
  factory FKernalError.cancelled({
    required String message,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.cancelled,
      message: message,
      originalError: originalError,
    );
  }

  /// Creates a parsing error.
  factory FKernalError.parsing({
    required String message,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.parsing,
      message: message,
      originalError: originalError,
    );
  }

  /// Creates a storage error.
  factory FKernalError.storage({
    required String message,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.storage,
      message: message,
      originalError: originalError,
    );
  }

  /// Creates an unknown error.
  factory FKernalError.unknown({
    required String message,
    int? statusCode,
    Object? originalError,
  }) {
    return FKernalError(
      type: FKernalErrorType.unknown,
      message: message,
      statusCode: statusCode,
      originalError: originalError,
    );
  }

  /// Whether this error is recoverable (can be retried).
  bool get isRecoverable {
    switch (type) {
      case FKernalErrorType.network:
      case FKernalErrorType.timeout:
      case FKernalErrorType.server:
      case FKernalErrorType.rateLimited:
        return true;
      default:
        return false;
    }
  }

  /// Whether this error requires authentication.
  bool get requiresAuth =>
      type == FKernalErrorType.unauthorized ||
      type == FKernalErrorType.forbidden;

  @override
  String toString() => 'FKernalError(${type.name}): $message';
}
