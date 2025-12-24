/// Types of kernel events for observability.
enum KernelEventType {
  requestStarted,
  requestCompleted,
  requestError,
  cacheHit,
  cacheMiss,
  stateChanged,
  actionStarted,
  actionCompleted,
}

/// A kernel event for devtools and logging.
class KernelEvent {
  final KernelEventType type;
  final String resourceId;
  final String message;
  final DateTime timestamp;
  final dynamic data;

  KernelEvent({
    required this.type,
    required this.resourceId,
    required this.message,
    this.data,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      '[${timestamp.toIso8601String()}] [$type] $resourceId: $message';
}

/// Base class for kernel observers.
abstract class KernelObserver {
  void onEvent(KernelEvent event);
}

/// Default logger observer.
class LoggingKernelObserver extends KernelObserver {
  @override
  void onEvent(KernelEvent event) {
    // ignore: avoid_print - This is intentional for logging/debugging
    // Production apps should use a custom observer
    assert(() {
      // ignore: avoid_print
      print(event.toString());
      return true;
    }());
  }
}
