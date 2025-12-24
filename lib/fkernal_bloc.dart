import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'fkernal.dart';

/// A BLoC (Cubit) that automatically syncs with an FKernal resource.
///
/// Users must add `flutter_bloc` to their dependencies to use this.
abstract class ResourceCubit<T> extends Cubit<ResourceState<T>> {
  final String endpointId;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;

  StreamSubscription? _subscription;

  ResourceCubit(
    this.endpointId, {
    this.params,
    this.pathParams,
  }) : super(FKernal.instance.stateManager.getState<T>(
          endpointId,
          params: params,
          pathParams: pathParams,
        )) {
    _init();
  }

  void _init() {
    _subscription = FKernal.instance.stateManager
        .stream<T>(endpointId, params: params, pathParams: pathParams)
        .listen((state) {
      if (!isClosed) emit(state);
    });
  }

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
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
