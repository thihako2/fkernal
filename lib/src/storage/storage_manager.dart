import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/interfaces.dart';

/// Manages local storage, caching, and secure storage via swappable providers.
class StorageManager {
  final bool enableCache;
  final bool enableOffline;

  final IStorageProvider? cacheProvider;
  final IStorageProvider? dataProvider;
  final ISecureStorageProvider secureProvider;

  static const _cacheMetaKey = '_cache_meta';

  StorageManager({
    this.enableCache = true,
    this.enableOffline = false,
    this.cacheProvider,
    this.dataProvider,
    required this.secureProvider,
  });

  /// Initializes the storage providers.
  Future<void> init() async {
    if (enableCache && cacheProvider != null) {
      await cacheProvider!.init();
    }
    if (enableOffline && dataProvider != null) {
      await dataProvider!.init();
    }
  }

  // ============ Cache Methods ============

  Future<dynamic> getCache(String key) async {
    if (!enableCache || cacheProvider == null) return null;

    final meta = await _getCacheMeta(key);
    if (meta == null) return null;

    if (DateTime.now().isAfter(meta.expiresAt)) {
      await cacheProvider!.delete(key);
      await cacheProvider!.delete('$_cacheMetaKey:$key');
      return null;
    }

    return cacheProvider!.get(key);
  }

  Future<void> setCache(
    String key,
    dynamic value, {
    Duration duration = const Duration(minutes: 5),
  }) async {
    if (!enableCache || cacheProvider == null) return;

    await cacheProvider!.put(key, value);
    await cacheProvider!.put(
      '$_cacheMetaKey:$key',
      jsonEncode({
        'expiresAt': DateTime.now().add(duration).toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> invalidateCache(String pattern) async {
    if (!enableCache || cacheProvider == null) return;

    final keysToDelete = cacheProvider!.keys
        .where((key) => key.toString().contains(pattern))
        .toList();

    for (final key in keysToDelete) {
      await cacheProvider!.delete(key.toString());
      await cacheProvider!.delete('$_cacheMetaKey:${key.toString()}');
    }
  }

  /// Clears all cache entries for a specific endpoint (all parameter variants).
  ///
  /// ```dart
  /// // Clears cache for getUsers, getUsers?page=1, getUsers?search=foo, etc.
  /// await storageManager.clearEndpointCache('/users');
  /// ```
  Future<void> clearEndpointCache(String endpointPath) async {
    await invalidateCache(endpointPath);
  }

  /// Clears cache entries matching a wildcard pattern.
  ///
  /// ```dart
  /// // Clear all user-related cache
  /// await storageManager.invalidateCachePattern('/users*');
  /// ```
  Future<void> invalidateCachePattern(String pattern) async {
    if (!enableCache || cacheProvider == null) return;

    final regexPattern = pattern.replaceAll('*', '.*').replaceAll('?', '.?');
    final regex = RegExp(regexPattern);

    final keysToDelete = cacheProvider!.keys
        .where((key) => regex.hasMatch(key.toString()))
        .toList();

    for (final key in keysToDelete) {
      await cacheProvider!.delete(key.toString());
      await cacheProvider!.delete('$_cacheMetaKey:${key.toString()}');
    }
  }

  Future<void> clearCache() async {
    await cacheProvider?.clear();
  }

  Future<_CacheMeta?> _getCacheMeta(String key) async {
    final metaJson = await cacheProvider?.get('$_cacheMetaKey:$key');
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

  Future<String?> getSecure(String key) => secureProvider.read(key);
  Future<void> setSecure(String key, String value) =>
      secureProvider.write(key, value);
  Future<void> deleteSecure(String key) => secureProvider.delete(key);
  Future<void> clearSecure() => secureProvider.deleteAll();

  // ============ Persistent Data Methods ============

  Future<dynamic> getData(String key) async {
    if (!enableOffline || dataProvider == null) return null;
    return dataProvider!.get(key);
  }

  Future<void> setData(String key, dynamic value) async {
    if (!enableOffline || dataProvider == null) return;
    await dataProvider!.put(key, value);
  }

  Future<void> deleteData(String key) =>
      dataProvider?.delete(key) ?? Future.value();
  Future<void> clearData() => dataProvider?.clear() ?? Future.value();

  // ============ Lifecycle ============

  Future<void> dispose() async {
    await cacheProvider?.close();
    await dataProvider?.close();
  }
}

class _CacheMeta {
  final DateTime expiresAt;
  final DateTime createdAt;
  _CacheMeta({required this.expiresAt, required this.createdAt});
}
