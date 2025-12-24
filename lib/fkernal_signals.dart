import 'dart:async';
import 'package:signals_flutter/signals_flutter.dart';
import 'fkernal.dart';

/// A Signal that reactively reflects an FKernal resource state.
///
/// Users must add `signals_flutter` to their dependencies to use this.
class ResourceSignal<T> {
  final String endpointId;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;

  late final Signal<ResourceState<T>> _signal;
  StreamSubscription? _subscription;

  ResourceSignal(
    this.endpointId, {
    this.params,
    this.pathParams,
  }) {
    _signal =
        signal<ResourceState<T>>(FKernal.instance.stateManager.getState<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    ));
    _init();
  }

  void _init() {
    _subscription = FKernal.instance.stateManager
        .stream<T>(endpointId, params: params, pathParams: pathParams)
        .listen((state) {
      _signal.value = state;
    });
  }

  /// The current state as a signal.
  ResourceState<T> get state => _signal.value;

  /// The signal instance for watching/effects.
  Signal<ResourceState<T>> get signalInstance => _signal;

  /// Fetches or refreshes the data.
  Future<T> fetch({bool forceRefresh = false}) {
    return FKernal.instance.stateManager.fetch<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
      forceRefresh: forceRefresh,
    );
  }

  void dispose() {
    _subscription?.cancel();
  }
}
