import '../resource_state.dart';
export '../resource_state.dart';

/// State management type selection.
///
/// Determines which state management solution FKernal uses internally.
/// Each option requires the corresponding package to be added as a dependency.
enum StateManagementType {
  /// Riverpod (default) - Requires flutter_riverpod
  riverpod,

  /// Bloc/Cubit - Requires flutter_bloc
  bloc,

  /// GetX - Requires get
  getx,

  /// MobX - Requires mobx and flutter_mobx
  mobx,

  /// Signals - Requires signals_flutter
  signals,

  /// Provider - Requires provider
  provider,

  /// None - Use FKernal's built-in minimal state (ValueNotifier-based)
  /// No external dependencies required
  none,
}

/// Abstract interface for state management adapters.
///
/// This allows FKernal to work with any state management solution
/// by implementing this interface.
abstract class StateAdapter {
  /// Gets the current state for a resource.
  ResourceState<T>? getState<T>(String resourceId);

  /// Watches state changes for a resource as a stream.
  Stream<ResourceState<T>?> watchState<T>(String resourceId);

  /// Updates the state for a resource.
  void setState<T>(String resourceId, ResourceState<T> value);

  /// Clears the state for a resource.
  void clearState(String resourceId);

  /// Disposes of resources.
  void dispose();
}

/// Abstract interface for managing resource states specifically.
///
/// Extends [StateAdapter] with resource-specific operations.
abstract class ResourceStateAdapter extends StateAdapter {
  /// Starts loading a resource.
  void setLoading(String resourceId);

  /// Sets a resource to success state with data.
  void setSuccess<T>(String resourceId, T data);

  /// Sets a resource to error state.
  void setError(String resourceId, dynamic error);

  /// Refreshes a resource (fetches fresh data).
  Future<void> refresh(String resourceId);
}
