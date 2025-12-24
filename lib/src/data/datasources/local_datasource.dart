/// Interface for local cache operations.
///
/// This abstracts the local storage layer for caching purposes.
abstract class LocalDataSource {
  /// Initializes the local data source.
  Future<void> init();

  /// Gets cached data for the given key.
  Future<T?> get<T>(String key);

  /// Puts data into cache with the given key.
  Future<void> put(String key, dynamic value);

  /// Deletes cached data for the given key.
  Future<void> delete(String key);

  /// Clears all cached data.
  Future<void> clear();

  /// Gets all cache keys.
  Iterable<dynamic> get keys;

  /// Checks if a cache entry is valid (not expired).
  Future<bool> isValid(String key);

  /// Closes the data source.
  Future<void> close();
}
