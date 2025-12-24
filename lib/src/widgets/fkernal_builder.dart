import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fkernal_app.dart';
import '../state/resource_state.dart';
import '../state/providers.dart';
import 'auto_loading_widget.dart';
import 'auto_error_widget.dart';

/// Builder widget for consuming resource state from endpoints.
class FKernalBuilder<T> extends ConsumerStatefulWidget {
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
  }) : assert(builder != null || customBuilder != null);

  @override
  ConsumerState<FKernalBuilder<T>> createState() => _FKernalBuilderState<T>();
}

class _FKernalBuilderState<T> extends ConsumerState<FKernalBuilder<T>> {
  @override
  void initState() {
    super.initState();
    if (widget.autoFetch) {
      _fetchIfInitial();
    }
  }

  void _fetchIfInitial() {
    // We defer to next frame to ensure providers are ready or just run it.
    // With Riverpod, we can just read the notifier and call fetch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final key = (widget.resource, widget.params, widget.pathParams);
      // Check if already loaded to avoid redundant fetches if autoFetch is on
      // But resourceProvider defaults to Initial, so we usually want to fetch.
      // The notifier's logic handles deduplication.
      ref.read(resourceProvider(key).notifier).fetch<T>();
    });
  }

  void _retry() {
    final key = (widget.resource, widget.params, widget.pathParams);
    ref.read(resourceProvider(key).notifier).fetch<T>(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.resource, widget.params, widget.pathParams);
    final rawState = ref.watch(resourceProvider(key));

    // Handle type casting safely, especially for initial state which defaults to dynamic
    ResourceState<T> state;
    if (rawState is ResourceState<T>) {
      state = rawState;
    } else if (rawState is ResourceInitial) {
      // If untyped initial state, convert to typed initial state
      state = ResourceInitial<T>();
    } else {
      // For other states, we expect them to match T. If not, it's a usage error
      // (conflicting types for same resource), so we let the cast fail.
      state = rawState as ResourceState<T>;
    }

    // Handle side effects (callbacks)
    ref.listen(resourceProvider(key), (previous, next) {
      if (next is ResourceData<T> && widget.onData != null) {
        // Check if data actually changed or just refetched?
        // Riverpod might notify even if same object if not using equatable.
        // ResourceState is sealed, data equality depends on T.
        // We'll just call it.
        widget.onData!(next.data);
      } else if (next is ResourceError<T> && widget.onError != null) {
        widget.onError!(next.error);
      }
    });

    if (widget.customBuilder != null) {
      return widget.customBuilder!(context, state);
    }

    final globalUI = FKernal.instance.config.globalUIConfig;

    return switch (state) {
      ResourceLoading() => widget.loadingWidget ??
          globalUI.loadingBuilder?.call(context) ??
          const AutoLoadingWidget(),
      ResourceData(:final data) => widget.builder!(context, data),
      ResourceError(:final error) => widget.errorBuilder != null
          ? widget.errorBuilder!(context, error, _retry)
          : globalUI.errorBuilder?.call(context, error, _retry) ??
              AutoErrorWidget(error: error, onRetry: _retry),
      ResourceInitial() => widget.loadingWidget ??
          globalUI.loadingBuilder?.call(context) ??
          const AutoLoadingWidget(),
    };
  }
}
