import 'endpoint.dart';

/// Registry for managing endpoint definitions.
///
/// Endpoints are registered during [FKernal.init] and can be looked up
/// by their unique ID throughout the app lifecycle.
class EndpointRegistry {
  final Map<String, Endpoint> _endpoints = {};

  /// Registers an endpoint.
  ///
  /// Throws if an endpoint with the same ID already exists.
  void register(Endpoint endpoint) {
    if (_endpoints.containsKey(endpoint.id)) {
      throw ArgumentError(
        'Endpoint with id "${endpoint.id}" already exists. '
        'Each endpoint must have a unique id.',
      );
    }
    _endpoints[endpoint.id] = endpoint;
  }

  /// Registers multiple endpoints.
  void registerAll(List<Endpoint> endpoints) {
    for (final endpoint in endpoints) {
      register(endpoint);
    }
  }

  /// Gets an endpoint by its ID.
  ///
  /// Throws if the endpoint is not found.
  Endpoint get(String id) {
    final endpoint = _endpoints[id];
    if (endpoint == null) {
      throw ArgumentError(
        'Endpoint "$id" not found. '
        'Make sure it is registered in your endpoints configuration.',
      );
    }
    return endpoint;
  }

  /// Gets an endpoint by ID, or null if not found.
  Endpoint? tryGet(String id) => _endpoints[id];

  /// Whether an endpoint with the given ID exists.
  bool contains(String id) => _endpoints.containsKey(id);

  /// All registered endpoint IDs.
  Iterable<String> get ids => _endpoints.keys;

  /// All registered endpoints.
  Iterable<Endpoint> get endpoints => _endpoints.values;

  /// Number of registered endpoints.
  int get length => _endpoints.length;

  /// Clears all registered endpoints.
  void clear() => _endpoints.clear();

  /// Gets all endpoints that should be invalidated when the given endpoint is called.
  List<Endpoint> getInvalidationTargets(String endpointId) {
    final endpoint = get(endpointId);
    return endpoint.invalidates
        .where((id) => contains(id))
        .map((id) => get(id))
        .toList();
  }
}
