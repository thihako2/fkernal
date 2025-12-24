import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/fkernal_app.dart';
import '../state/providers.dart';
import 'auto_loading_widget.dart';
import 'auto_error_widget.dart';

/// Optional pagination builder for infinite scroll lists.
class FKernalPaginatedBuilder<T> extends ConsumerStatefulWidget {
  /// The endpoint resource ID.
  final String resource;

  /// Number of items per page.
  final int pageSize;

  /// Query parameter name for page number.
  final String pageParam;

  /// Query parameter name for page size.
  final String limitParam;

  /// Fixed query params to include with each request.
  final Map<String, dynamic>? extraParams;

  /// Path params for the endpoint.
  final Map<String, String>? pathParams;

  /// Builder for the paginated list.
  final Widget Function(
    BuildContext context,
    List<T> items,
    bool hasMore,
    VoidCallback loadMore,
    bool isLoadingMore,
  ) builder;

  /// Widget to show when loading initial page.
  final Widget? loadingWidget;

  /// Widget to show on error.
  final Widget Function(BuildContext, dynamic error, VoidCallback retry)?
      errorBuilder;

  /// Widget to show when the list is empty.
  final Widget? emptyWidget;

  /// Called when items are loaded.
  final void Function(List<T> items)? onData;

  const FKernalPaginatedBuilder({
    super.key,
    required this.resource,
    required this.builder,
    this.pageSize = 20,
    this.pageParam = 'page',
    this.limitParam = 'limit',
    this.extraParams,
    this.pathParams,
    this.loadingWidget,
    this.errorBuilder,
    this.emptyWidget,
    this.onData,
  });

  @override
  ConsumerState<FKernalPaginatedBuilder<T>> createState() =>
      _FKernalPaginatedBuilderState<T>();
}

class _FKernalPaginatedBuilderState<T>
    extends ConsumerState<FKernalPaginatedBuilder<T>> {
  final List<T> _items = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadPage(_currentPage);
  }

  Future<void> _loadPage(int page) async {
    if (_isLoadingMore && page > 1) return;

    setState(() {
      if (page == 1) {
        _isInitialLoading = true;
        _error = null;
      } else {
        _isLoadingMore = true;
      }
    });

    try {
      final params = <String, dynamic>{
        widget.pageParam: page,
        widget.limitParam: widget.pageSize,
        ...?widget.extraParams,
      };

      final key = (widget.resource, params, widget.pathParams);

      // Imperatively fetch using the resource notifier
      final result =
          await ref.read(resourceProvider(key).notifier).fetch<List<T>>(
                forceRefresh: true,
              );

      if (!mounted) return;

      setState(() {
        if (page == 1) {
          _items.clear();
        }
        _items.addAll(result);
        _hasMore = result.length >= widget.pageSize;
        _currentPage = page;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });

      widget.onData?.call(_items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _loadMore() {
    if (_hasMore && !_isLoadingMore) {
      _loadPage(_currentPage + 1);
    }
  }

  void _retry() {
    _loadPage(_currentPage == 1 ? 1 : _currentPage);
  }

  /// Resets the list and reloads from page 1.
  void reset() {
    setState(() {
      _items.clear();
      _currentPage = 1;
      _hasMore = true;
    });
    _loadPage(1);
  }

  @override
  Widget build(BuildContext context) {
    final globalUI = FKernal.instance.config.globalUIConfig;

    // Initial loading state
    if (_isInitialLoading) {
      return widget.loadingWidget ??
          globalUI.loadingBuilder?.call(context) ??
          const AutoLoadingWidget();
    }

    // Error state (only for initial load)
    if (_error != null && _items.isEmpty) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _error, _retry);
      }
      if (globalUI.errorBuilder != null) {
        return globalUI.errorBuilder!(context, _error, _retry);
      }
      return AutoErrorWidget(error: _error, onRetry: _retry);
    }

    // Empty state
    if (_items.isEmpty) {
      return widget.emptyWidget ??
          globalUI.emptyBuilder?.call(context) ??
          const Center(child: Text('No items found'));
    }

    // Data state
    return widget.builder(
      context,
      List.unmodifiable(_items),
      _hasMore,
      _loadMore,
      _isLoadingMore,
    );
  }
}

/// A convenience widget for the load more button/indicator.
class FKernalLoadMoreIndicator extends StatelessWidget {
  final VoidCallback onLoadMore;
  final bool isLoading;
  final Widget? loadingIndicator;
  final Widget? button;

  const FKernalLoadMoreIndicator({
    super.key,
    required this.onLoadMore,
    required this.isLoading,
    this.loadingIndicator,
    this.button,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingIndicator ??
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
    }

    return button ??
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: TextButton(
              onPressed: onLoadMore,
              child: const Text('Load More'),
            ),
          ),
        );
  }
}
