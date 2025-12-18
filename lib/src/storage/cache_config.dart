/// Cache configuration for endpoints.
class CacheConfig {
  /// How long to cache responses.
  final Duration duration;

  /// Whether to use stale-while-revalidate strategy.
  ///
  /// If true, cached data is returned immediately while fresh data
  /// is fetched in the background.
  final bool staleWhileRevalidate;

  /// Maximum cache size in bytes (0 = unlimited).
  final int maxSize;

  const CacheConfig({
    this.duration = const Duration(minutes: 5),
    this.staleWhileRevalidate = false,
    this.maxSize = 0,
  });

  /// No caching.
  static const none = CacheConfig(duration: Duration.zero);

  /// Short cache (1 minute).
  static const short = CacheConfig(duration: Duration(minutes: 1));

  /// Medium cache (5 minutes).
  static const medium = CacheConfig(duration: Duration(minutes: 5));

  /// Long cache (1 hour).
  static const long = CacheConfig(duration: Duration(hours: 1));

  /// Persistent cache (24 hours).
  static const persistent = CacheConfig(duration: Duration(hours: 24));

  /// Creates a copy with updated values.
  CacheConfig copyWith({
    Duration? duration,
    bool? staleWhileRevalidate,
    int? maxSize,
  }) {
    return CacheConfig(
      duration: duration ?? this.duration,
      staleWhileRevalidate: staleWhileRevalidate ?? this.staleWhileRevalidate,
      maxSize: maxSize ?? this.maxSize,
    );
  }
}
