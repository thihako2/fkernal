import 'package:flutter/foundation.dart';

import '../error/error_handler.dart';
import '../error/fkernal_error.dart';
import '../networking/api_client.dart';
import '../networking/endpoint.dart';
import '../networking/endpoint_registry.dart';
import '../storage/storage_manager.dart';
import 'resource_state.dart';

/// Central state manager for the application.
///
/// Automatically manages state slices for each endpoint and handles:
/// - Data fetching and caching
/// - Loading states
/// - Error states
/// - Cache invalidation on mutations
///
/// UI code uses [FKernalBuilder] or [StateManager] methods to interact with state.
class StateManager extends ChangeNotifier {
  final ApiClient apiClient;
  final EndpointRegistry endpointRegistry;
  final StorageManager storageManager;
  final ErrorHandler errorHandler;

  /// State slices for each endpoint, keyed by endpoint ID + params hash.
  final Map<String, ResourceState<dynamic>> _states = {};

  /// In-flight requests to prevent duplicate fetches.
  final Map<String, Future<void>> _pendingRequests = {};

  StateManager({
    required this.apiClient,
    required this.endpointRegistry,
    required this.storageManager,
    required this.errorHandler,
  });

  /// Gets the current state for an endpoint.
  ///
  /// Returns [ResourceInitial] if no fetch has been attempted.
  ResourceState<T> getState<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    final key = _buildStateKey(endpointId, params, pathParams);
    return (_states[key] as ResourceState<T>?) ?? ResourceInitial<T>();
  }

  /// Fetches data from an endpoint.
  ///
  /// This method:
  /// 1. Sets state to loading
  /// 2. Checks cache (if enabled)
  /// 3. Makes network request
  /// 4. Updates state with data or error
  /// 5. Notifies listeners
  ///
  /// Returns the fetched data, or throws on error.
  Future<T> fetch<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
    bool forceRefresh = false,
  }) async {
    final endpoint = endpointRegistry.get(endpointId);
    final key = _buildStateKey(endpointId, params, pathParams);

    // Deduplicate in-flight requests
    if (_pendingRequests.containsKey(key)) {
      await _pendingRequests[key];
      final state = _states[key];
      if (state is ResourceData<T>) {
        return state.data;
      } else if (state is ResourceError<T>) {
        throw state.error;
      }
    }

    // Get previous data for optimistic updates
    final previousData = _states[key]?.dataOrNull as T?;

    // Set loading state
    _states[key] = ResourceLoading<T>(previousData: previousData);
    notifyListeners();

    // Create the fetch future
    final fetchFuture = _doFetch<T>(
      endpoint,
      key,
      params: params,
      pathParams: pathParams,
      forceRefresh: forceRefresh,
    );

    _pendingRequests[key] = fetchFuture;

    try {
      await fetchFuture;
      final state = _states[key];
      if (state is ResourceData<T>) {
        return state.data;
      } else if (state is ResourceError<T>) {
        throw state.error;
      }
      throw FKernalError.unknown(message: 'Unexpected state after fetch');
    } finally {
      _pendingRequests.remove(key);
    }
  }

  Future<void> _doFetch<T>(
    Endpoint endpoint,
    String key, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
    bool forceRefresh = false,
  }) async {
    try {
      final data = await apiClient.request<T>(
        endpoint,
        queryParams: params,
        pathParams: pathParams,
      );

      _states[key] = ResourceData<T>(data: data);
      notifyListeners();
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);

      errorHandler.handle(error);

      final previousData = (_states[key] as ResourceLoading<T>?)?.previousData;
      _states[key] = ResourceError<T>(error: error, previousData: previousData);
      notifyListeners();
    }
  }

  /// Performs an action (mutation) on an endpoint.
  ///
  /// Actions are typically POST, PUT, PATCH, or DELETE requests.
  /// After a successful action, related caches are invalidated.
  Future<T> performAction<T>(
    String endpointId, {
    dynamic payload,
    Map<String, String>? pathParams,
  }) async {
    final endpoint = endpointRegistry.get(endpointId);
    final key = _buildStateKey(endpointId, null, pathParams);

    // Set loading state
    final previousData = _states[key]?.dataOrNull as T?;
    _states[key] = ResourceLoading<T>(previousData: previousData);
    notifyListeners();

    try {
      final data = await apiClient.request<T>(
        endpoint,
        pathParams: pathParams,
        body: payload,
      );

      _states[key] = ResourceData<T>(data: data);
      notifyListeners();

      // Invalidate related caches
      if (endpoint.invalidates.isNotEmpty) {
        await _invalidateEndpoints(endpoint.invalidates);
      }

      return data;
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);

      errorHandler.handle(error);

      _states[key] = ResourceError<T>(error: error, previousData: previousData);
      notifyListeners();

      throw error;
    }
  }

  /// Invalidates state for the given endpoint IDs.
  Future<void> _invalidateEndpoints(List<String> endpointIds) async {
    for (final id in endpointIds) {
      // Clear all states that start with this endpoint ID
      final keysToRemove = _states.keys
          .where((key) => key.startsWith('$id:'))
          .toList();
      for (final key in keysToRemove) {
        _states[key] = const ResourceInitial();
      }

      // Clear cache
      await apiClient.invalidateCache([id]);
    }
    notifyListeners();
  }

  /// Refreshes data for an endpoint.
  Future<T> refresh<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return fetch<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
      forceRefresh: true,
    );
  }

  /// Clears all state.
  void clear() {
    _states.clear();
    notifyListeners();
  }

  /// Clears state for a specific endpoint.
  void clearEndpoint(String endpointId) {
    final keysToRemove = _states.keys
        .where((key) => key.startsWith('$endpointId:'))
        .toList();
    for (final key in keysToRemove) {
      _states.remove(key);
    }
    notifyListeners();
  }

  String _buildStateKey(
    String endpointId,
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  ) {
    final paramHash =
        params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    final pathHash =
        pathParams?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$endpointId:$paramHash:$pathHash';
  }
}
