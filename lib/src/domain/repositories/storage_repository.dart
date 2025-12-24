/// Abstract repository for storage operations.
///
/// This interface defines the contract for local data persistence
/// including caching and secure storage.
abstract class StorageRepository {
  /// Initializes the storage.
  Future<void> init();

  /// Gets cached data for the given key.
  Future<T?> getCached<T>(String key);

  /// Caches data with the given key.
  Future<void> cache<T>(String key, T data, {Duration? ttl});

  /// Removes cached data for the given key.
  Future<void> removeCached(String key);

  /// Invalidates all cache entries matching the given prefix.
  Future<void> invalidateByPrefix(String prefix);

  /// Clears all cached data.
  Future<void> clearCache();

  /// Reads a secure value.
  Future<String?> readSecure(String key);

  /// Writes a secure value.
  Future<void> writeSecure(String key, String value);

  /// Deletes a secure value.
  Future<void> deleteSecure(String key);

  /// Deletes all secure values.
  Future<void> clearSecure();

  /// Disposes of resources.
  Future<void> dispose();
}
