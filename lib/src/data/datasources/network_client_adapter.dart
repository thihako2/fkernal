import '../../core/interfaces.dart';
import '../../domain/entities/endpoint_config.dart';
import 'remote_datasource.dart';

/// Adapter that bridges [INetworkClient] to [RemoteDataSource].
///
/// This allows existing network client implementations (ApiClient, FirebaseNetworkClient)
/// to be used as RemoteDataSource without modification.
class NetworkClientAdapter implements RemoteDataSource {
  final INetworkClient _client;

  NetworkClientAdapter(this._client);

  @override
  String get baseUrl => _client.baseUrl;

  @override
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  }) {
    return _client.request<T>(
      endpoint,
      queryParams: queryParams,
      pathParams: pathParams,
      body: body,
    );
  }

  @override
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  }) {
    return _client.watch<T>(
      endpoint,
      queryParams: queryParams,
      pathParams: pathParams,
    );
  }

  @override
  void cancelAll() => _client.cancelAll();

  @override
  void dispose() => _client.dispose();
}
