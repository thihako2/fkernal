import '../../domain/entities/endpoint_config.dart';

/// Interface for remote data operations.
///
/// This abstracts the network layer, allowing different implementations
/// such as REST (Dio), GraphQL, Firebase, or gRPC.
abstract class RemoteDataSource {
  /// Base URL for the remote data source.
  String get baseUrl;

  /// Performs a request to the given endpoint.
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  });

  /// Watches an endpoint for real-time updates.
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  });

  /// Cancels all pending requests.
  void cancelAll();

  /// Disposes of resources.
  void dispose();
}
