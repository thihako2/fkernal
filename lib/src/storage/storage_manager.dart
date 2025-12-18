import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages local storage, caching, and secure storage.
///
/// Provides a unified interface for:
/// - Response caching with TTL
/// - Secure token storage
/// - Offline data persistence
class StorageManager {
  final bool enableCache;
  final bool enableOffline;

  Box<dynamic>? _cacheBox;
  Box<dynamic>? _dataBox;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const _cacheBoxName = 'fkernal_cache';
  static const _dataBoxName = 'fkernal_data';
  static const _cacheMetaKey = '_cache_meta';

  StorageManager({this.enableCache = true, this.enableOffline = false});

  /// Initializes the storage system.
  Future<void> init() async {
    await Hive.initFlutter();

    if (enableCache) {
      _cacheBox = await Hive.openBox(_cacheBoxName);
    }

    if (enableOffline) {
      _dataBox = await Hive.openBox(_dataBoxName);
    }
  }

  // ============ Cache Methods ============

  /// Gets a cached value.
  Future<dynamic> getCache(String key) async {
    if (!enableCache || _cacheBox == null) return null;

    final meta = _getCacheMeta(key);
    if (meta == null) return null;

    // Check expiration
    if (DateTime.now().isAfter(meta.expiresAt)) {
      await _cacheBox!.delete(key);
      await _cacheBox!.delete('$_cacheMetaKey:$key');
      return null;
    }

    return _cacheBox!.get(key);
  }

  /// Sets a cached value with optional duration.
  Future<void> setCache(
    String key,
    dynamic value, {
    Duration duration = const Duration(minutes: 5),
  }) async {
    if (!enableCache || _cacheBox == null) return;

    await _cacheBox!.put(key, value);
    await _cacheBox!.put(
      '$_cacheMetaKey:$key',
      jsonEncode({
        'expiresAt': DateTime.now().add(duration).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Invalidates cache entries that match the given pattern.
  Future<void> invalidateCache(String pattern) async {
    if (!enableCache || _cacheBox == null) return;

    final keysToDelete = _cacheBox!.keys
        .where((key) => key.toString().contains(pattern))
        .toList();

    for (final key in keysToDelete) {
      await _cacheBox!.delete(key);
      await _cacheBox!.delete('$_cacheMetaKey:$key');
    }
  }

  /// Clears all cached data.
  Future<void> clearCache() async {
    if (_cacheBox != null) {
      await _cacheBox!.clear();
    }
  }

  _CacheMeta? _getCacheMeta(String key) {
    final metaJson = _cacheBox?.get('$_cacheMetaKey:$key');
    if (metaJson == null) return null;

    try {
      final map = jsonDecode(metaJson as String);
      return _CacheMeta(
        expiresAt: DateTime.parse(map['expiresAt']),
        createdAt: DateTime.parse(map['createdAt']),
      );
    } catch (e) {
      debugPrint('[FKernal Storage] Error parsing cache meta: $e');
      return null;
    }
  }

  // ============ Secure Storage Methods ============

  /// Gets a secure value.
  Future<String?> getSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('[FKernal Storage] Error reading secure storage: $e');
      return null;
    }
  }

  /// Sets a secure value.
  Future<void> setSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[FKernal Storage] Error writing secure storage: $e');
    }
  }

  /// Deletes a secure value.
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('[FKernal Storage] Error deleting secure storage: $e');
    }
  }

  /// Clears all secure storage.
  Future<void> clearSecure() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('[FKernal Storage] Error clearing secure storage: $e');
    }
  }

  // ============ Persistent Data Methods ============

  /// Gets a persisted value.
  Future<dynamic> getData(String key) async {
    if (!enableOffline || _dataBox == null) return null;
    return _dataBox!.get(key);
  }

  /// Sets a persisted value.
  Future<void> setData(String key, dynamic value) async {
    if (!enableOffline || _dataBox == null) return;
    await _dataBox!.put(key, value);
  }

  /// Deletes a persisted value.
  Future<void> deleteData(String key) async {
    if (_dataBox != null) {
      await _dataBox!.delete(key);
    }
  }

  /// Clears all persisted data.
  Future<void> clearData() async {
    if (_dataBox != null) {
      await _dataBox!.clear();
    }
  }

  // ============ Lifecycle ============

  /// Disposes all storage resources.
  Future<void> dispose() async {
    await _cacheBox?.close();
    await _dataBox?.close();
  }
}

class _CacheMeta {
  final DateTime expiresAt;
  final DateTime createdAt;

  _CacheMeta({required this.expiresAt, required this.createdAt});
}
