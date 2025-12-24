import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fkernal_config.dart';
import '../core/interfaces.dart';
import '../core/observability.dart';
import '../error/error_handler.dart';
import '../error/fkernal_error.dart';

import '../networking/endpoint_registry.dart';
import '../storage/storage_manager.dart';
import 'resource_state.dart';

// Key type for resource family: (endpointId, queryParams, pathParams)
typedef ResourceFamilyKey = (
  String,
  Map<String, dynamic>?,
  Map<String, String>?
);

// Defaults (will be overridden in ProviderScope)
final fkernalConfigProvider =
    Provider<FKernalConfig>((ref) => throw UnimplementedError());
final networkClientProvider =
    Provider<INetworkClient>((ref) => throw UnimplementedError());
final storageManagerProvider =
    Provider<StorageManager>((ref) => throw UnimplementedError());
final endpointRegistryProvider =
    Provider<EndpointRegistry>((ref) => throw UnimplementedError());
final errorHandlerProvider =
    Provider<ErrorHandler>((ref) => throw UnimplementedError());
final observersProvider = Provider<List<KernelObserver>>((ref) => []);

/// Family provider for all API resources.
final resourceProvider = StateNotifierProvider.family<ResourceNotifier,
    ResourceState, ResourceFamilyKey>(
  (ref, key) {
    return ResourceNotifier(
      ref,
      key.$1,
      params: key.$2,
      pathParams: key.$3,
    );
  },
);

class ResourceNotifier extends StateNotifier<ResourceState> {
  final Ref ref;
  final String endpointId;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;

  ResourceNotifier(
    this.ref,
    this.endpointId, {
    this.params,
    this.pathParams,
  }) : super(const ResourceInitial());

  Future<T> fetch<T>({bool forceRefresh = false}) async {
    final endpoint = ref.read(endpointRegistryProvider).get(endpointId);

    // Optimistic update
    final previousData = state.dataOrNull;
    final T? typedPreviousData = previousData is T ? previousData : null;

    state = ResourceLoading<T>(previousData: typedPreviousData);

    _notifyObservers(KernelEvent(
      type: KernelEventType.requestStarted,
      resourceId: endpointId,
      message: 'Fetching resource...',
      data: {'params': params, 'forceRefresh': forceRefresh},
    ));

    try {
      final network = ref.read(networkClientProvider);
      final data = await network.request<T>(
        endpoint,
        queryParams: params,
        pathParams: pathParams,
      );

      state = ResourceData<T>(data: data);

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestCompleted,
        resourceId: endpointId,
        message: 'Resource fetched successfully',
      ));

      return data;
    } catch (e) {
      final error = e is FKernalError
          ? e
          : FKernalError.unknown(message: e.toString(), originalError: e);

      ref.read(errorHandlerProvider).handle(error);

      state = ResourceError<T>(error: error, previousData: typedPreviousData);

      _notifyObservers(KernelEvent(
        type: KernelEventType.requestError,
        resourceId: endpointId,
        message: 'Failed to fetch resource: ${error.message}',
        data: error,
      ));

      throw error;
    }
  }

  void _notifyObservers(KernelEvent event) {
    for (final observer in ref.read(observersProvider)) {
      observer.onEvent(event);
    }
  }
}
