import '../../core/interfaces.dart';
import 'local_datasource.dart';

/// Adapter that bridges [IStorageProvider] to [LocalDataSource].
///
/// This allows existing storage provider implementations to be used
/// as LocalDataSource without modification.
class StorageProviderAdapter implements LocalDataSource {
  final IStorageProvider _provider;

  /// TTL tracking for cache validity.
  final Map<String, DateTime> _expiryMap = {};

  /// Default TTL if none specified.
  final Duration defaultTtl;

  StorageProviderAdapter(
    this._provider, {
    this.defaultTtl = const Duration(minutes: 5),
  });

  @override
  Future<void> init() => _provider.init();

  @override
  Future<T?> get<T>(String key) async {
    final data = await _provider.get(key);
    if (data == null) return null;
    return data as T;
  }

  @override
  Future<void> put(String key, dynamic value) async {
    await _provider.put(key, value);
    _expiryMap[key] = DateTime.now().add(defaultTtl);
  }

  @override
  Future<void> delete(String key) async {
    await _provider.delete(key);
    _expiryMap.remove(key);
  }

  @override
  Future<void> clear() async {
    await _provider.clear();
    _expiryMap.clear();
  }

  @override
  Iterable<dynamic> get keys => _provider.keys;

  @override
  Future<bool> isValid(String key) async {
    final expiry = _expiryMap[key];
    if (expiry == null) return true; // No expiry set, assume valid
    return DateTime.now().isBefore(expiry);
  }

  @override
  Future<void> close() => _provider.close();
}
