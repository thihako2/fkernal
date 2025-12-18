import 'package:flutter/material.dart';

import '../error/fkernal_error.dart';

/// Default error widget shown when data fetching fails.
class AutoErrorWidget extends StatelessWidget {
  /// The error that occurred.
  final dynamic error;

  /// Callback to retry the failed operation.
  final VoidCallback? onRetry;

  /// Whether to show a compact version.
  final bool compact;

  /// Custom icon to show.
  final IconData? icon;

  const AutoErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.compact = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final errorMessage = _getErrorMessage();
    final errorIcon = icon ?? _getErrorIcon();
    final isRecoverable = _isRecoverable();

    if (compact) {
      return _buildCompact(context, errorMessage, errorIcon, isRecoverable);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(errorIcon, size: 48, color: colorScheme.error),
            ),
            const SizedBox(height: 24),
            Text(
              _getErrorTitle(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null && isRecoverable) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(
    BuildContext context,
    String message,
    IconData icon,
    bool isRecoverable,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          if (onRetry != null && isRecoverable)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: colorScheme.primary,
            ),
        ],
      ),
    );
  }

  String _getErrorMessage() {
    if (error is FKernalError) {
      return (error as FKernalError).message;
    }
    return error.toString();
  }

  String _getErrorTitle() {
    if (error is FKernalError) {
      switch ((error as FKernalError).type) {
        case FKernalErrorType.network:
          return 'Connection Error';
        case FKernalErrorType.server:
          return 'Server Error';
        case FKernalErrorType.unauthorized:
          return 'Session Expired';
        case FKernalErrorType.forbidden:
          return 'Access Denied';
        case FKernalErrorType.notFound:
          return 'Not Found';
        case FKernalErrorType.validation:
          return 'Invalid Data';
        case FKernalErrorType.rateLimited:
          return 'Too Many Requests';
        default:
          return 'Something Went Wrong';
      }
    }
    return 'Error';
  }

  IconData _getErrorIcon() {
    if (error is FKernalError) {
      switch ((error as FKernalError).type) {
        case FKernalErrorType.network:
          return Icons.wifi_off;
        case FKernalErrorType.server:
          return Icons.cloud_off;
        case FKernalErrorType.unauthorized:
          return Icons.lock_outline;
        case FKernalErrorType.forbidden:
          return Icons.block;
        case FKernalErrorType.notFound:
          return Icons.search_off;
        case FKernalErrorType.validation:
          return Icons.warning_amber;
        case FKernalErrorType.rateLimited:
          return Icons.speed;
        default:
          return Icons.error_outline;
      }
    }
    return Icons.error_outline;
  }

  bool _isRecoverable() {
    if (error is FKernalError) {
      return (error as FKernalError).isRecoverable;
    }
    return true;
  }
}

/// Empty state widget when no data is available.
class AutoEmptyWidget extends StatelessWidget {
  /// Title to display.
  final String title;

  /// Subtitle or description.
  final String? subtitle;

  /// Custom icon.
  final IconData icon;

  /// Action button text.
  final String? actionText;

  /// Action callback.
  final VoidCallback? onAction;

  const AutoEmptyWidget({
    super.key,
    this.title = 'No Data',
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}
