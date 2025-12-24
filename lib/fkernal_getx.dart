import 'dart:async';
import 'package:get/get.dart';
import 'fkernal.dart';

/// A GetX Controller that automatically syncs with an FKernal resource.
///
/// Users must add `get` to their dependencies to use this.
class ResourceController<T> extends GetxController {
  final String endpointId;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;

  final Rx<ResourceState<T>> _state =
      Rx<ResourceState<T>>(const ResourceInitial());
  StreamSubscription? _subscription;

  ResourceController(
    this.endpointId, {
    this.params,
    this.pathParams,
  }) {
    _state.value = FKernal.instance.stateManager.getState<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    );
    _init();
  }

  void _init() {
    _subscription = FKernal.instance.stateManager
        .stream<T>(endpointId, params: params, pathParams: pathParams)
        .listen((state) {
      _state.value = state;
    });
  }

  /// The current state as a reactive variable.
  ResourceState<T> get state => _state.value;

  /// Fetches or refreshes the data.
  Future<T> fetch({bool forceRefresh = false}) {
    return FKernal.instance.stateManager.fetch<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
      forceRefresh: forceRefresh,
    );
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
