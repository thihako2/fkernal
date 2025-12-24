import '../core/interfaces.dart';

/// Mock implementation of [IStorageProvider] for testing.
///
/// Stores data in memory, making tests fast and isolated:
///
/// ```dart
/// final mockStorage = MockStorageProvider();
///
/// await FKernal.init(
///   config: FKernalConfig(
///     baseUrl: 'https://api.example.com',
///     cacheProviderOverride: mockStorage,
///   ),
///   endpoints: endpoints,
/// );
/// ```
class MockStorageProvider implements IStorageProvider {
  final Map<String, dynamic> _storage = {};
  bool _isInitialized = false;

  @override
  Future<void> init() async {
    _isInitialized = true;
  }

  @override
  Future<dynamic> get(String key) async {
    _ensureInitialized();
    return _storage[key];
  }

  @override
  Future<void> put(String key, dynamic value) async {
    _ensureInitialized();
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _ensureInitialized();
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    _storage.clear();
  }

  @override
  Iterable<dynamic> get keys => _storage.keys;

  @override
  Future<void> close() async {
    _storage.clear();
    _isInitialized = false;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError(
          'MockStorageProvider not initialized. Call init() first.');
    }
  }

  /// Gets all stored data (for test verification).
  Map<String, dynamic> get allData => Map.unmodifiable(_storage);

  /// Checks if a key exists.
  bool containsKey(String key) => _storage.containsKey(key);
}

/// Mock implementation of [ISecureStorageProvider] for testing.
///
/// Stores data in memory (not actually secure, but suitable for tests).
class MockSecureStorageProvider implements ISecureStorageProvider {
  final Map<String, String> _storage = {};

  @override
  Future<String?> read(String key) async {
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }

  /// Gets all stored data (for test verification).
  Map<String, String> get allData => Map.unmodifiable(_storage);

  /// Checks if a key exists.
  bool containsKey(String key) => _storage.containsKey(key);
}
