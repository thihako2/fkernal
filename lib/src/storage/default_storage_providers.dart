import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/interfaces.dart';

/// Default Hive-based storage provider.
class HiveStorageProvider implements IStorageProvider {
  final String boxName;
  Box? _box;

  HiveStorageProvider(this.boxName);

  @override
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox(boxName);
    } else {
      _box = Hive.box(boxName);
    }
  }

  @override
  Future<dynamic> get(String key) async => _box?.get(key);

  @override
  Future<void> put(String key, dynamic value) async =>
      await _box?.put(key, value);

  @override
  Future<void> delete(String key) async => await _box?.delete(key);

  @override
  Future<void> clear() async => await _box?.clear();

  @override
  Iterable<dynamic> get keys => _box?.keys ?? [];

  @override
  Future<void> close() async => await _box?.close();
}

/// Default FlutterSecureStorage-based secure storage provider.
class DefaultSecureStorageProvider implements ISecureStorageProvider {
  final _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
