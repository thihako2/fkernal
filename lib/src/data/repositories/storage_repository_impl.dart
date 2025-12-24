import '../../core/interfaces.dart';
import '../../domain/repositories/storage_repository.dart';

/// Concrete implementation of [StorageRepository].
///
/// This implementation wraps the existing storage providers
/// (IStorageProvider and ISecureStorageProvider) to provide
/// a unified storage interface.
class StorageRepositoryImpl implements StorageRepository {
  final IStorageProvider _cacheProvider;
  final ISecureStorageProvider _secureProvider;

  /// Metadata storage for TTL tracking.
  final Map<String, DateTime> _expiryMap = {};

  StorageRepositoryImpl({
    required IStorageProvider cacheProvider,
    required ISecureStorageProvider secureProvider,
  })  : _cacheProvider = cacheProvider,
        _secureProvider = secureProvider;

  @override
  Future<void> init() async {
    await _cacheProvider.init();
  }

  @override
  Future<T?> getCached<T>(String key) async {
    // Check if expired
    final expiry = _expiryMap[key];
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      await removeCached(key);
      return null;
    }

    final data = await _cacheProvider.get(key);
    if (data == null) return null;
    return data as T;
  }

  @override
  Future<void> cache<T>(String key, T data, {Duration? ttl}) async {
    await _cacheProvider.put(key, data);

    if (ttl != null) {
      _expiryMap[key] = DateTime.now().add(ttl);
    }
  }

  @override
  Future<void> removeCached(String key) async {
    await _cacheProvider.delete(key);
    _expiryMap.remove(key);
  }

  @override
  Future<void> invalidateByPrefix(String prefix) async {
    final keysToDelete = _cacheProvider.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList();

    for (final key in keysToDelete) {
      await _cacheProvider.delete(key.toString());
      _expiryMap.remove(key.toString());
    }
  }

  @override
  Future<void> clearCache() async {
    await _cacheProvider.clear();
    _expiryMap.clear();
  }

  @override
  Future<String?> readSecure(String key) {
    return _secureProvider.read(key);
  }

  @override
  Future<void> writeSecure(String key, String value) {
    return _secureProvider.write(key, value);
  }

  @override
  Future<void> deleteSecure(String key) {
    return _secureProvider.delete(key);
  }

  @override
  Future<void> clearSecure() {
    return _secureProvider.deleteAll();
  }

  @override
  Future<void> dispose() async {
    await _cacheProvider.close();
    _expiryMap.clear();
  }
}
