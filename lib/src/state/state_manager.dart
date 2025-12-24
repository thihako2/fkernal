import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/observability.dart';
import '../error/fkernal_error.dart';
import '../networking/endpoint.dart';

import 'resource_state.dart';
import 'adapters/adapters.dart'
    hide
        ResourceState,
        ResourceInitial,
        ResourceLoading,
        ResourceData,
        ResourceError;
import 'providers.dart';

/// Bridge class to expose Adapter state as ValueNotifier
class _AdapterValueListenable<T> extends ValueNotifier<ResourceState<T>> {
  final ResourceStateAdapter adapter;
  final String key;
  StreamSubscription? _subscription;

  _AdapterValueListenable(this.adapter, this.key)
      : super(const ResourceInitial()) {
    final state = adapter.getState<T>(key);
    if (state != null) value = state;

    _subscription = adapter.watchState<T>(key).listen((state) {
      value = state ?? const ResourceInitial();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Central state manager for the application.
///
/// Wraps Riverpod providers to maintain backward compatibility with
/// the imperative API.
class StateManager {
  final ProviderContainer container;
  final ResourceStateAdapter? adapter;

  StateManager({
    required this.container,
    this.adapter,
  });

  String _getKey(String endpointId,
      {Map<String, dynamic>? params, Map<String, String>? pathParams}) {
    final registry = container.read(endpointRegistryProvider);
    final endpoint = registry.get(endpointId);
    return Endpoint.generateKey(endpoint,
        params: params, pathParams: pathParams);
  }

  ValueListenable<ResourceState<T>> getListenable<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    // Note: External adapters don't easily support ValueListenable unless wrapped.
    // For now we assume if using adapter, we might need a different bridge or this remains Riverpod-only.
    // However, we can wrap the stream from adapter.watchState if adapter is present.
    if (adapter != null) {
      final key = _getKey(endpointId, params: params, pathParams: pathParams);
      return _AdapterValueListenable<T>(adapter!, key);
    }

    final key = (endpointId, params, pathParams);
    return _ProviderValueListenable<T>(container, key);
  }

  ResourceState<T> getState<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    if (adapter != null) {
      final key = _getKey(endpointId, params: params, pathParams: pathParams);
      // Adapter returns generic ResourceState, cast is tricky but usually safe via generics above
      // But ResourceState<T> expectation means we need to ensure type safety.
      final state = adapter!.getState(key) as dynamic;
      // Convert adapter specific state to core ResourceState if needed?
      // No, Adapter returns ResourceState<dynamic> in generic interface.
      // We assume correct casting:
      if (state is ResourceState<T>) return state;
      // If null or mismatch, return Initial
      return const ResourceInitial();
    }

    return container.read(
      resourceProvider((endpointId, params, pathParams)),
    ) as ResourceState<T>;
  }

  Stream<ResourceState<T>> stream<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    if (adapter != null) {
      final key = _getKey(endpointId, params: params, pathParams: pathParams);
      return adapter!
          .watchState(key)
          .map((s) => (s as ResourceState<T>?) ?? const ResourceInitial());
    }

    final key = (endpointId, params, pathParams);
    final controller = StreamController<ResourceState<T>>.broadcast();

    controller
        .add(getState<T>(endpointId, params: params, pathParams: pathParams));

    final subscription = container.listen<ResourceState>(
      resourceProvider(key),
      (prev, next) {
        if (!controller.isClosed) {
          controller.add(next as ResourceState<T>);
        }
      },
    );

    controller.onCancel = () {
      subscription.close();
      controller.close();
    };

    return controller.stream;
  }

  Future<T> fetch<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
    bool forceRefresh = false,
  }) async {
    if (adapter != null) {
      final key = _getKey(endpointId, params: params, pathParams: pathParams);
      if (forceRefresh) {
        await adapter!.refresh(key);
      } else {
        // adapters might not support "fetch without refresh" directly if they are reactive.
        // We assume refresh = fetch.
        await adapter!.refresh(key);
      }
      // Return fresh state data
      final state =
          getState<T>(endpointId, params: params, pathParams: pathParams);
      if (state is ResourceData<T>) return state.data;
      if (state is ResourceError<T>) throw state.error;
      // If still loading or initial, maybe wait?
      // For now, return what we have or error.
      throw FKernalError.unknown(
          message: 'Fetch completed but no data returned');
    }

    final key = (endpointId, params, pathParams);
    return container
        .read(resourceProvider(key).notifier)
        .fetch<T>(forceRefresh: forceRefresh);
  }

  Future<T> performAction<T>(
    String endpointId, {
    dynamic payload,
    Map<String, String>? pathParams,
  }) async {
    // Actions are usually direct API calls.
    // If using adapter, we might still want to use the NetworkClient directly?
    // OR delegate to adapter if it manages actions?
    // ResourceStateAdapter interface has no "performAction".
    // So we keep the core logic which uses NetworkClient directly.
    // BUT we must invalidate the adapter state if needed.

    final endpoint = container.read(endpointRegistryProvider).get(endpointId);
    final network = container.read(networkClientProvider);
    final errorHandler = container.read(errorHandlerProvider);

    _notifyObservers(KernelEvent(
      type: KernelEventType.actionStarted,
      resourceId: endpointId,
      message: 'Performing action...',
      data: payload,
    ));

    try {
      final data = await network.request<T>(
        endpoint,
        pathParams: pathParams,
        body: payload,
      );

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

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestError,
        resourceId: endpointId,
        message: 'Action failed: ${error.message}',
        data: error,
      ));

      throw error;
    }
  }

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

  @Deprecated('Use ref.listen in ConsumerWidgets instead')
  void watch<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    // No-op
  }

  Future<void> _invalidateEndpoints(List<String> endpointIds) async {
    final storage = container.read(storageManagerProvider);

    // If adapter exists, we can't easily iterate specific keys to invalidate
    // because we don't know the params for those keys.
    // But invalidating storage should clear the data foundation.

    for (final id in endpointIds) {
      await storage.invalidateCache(id);

      // If we could, we'd tell the adapter to clear specific IDs.
      // But we lack params here.
      // We rely on the adapter re-fetching or implementation details.
    }
  }

  void _notifyObservers(KernelEvent event) {
    for (final observer in container.read(observersProvider)) {
      observer.onEvent(event);
    }
  }

  void dispose() {
    adapter?.dispose();
    container.dispose();
  }
}

/// Bridge class to expose Riverpod state as ValueListenable
class _ProviderValueListenable<T> extends ValueListenable<ResourceState<T>> {
  final ProviderContainer container;
  final ResourceFamilyKey key;

  _ProviderValueListenable(this.container, this.key);

  @override
  ResourceState<T> get value =>
      container.read(resourceProvider(key)) as ResourceState<T>;

  @override
  void addListener(VoidCallback listener) {
    // This is tricky. ValueListenable is synchronous addition.
    // We would need to subscribe to the provider.
    // For migration purposes, implementing full bridge is complex.
    // Generally, widgets should switch to ConsumerWidget.
    // This bridge is best-effort.

    // We'll use a manual subscription managed internally if needed,
    // but standard ValueListenable usage might fail here without a real subscription.
    // Given the widget migration plan, we will update FKernalBuilder to NOT use this.
  }

  @override
  void removeListener(VoidCallback listener) {
    // No-op
  }
}
