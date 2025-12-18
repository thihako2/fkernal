import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'state_manager.dart';
import 'resource_state.dart';

/// Provides access to FKernal state management from the widget tree.
class FKernalProvider {
  /// Gets the [StateManager] from context.
  static StateManager of(BuildContext context) {
    return context.read<StateManager>();
  }

  /// Watches the [StateManager] for changes.
  static StateManager watch(BuildContext context) {
    return context.watch<StateManager>();
  }
}

/// A hook-like helper to fetch and subscribe to resource state.
///
/// Usage:
/// ```dart
/// final users = useResource<List<User>>(context, 'getUsers');
/// ```
ResourceState<T> useResource<T>(
  BuildContext context,
  String endpointId, {
  Map<String, dynamic>? params,
  Map<String, String>? pathParams,
  bool autoFetch = true,
}) {
  final stateManager = context.watch<StateManager>();
  final state = stateManager.getState<T>(
    endpointId,
    params: params,
    pathParams: pathParams,
  );

  // Auto-fetch if state is initial and autoFetch is true
  if (state is ResourceInitial<T> && autoFetch) {
    // Schedule fetch after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stateManager.fetch<T>(endpointId, params: params, pathParams: pathParams);
    });
  }

  return state;
}

/// Triggers an action on an endpoint.
///
/// Usage:
/// ```dart
/// await performAction(context, 'createUser', payload: userData);
/// ```
Future<T> performAction<T>(
  BuildContext context,
  String endpointId, {
  dynamic payload,
  Map<String, String>? pathParams,
}) {
  final stateManager = context.read<StateManager>();
  return stateManager.performAction<T>(
    endpointId,
    payload: payload,
    pathParams: pathParams,
  );
}

/// Refreshes data for an endpoint.
///
/// Usage:
/// ```dart
/// await refreshResource<List<User>>(context, 'getUsers');
/// ```
Future<T> refreshResource<T>(
  BuildContext context,
  String endpointId, {
  Map<String, dynamic>? params,
  Map<String, String>? pathParams,
}) {
  final stateManager = context.read<StateManager>();
  return stateManager.refresh<T>(
    endpointId,
    params: params,
    pathParams: pathParams,
  );
}
