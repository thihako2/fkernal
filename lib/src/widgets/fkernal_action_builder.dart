import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../error/fkernal_error.dart';
import '../state/resource_state.dart';
import '../state/state_manager.dart';

/// Builder widget for performing actions (mutations) on endpoints.
///
/// ```dart
/// FKernalActionBuilder<User>(
///   action: 'createUser',
///   builder: (context, perform, state) => ElevatedButton(
///     onPressed: state.isLoading ? null : () => perform({'name': 'John'}),
///     child: state.isLoading
///       ? CircularProgressIndicator()
///       : Text('Create User'),
///   ),
/// )
/// ```
class FKernalActionBuilder<T> extends StatefulWidget {
  /// The endpoint ID for the action.
  final String action;

  /// Path parameters for the request.
  final Map<String, String>? pathParams;

  /// Builder function that provides the perform callback and current state.
  final Widget Function(
    BuildContext context,
    Future<T> Function(dynamic payload) perform,
    ResourceState<T> state,
  ) builder;

  /// Callback when action completes successfully.
  final void Function(T result)? onSuccess;

  /// Callback when action fails.
  final void Function(dynamic error)? onError;

  /// Whether to show a snackbar on success.
  final bool showSuccessSnackbar;

  /// Success message for snackbar.
  final String? successMessage;

  /// Whether to show a snackbar on error.
  final bool showErrorSnackbar;

  const FKernalActionBuilder({
    super.key,
    required this.action,
    this.pathParams,
    required this.builder,
    this.onSuccess,
    this.onError,
    this.showSuccessSnackbar = false,
    this.successMessage,
    this.showErrorSnackbar = true,
  });

  @override
  State<FKernalActionBuilder<T>> createState() =>
      _FKernalActionBuilderState<T>();
}

class _FKernalActionBuilderState<T> extends State<FKernalActionBuilder<T>> {
  ResourceState<T> _state = const ResourceInitial();

  Future<T> _perform(dynamic payload) async {
    final stateManager = context.read<StateManager>();

    setState(() {
      _state = ResourceLoading<T>(previousData: _state.dataOrNull);
    });

    try {
      final result = await stateManager.performAction<T>(
        widget.action,
        payload: payload,
        pathParams: widget.pathParams,
      );

      setState(() {
        _state = ResourceData<T>(data: result);
      });

      if (widget.onSuccess != null) {
        widget.onSuccess!(result);
      }

      if (widget.showSuccessSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.successMessage ?? 'Action completed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      return result;
    } catch (e) {
      final fkernalError = e is FKernalError
          ? e
          : FKernalError.unknown(
              message: e.toString(),
              originalError: e,
            );

      setState(() {
        _state = ResourceError<T>(
          error: fkernalError,
          previousData: _state.dataOrNull,
        );
      });

      if (widget.onError != null) {
        widget.onError!(e);
      }

      if (widget.showErrorSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }

      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _perform, _state);
  }
}

/// Simplified action trigger that handles a single action.
///
/// ```dart
/// ActionButton<void>(
///   action: 'deleteUser',
///   pathParams: {'id': userId},
///   child: Text('Delete'),
///   onSuccess: (_) => Navigator.pop(context),
/// )
/// ```
class ActionButton<T> extends StatelessWidget {
  /// The endpoint ID for the action.
  final String action;

  /// The payload to send.
  final dynamic payload;

  /// Path parameters.
  final Map<String, String>? pathParams;

  /// Button child widget.
  final Widget child;

  /// Callback on success.
  final void Function(T result)? onSuccess;

  /// Callback on error.
  final void Function(dynamic error)? onError;

  /// Custom loading widget.
  final Widget? loadingWidget;

  const ActionButton({
    super.key,
    required this.action,
    this.payload,
    this.pathParams,
    required this.child,
    this.onSuccess,
    this.onError,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FKernalActionBuilder<T>(
      action: action,
      pathParams: pathParams,
      onSuccess: onSuccess,
      onError: onError,
      builder: (context, perform, state) => ElevatedButton(
        onPressed: state.isLoading ? null : () => perform(payload),
        child: state.isLoading
            ? loadingWidget ??
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
            : child,
      ),
    );
  }
}
