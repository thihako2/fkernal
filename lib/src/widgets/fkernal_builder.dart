import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/resource_state.dart';
import '../state/state_manager.dart';
import 'auto_loading_widget.dart';
import 'auto_error_widget.dart';

/// Builder widget for consuming resource state from endpoints.
///
/// Automatically handles loading, data, and error states:
///
/// ```dart
/// FKernalBuilder<List<User>>(
///   resource: 'getUsers',
///   builder: (context, data) => UserList(users: data),
/// )
/// ```
///
/// For more control, use [builder] instead of [onData]:
///
/// ```dart
/// FKernalBuilder<List<User>>(
///   resource: 'getUsers',
///   customBuilder: (context, state) => switch (state) {
///     ResourceLoading() => MyLoadingWidget(),
///     ResourceData(:final data) => UserList(users: data),
///     ResourceError(:final error) => MyErrorWidget(error),
///     ResourceInitial() => SizedBox(),
///   },
/// )
/// ```
class FKernalBuilder<T> extends StatefulWidget {
  /// The endpoint ID to fetch data from.
  final String resource;

  /// Query parameters for the request.
  final Map<String, dynamic>? params;

  /// Path parameters for the request.
  final Map<String, String>? pathParams;

  /// Whether to automatically fetch data on mount.
  final bool autoFetch;

  /// Builder for the data state.
  ///
  /// If provided, loading and error states are handled automatically.
  final Widget Function(BuildContext context, T data)? builder;

  /// Custom builder for full control over all states.
  final Widget Function(BuildContext context, ResourceState<T> state)?
  customBuilder;

  /// Custom loading widget.
  final Widget? loadingWidget;

  /// Custom error widget builder.
  final Widget Function(
    BuildContext context,
    dynamic error,
    VoidCallback retry,
  )?
  errorBuilder;

  /// Widget to show when there's no data.
  final Widget? emptyWidget;

  /// Callback when data is successfully loaded.
  final void Function(T data)? onData;

  /// Callback when an error occurs.
  final void Function(dynamic error)? onError;

  const FKernalBuilder({
    super.key,
    required this.resource,
    this.params,
    this.pathParams,
    this.autoFetch = true,
    this.builder,
    this.customBuilder,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.onData,
    this.onError,
  }) : assert(
         builder != null || customBuilder != null,
         'Either builder or customBuilder must be provided',
       );

  @override
  State<FKernalBuilder<T>> createState() => _FKernalBuilderState<T>();
}

class _FKernalBuilderState<T> extends State<FKernalBuilder<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      _fetch();
    }
  }

  @override
  void didUpdateWidget(FKernalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if resource or params changed
    if (widget.resource != oldWidget.resource ||
        widget.params != oldWidget.params ||
        widget.pathParams != oldWidget.pathParams) {
      _fetch();
    }
  }

  void _fetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stateManager = context.read<StateManager>();
      stateManager.fetch<T>(
        widget.resource,
        params: widget.params,
        pathParams: widget.pathParams,
      );
    });
  }

  void _retry() {
    final stateManager = context.read<StateManager>();
    stateManager.refresh<T>(
      widget.resource,
      params: widget.params,
      pathParams: widget.pathParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    final stateManager = context.watch<StateManager>();
    final state = stateManager.getState<T>(
      widget.resource,
      params: widget.params,
      pathParams: widget.pathParams,
    );

    // Call callbacks
    if (state is ResourceData<T> && widget.onData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onData!(state.data);
      });
    }
    if (state is ResourceError<T> && widget.onError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onError!(state.error);
      });
    }

    // Use custom builder if provided
    if (widget.customBuilder != null) {
      return widget.customBuilder!(context, state);
    }

    // Default state handling
    return switch (state) {
      ResourceLoading() => widget.loadingWidget ?? const AutoLoadingWidget(),
      ResourceData(:final data) => widget.builder!(context, data),
      ResourceError(:final error) =>
        widget.errorBuilder != null
            ? widget.errorBuilder!(context, error, _retry)
            : AutoErrorWidget(error: error, onRetry: _retry),
      ResourceInitial() => widget.loadingWidget ?? const AutoLoadingWidget(),
    };
  }
}
