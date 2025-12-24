import 'package:flutter/material.dart';

import '../core/fkernal_app.dart';
import '../core/fkernal_config.dart';
import '../error/error_handler.dart';
import '../networking/endpoint_registry.dart';
import '../state/state_manager.dart';
import '../storage/storage_manager.dart';
import '../state/resource_key.dart';
import '../state/resource_state.dart';
import '../state/local_slice.dart';
import '../theme/theme_manager.dart';
import '../core/interfaces.dart';

/// Extension methods on BuildContext for accessing FKernal services.
extension FKernalContextExtensions on BuildContext {
  /// Gets the FKernal configuration.
  FKernalConfig get fkernalConfig => FKernal.instance.config;

  /// Gets the FKernal instance.
  FKernal get fkernal => FKernal.instance;

  /// Gets the state manager.
  StateManager get stateManager => FKernal.instance.stateManager;

  /// Watches and returns the state for a resource.
  ///
  /// NOTE: With Riverpod migration, this extension method is no longer reactive
  /// on a standard BuildContext. Use [ConsumerWidget] and `ref.watch` instead.
  /// This method now just returns the current state snapshot.
  @Deprecated('Use ref.watch(resourceProvider(...)) in a ConsumerWidget')
  ResourceState<T> useResource<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return stateManager.getState<T>(endpointId,
        params: params, pathParams: pathParams);
  }

  /// Watches and returns the state for a resource using a type-safe key.
  @Deprecated('Use ref.watch(resourceProvider(...)) in a ConsumerWidget')
  ResourceState<T> useResourceKey<T>(
    ResourceKey<T> key, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return useResource<T>(key.id, params: params, pathParams: pathParams);
  }

  /// Returns a function to perform an action.
  Future<T> Function({dynamic payload, Map<String, String>? pathParams})
      useAction<T>(String endpointId) {
    return ({payload, pathParams}) => stateManager.performAction<T>(
          endpointId,
          payload: payload,
          pathParams: pathParams,
        );
  }

  /// Gets the network client.
  INetworkClient get networkClient => FKernal.instance.networkClient;

  /// Gets the storage manager.
  StorageManager get storageManager => FKernal.instance.storageManager;

  /// Gets the error handler.
  ErrorHandler get errorHandler => FKernal.instance.errorHandler;

  /// Gets the theme manager.
  ThemeManager get themeManager => FKernal.instance.themeManager;

  /// Gets the endpoint registry.
  EndpointRegistry get endpointRegistry => FKernal.instance.endpointRegistry;

  /// Fetches data from an endpoint.
  Future<T> fetchResource<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return stateManager.fetch<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    );
  }

  /// Performs an action (mutation) on an endpoint.
  Future<T> performAction<T>(
    String endpointId, {
    dynamic payload,
    Map<String, String>? pathParams,
  }) {
    return stateManager.performAction<T>(
      endpointId,
      payload: payload,
      pathParams: pathParams,
    );
  }

  /// Refreshes data for an endpoint.
  Future<T> refreshResource<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return stateManager.refresh<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    );
  }

  /// Gets the value of a local state slice.
  T localState<T>(String id) => fkernal.getLocalSlice<LocalSlice<T>>(id).state;

  /// Gets a local state slice object.
  LocalSlice<T> localSlice<T>(String id) =>
      fkernal.getLocalSlice<LocalSlice<T>>(id);

  /// Updates a local state slice.
  void updateLocal<T>(String id, T Function(T current) updater) {
    fkernal.getLocalSlice<LocalSlice<T>>(id).update(updater);
  }
}
