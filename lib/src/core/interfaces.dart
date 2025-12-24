import '../networking/endpoint.dart';

/// Interface for network clients (REST, GraphQL, gRPC).
abstract class INetworkClient {
  /// Base URL for the client.
  String get baseUrl;

  /// Executes a request for a given endpoint.
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  });

  /// Watches an endpoint for changes (Streams).
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  });

  /// Cancels all pending requests.
  void cancelAll();

  /// Disposes the client.
  void dispose();
}

/// Interface for storage providers (Hive, SQLite, etc.).
abstract class IStorageProvider {
  Future<void> init();
  Future<dynamic> get(String key);
  Future<void> put(String key, dynamic value);
  Future<void> delete(String key);
  Future<void> clear();
  Iterable<dynamic> get keys;
  Future<void> close();
}

/// Interface for secure storage.
abstract class ISecureStorageProvider {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}
