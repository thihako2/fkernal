import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/resource_state.dart';
import '../state/state_manager.dart';
import 'auto_loading_widget.dart';
import 'auto_error_widget.dart';

/// Builder widget for consuming resource state from endpoints.
class FKernalBuilder<T> extends StatefulWidget {
  final String resource;
  final Map<String, dynamic>? params;
  final Map<String, String>? pathParams;
  final bool autoFetch;
  final Widget Function(BuildContext context, T data)? builder;
  final Widget Function(BuildContext context, ResourceState<T> state)?
      customBuilder;
  final Widget? loadingWidget;
  final Widget Function(
      BuildContext context, dynamic error, VoidCallback retry)? errorBuilder;
  final Widget? emptyWidget;
  final void Function(T data)? onData;
  final void Function(dynamic error)? onError;
  final bool watch;

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
    this.watch = false,
  }) : assert(builder != null || customBuilder != null);

  @override
  State<FKernalBuilder<T>> createState() => _FKernalBuilderState<T>();
}

class _FKernalBuilderState<T> extends State<FKernalBuilder<T>> {
  late StateManager _stateManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stateManager = context.read<StateManager>();
    if (widget.watch) {
      _watch();
    } else if (widget.autoFetch) {
      _fetch();
    }
  }

  @override
  void didUpdateWidget(FKernalBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resource != oldWidget.resource ||
        widget.params != oldWidget.params ||
        widget.pathParams != oldWidget.pathParams ||
        widget.watch != oldWidget.watch) {
      if (widget.watch) {
        _watch();
      } else {
        _fetch();
      }
    }
  }

  void _watch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stateManager.watch<T>(
        widget.resource,
        params: widget.params,
        pathParams: widget.pathParams,
      );
    });
  }

  void _fetch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _stateManager.fetch<T>(
        widget.resource,
        params: widget.params,
        pathParams: widget.pathParams,
      );
    });
  }

  void _retry() {
    _stateManager.refresh<T>(
      widget.resource,
      params: widget.params,
      pathParams: widget.pathParams,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the specific resource instead of the whole StateManager
    return ValueListenableBuilder<ResourceState<T>>(
      valueListenable: _stateManager.getListenable<T>(
        widget.resource,
        params: widget.params,
        pathParams: widget.pathParams,
      ),
      builder: (context, state, child) {
        // Call callbacks
        if (state is ResourceData<T> && widget.onData != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onData!(state.data));
        }
        if (state is ResourceError<T> && widget.onError != null) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => widget.onError!(state.error));
        }

        if (widget.customBuilder != null) {
          return widget.customBuilder!(context, state);
        }

        return switch (state) {
          ResourceLoading() =>
            widget.loadingWidget ?? const AutoLoadingWidget(),
          ResourceData(:final data) => widget.builder!(context, data),
          ResourceError(:final error) => widget.errorBuilder != null
              ? widget.errorBuilder!(context, error, _retry)
              : AutoErrorWidget(error: error, onRetry: _retry),
          ResourceInitial() =>
            widget.loadingWidget ?? const AutoLoadingWidget(),
        };
      },
    );
  }
}
