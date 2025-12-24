import 'dart:async';
import 'package:mobx/mobx.dart';
import 'fkernal.dart';

// part 'fkernal_mobx.g.dart';

/// A MobX Store that automatically syncs with an FKernal resource.
///
/// Users must add `mobx` to their dependencies to use this.
class ResourceStore<T> = _ResourceStoreBase<T> with _$ResourceStore;

abstract class _ResourceStoreBase<T> with Store {
  final String endpointId;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;

  @observable
  ResourceState<T> state = const ResourceInitial();

  StreamSubscription? _subscription;

  _ResourceStoreBase(
    this.endpointId, {
    this.params,
    this.pathParams,
  }) {
    state = FKernal.instance.stateManager.getState<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    );
    _init();
  }

  void _init() {
    _subscription = FKernal.instance.stateManager
        .stream<T>(endpointId, params: params, pathParams: pathParams)
        .listen((newState) {
      _updateState(newState);
    });
  }

  @action
  void _updateState(ResourceState<T> newState) {
    state = newState;
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

  void dispose() {
    _subscription?.cancel();
  }
}

// Minimal manual boilerplate since we can't run build_runner here easily for this bridge
mixin _$ResourceStore<T> on _ResourceStoreBase<T>, Store {
  late final _$stateAtom =
      Atom(name: '_ResourceStoreBase.state', context: context);

  @override
  ResourceState<T> get state {
    _$stateAtom.reportRead();
    return super.state;
  }

  @override
  set state(ResourceState<T> value) {
    _$stateAtom.reportWrite(value, super.state, () {
      super.state = value;
    });
  }

  late final _updateStateActionController = ActionController(
      name: '_ResourceStoreBase._updateState', context: context);

  @override
  void _updateState(ResourceState<T> newState) {
    final actionInfo = _updateStateActionController.startAction(
        name: '_ResourceStoreBase._updateState');
    try {
      return super._updateState(newState);
    } finally {
      _updateStateActionController.endAction(actionInfo);
    }
  }
}
