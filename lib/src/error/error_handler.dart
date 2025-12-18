import 'package:flutter/foundation.dart';

import '../core/environment.dart';
import 'fkernal_error.dart';

/// Callback for error handling.
typedef ErrorCallback = void Function(FKernalError error);

/// Centralized error handler for the framework.
///
/// Captures errors from all layers and provides:
/// - Environment-aware logging
/// - Error categorization
/// - Custom error handlers
class ErrorHandler {
  final Environment environment;
  final List<ErrorCallback> _listeners = [];

  /// The last error that occurred.
  FKernalError? lastError;

  ErrorHandler({required this.environment});

  /// Handles an error.
  ///
  /// Logs the error based on environment and notifies listeners.
  void handle(FKernalError error) {
    lastError = error;

    // Log based on environment
    _log(error);

    // Notify listeners
    for (final listener in _listeners) {
      try {
        listener(error);
      } catch (e) {
        debugPrint('[FKernal Error] Error in error listener: $e');
      }
    }
  }

  /// Adds an error listener.
  void addListener(ErrorCallback callback) {
    _listeners.add(callback);
  }

  /// Removes an error listener.
  void removeListener(ErrorCallback callback) {
    _listeners.remove(callback);
  }

  /// Clears all listeners.
  void clearListeners() {
    _listeners.clear();
  }

  void _log(FKernalError error) {
    if (!environment.shouldLog) return;

    final buffer = StringBuffer();
    buffer.writeln('[FKernal Error] ${error.type.name.toUpperCase()}');
    buffer.writeln('  Message: ${error.message}');

    if (error.statusCode != null) {
      buffer.writeln('  Status Code: ${error.statusCode}');
    }

    if (error.originalError != null && environment.isDevelopment) {
      buffer.writeln('  Original Error: ${error.originalError}');
      if (error.originalError is Error) {
        buffer.writeln(
          '  Stack Trace: ${(error.originalError as Error).stackTrace}',
        );
      }
    }

    debugPrint(buffer.toString());
  }

  /// Wraps an async operation with error handling.
  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);
      handle(error);
      throw error;
    }
  }

  /// Wraps a sync operation with error handling.
  T guardSync<T>(T Function() operation) {
    try {
      return operation();
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);
      handle(error);
      throw error;
    }
  }
}
