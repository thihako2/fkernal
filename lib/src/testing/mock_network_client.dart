import 'dart:async';
import '../core/interfaces.dart';
import '../networking/endpoint.dart';

/// Mock implementation of [INetworkClient] for testing.
///
/// Use this to test your app without making real network requests:
///
/// ```dart
/// final mockClient = MockNetworkClient();
///
/// // Set up mock responses
/// mockClient.mockResponse('getUsers', [
///   {'id': 1, 'name': 'Test User'},
/// ]);
///
/// // Initialize FKernal with mock
/// await FKernal.init(
///   config: FKernalConfig(
///     baseUrl: 'https://mock.api',
///     networkClientOverride: mockClient,
///   ),
///   endpoints: endpoints,
/// );
/// ```
class MockNetworkClient implements INetworkClient {
  @override
  final String baseUrl;

  /// Map of endpoint ID to mock response data.
  final Map<String, dynamic> _mockResponses = {};

  /// Map of endpoint ID to mock error.
  final Map<String, Object> _mockErrors = {};

  /// Map of endpoint ID to mock stream data.
  final Map<String, StreamController<dynamic>> _mockStreams = {};

  /// List of all requests made for verification.
  final List<MockRequest> requests = [];

  /// Artificial delay to simulate network latency.
  Duration? latency;

  MockNetworkClient({this.baseUrl = 'https://mock.api', this.latency});

  /// Sets up a mock response for an endpoint.
  void mockResponse<T>(String endpointId, T data) {
    _mockResponses[endpointId] = data;
    _mockErrors.remove(endpointId);
  }

  /// Sets up a mock error for an endpoint.
  void mockError(String endpointId, Object error) {
    _mockErrors[endpointId] = error;
    _mockResponses.remove(endpointId);
  }

  /// Sets up a mock stream for an endpoint.
  StreamController<T> mockStream<T>(String endpointId) {
    final controller = StreamController<T>.broadcast();
    _mockStreams[endpointId] = controller;
    return controller;
  }

  /// Clears all mock responses and errors.
  void reset() {
    _mockResponses.clear();
    _mockErrors.clear();
    for (final stream in _mockStreams.values) {
      stream.close();
    }
    _mockStreams.clear();
    requests.clear();
  }

  /// Verifies that a specific endpoint was called.
  bool wasCalled(String endpointId) {
    return requests.any((r) => r.endpointId == endpointId);
  }

  /// Gets all requests made to a specific endpoint.
  List<MockRequest> getRequestsFor(String endpointId) {
    return requests.where((r) => r.endpointId == endpointId).toList();
  }

  @override
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  }) async {
    // Record the request
    requests.add(MockRequest(
      endpointId: endpoint.id,
      queryParams: queryParams,
      pathParams: pathParams,
      body: body,
      timestamp: DateTime.now(),
    ));

    // Simulate latency if set
    if (latency != null) {
      await Future.delayed(latency!);
    }

    // Check for mock error
    if (_mockErrors.containsKey(endpoint.id)) {
      throw _mockErrors[endpoint.id]!;
    }

    // Check for mock response
    if (_mockResponses.containsKey(endpoint.id)) {
      final response = _mockResponses[endpoint.id];
      return endpoint.parser != null
          ? endpoint.parser!(response) as T
          : response as T;
    }

    throw StateError('No mock response set for endpoint: ${endpoint.id}. '
        'Call mockResponse("${endpoint.id}", yourData) first.');
  }

  @override
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  }) {
    if (_mockStreams.containsKey(endpoint.id)) {
      return _mockStreams[endpoint.id]!.stream.map((data) {
        return endpoint.parser != null
            ? endpoint.parser!(data) as T
            : data as T;
      });
    }

    throw StateError('No mock stream set for endpoint: ${endpoint.id}. '
        'Call mockStream<T>("${endpoint.id}") first.');
  }

  @override
  void cancelAll() {}

  @override
  void dispose() {
    reset();
  }
}

/// Represents a recorded mock request.
class MockRequest {
  final String endpointId;
  final Map<String, dynamic>? queryParams;
  final Map<String, String>? pathParams;
  final dynamic body;
  final DateTime timestamp;

  MockRequest({
    required this.endpointId,
    this.queryParams,
    this.pathParams,
    this.body,
    required this.timestamp,
  });

  @override
  String toString() => 'MockRequest($endpointId, params: $queryParams, '
      'pathParams: $pathParams, body: $body)';
}
