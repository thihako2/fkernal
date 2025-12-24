import 'dart:async';
import 'package:flutter/foundation.dart';

import '../core/interfaces.dart';
import '../core/observability.dart';
import '../error/error_handler.dart';
import '../error/fkernal_error.dart';
import '../networking/endpoint.dart';
import '../networking/endpoint_registry.dart';
import '../storage/storage_manager.dart';
import 'resource_state.dart';

/// Central state manager for the application.
class StateManager extends ChangeNotifier {
  final INetworkClient networkClient;
  final EndpointRegistry endpointRegistry;
  final StorageManager storageManager;
  final ErrorHandler errorHandler;
  final List<KernelObserver> observers;

  /// State slices for each endpoint, keyed by endpoint ID + params hash.
  final Map<String, ValueNotifier<ResourceState<dynamic>>> _states = {};

  /// In-flight requests to prevent duplicate fetches.
  final Map<String, Future<void>> _pendingRequests = {};

  /// Active stream subscriptions for watch() calls.
  final Map<String, StreamSubscription> _subscriptions = {};

  StateManager({
    required this.networkClient,
    required this.endpointRegistry,
    required this.storageManager,
    required this.errorHandler,
    this.observers = const [],
  });

  void _notifyObservers(KernelEvent event) {
    for (final observer in observers) {
      observer.onEvent(event);
    }
  }

  /// Gets the notification handle for a specific resource state.
  ValueListenable<ResourceState<T>> getListenable<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    final key = _buildStateKey(endpointId, params, pathParams);
    if (!_states.containsKey(key)) {
      _states[key] = ValueNotifier<ResourceState<T>>(ResourceInitial<T>());
    }
    return _states[key]! as ValueListenable<ResourceState<T>>;
  }

  /// Gets the current state for an endpoint.
  ResourceState<T> getState<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    final key = _buildStateKey(endpointId, params, pathParams);
    return (_states[key]?.value as ResourceState<T>?) ?? ResourceInitial<T>();
  }

  /// Fetches data from an endpoint.
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
      final state = _states[key]!.value;
      if (state is ResourceData<T>) {
        return state.data;
      } else if (state is ResourceError<T>) {
        throw state.error;
      }
    }

    // Get previous data for optimistic updates
    final previousState = _states[key];
    final previousData = previousState?.value.dataOrNull as T?;

    if (previousState == null) {
      _states[key] = ValueNotifier<ResourceState<T>>(
          ResourceLoading<T>(previousData: previousData));
    } else {
      previousState.value = ResourceLoading<T>(previousData: previousData);
    }
    notifyListeners();

    _notifyObservers(KernelEvent(
      type: KernelEventType.requestStarted,
      resourceId: endpointId,
      message: 'Fetching resource...',
      data: {
        'params': params,
        'pathParams': pathParams,
        'forceRefresh': forceRefresh
      },
    ));

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
      final state = _states[key]!.value;
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
      final data = await networkClient.request<T>(
        endpoint,
        queryParams: params,
        pathParams: pathParams,
      );

      _states[key]!.value = ResourceData<T>(data: data);

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestCompleted,
        resourceId: endpoint.id,
        message: 'Resource fetched successfully',
      ));
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);

      errorHandler.handle(error);

      final previousData =
          (_states[key]!.value as ResourceLoading<T>?)?.previousData;
      _states[key]!.value =
          ResourceError<T>(error: error, previousData: previousData);
      notifyListeners();

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestError,
        resourceId: endpoint.id,
        message: 'Failed to fetch resource: ${error.message}',
        data: error,
      ));
    }
  }

  /// Watches an endpoint for real-time updates.
  void watch<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    final key = _buildStateKey(endpointId, params, pathParams);
    if (_subscriptions.containsKey(key)) return;

    final endpoint = endpointRegistry.get(endpointId);

    if (!_states.containsKey(key) || _states[key]!.value is ResourceInitial) {
      _states[key] = ValueNotifier<ResourceState<T>>(const ResourceLoading());
    }

    final subscription = networkClient
        .watch<T>(
      endpoint,
      queryParams: params,
      pathParams: pathParams,
    )
        .listen(
      (data) {
        if (!_states.containsKey(key)) {
          _states[key] =
              ValueNotifier<ResourceState<T>>(ResourceData<T>(data: data));
        } else {
          _states[key]!.value = ResourceData<T>(data: data);
        }
        notifyListeners();
      },
      onError: (e) {
        final error = e is FKernalError
            ? e
            : FKernalError.unknown(message: e.toString(), originalError: e);

        if (_states.containsKey(key)) {
          _states[key]!.value = ResourceError<T>(error: error);
        }
        notifyListeners();
      },
    );

    _subscriptions[key] = subscription;
  }

  /// Performs an action (mutation) on an endpoint.
  Future<T> performAction<T>(
    String endpointId, {
    dynamic payload,
    Map<String, String>? pathParams,
  }) async {
    final endpoint = endpointRegistry.get(endpointId);
    final key = _buildStateKey(endpointId, null, pathParams);

    if (!_states.containsKey(key)) {
      _states[key] = ValueNotifier<ResourceState<T>>(const ResourceInitial());
    }

    final previousData = _states[key]!.value.dataOrNull as T?;
    _states[key]!.value = ResourceLoading<T>(previousData: previousData);
    notifyListeners();

    _notifyObservers(KernelEvent(
      type: KernelEventType.actionStarted,
      resourceId: endpointId,
      message: 'Performing action...',
      data: payload,
    ));

    try {
      final data = await networkClient.request<T>(
        endpoint,
        pathParams: pathParams,
        body: payload,
      );

      _states[key]!.value = ResourceData<T>(data: data);

      _notifyObservers(KernelEvent(
        type: KernelEventType.actionCompleted,
        resourceId: endpointId,
        message: 'Action completed successfully',
      ));

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

      _states[key]!.value =
          ResourceError<T>(error: error, previousData: previousData);

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestError,
        resourceId: endpointId,
        message: 'Action failed: ${error.message}',
        data: error,
      ));

      throw error;
    }
  }

  /// Invalidates state for the given endpoint IDs.
  Future<void> _invalidateEndpoints(List<String> endpointIds) async {
    for (final id in endpointIds) {
      final keysToRemove =
          _states.keys.where((key) => key.startsWith('$id:')).toList();
      for (final key in keysToRemove) {
        _states[key]!.value = const ResourceInitial();
      }
      notifyListeners();

      // Invalidate in storage as well
      await storageManager.invalidateCache(id);
    }
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

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (final state in _states.values) {
      state.dispose();
    }
    super.dispose();
  }
}
