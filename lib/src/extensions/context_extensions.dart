import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/fkernal_app.dart';
import '../core/fkernal_config.dart';
import '../error/error_handler.dart';
import '../networking/api_client.dart';
import '../networking/endpoint_registry.dart';
import '../state/state_manager.dart';
import '../storage/storage_manager.dart';
import '../state/local_slice.dart';
import '../theme/theme_manager.dart';

/// Extension methods on BuildContext for accessing FKernal services.
extension FKernalContextExtensions on BuildContext {
  /// Gets the FKernal configuration.
  FKernalConfig get fkernalConfig => read<FKernalConfig>();

  /// Gets the FKernal instance.
  FKernal get fkernal => FKernal.instance;

  /// Gets the state manager.
  StateManager get stateManager => read<StateManager>();

  /// Watches the state manager for changes.
  StateManager watchStateManager() => watch<StateManager>();

  /// Gets the API client.
  ApiClient get apiClient => read<ApiClient>();

  /// Gets the storage manager.
  StorageManager get storageManager => read<StorageManager>();

  /// Gets the error handler.
  ErrorHandler get errorHandler => read<ErrorHandler>();

  /// Gets the theme manager.
  ThemeManager get themeManager => read<ThemeManager>();

  /// Watches the theme manager for changes.
  ThemeManager watchThemeManager() => watch<ThemeManager>();

  /// Gets the endpoint registry.
  EndpointRegistry get endpointRegistry => read<EndpointRegistry>();

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

  /// Performs an action on an endpoint.
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
