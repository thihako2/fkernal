import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state_adapter.dart';
import '../resource_state.dart' as legacy;
import '../providers.dart';

/// Default state adapter using Riverpod.
///
/// This implementation wraps the existing Riverpod providers to
/// fulfill the StateAdapter contract.
class RiverpodAdapter implements ResourceStateAdapter {
  final ProviderContainer container;

  RiverpodAdapter(this.container);

  @override
  legacy.ResourceState<T>? getState<T>(String resourceId) {
    try {
      final key = (resourceId, null, null);
      return container.read(resourceProvider(key)) as legacy.ResourceState<T>;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<legacy.ResourceState<T>?> watchState<T>(String resourceId) {
    // For manual watching outside widgets
    throw UnimplementedError(
        'watchState not fully implemented for RiverpodAdapter outside widgets');
  }

  @override
  void setState<T>(String resourceId, legacy.ResourceState<T> value) {
    // No-op for derived state
  }

  @override
  void clearState(String resourceId) {
    final key = (resourceId, null, null);
    container.invalidate(resourceProvider(key));
  }

  @override
  void setLoading(String resourceId) {}

  @override
  void setSuccess<T>(String resourceId, T data) {}

  @override
  void setError(String resourceId, error) {}

  @override
  Future<void> refresh(String resourceId) async {
    final key = (resourceId, null, null);
    await container
        .read(resourceProvider(key).notifier)
        .fetch(forceRefresh: true);
  }

  @override
  void dispose() {
    container.dispose();
  }
}
