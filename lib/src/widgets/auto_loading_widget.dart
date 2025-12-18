import 'package:flutter/material.dart';

/// Default loading widget shown during data fetching.
class AutoLoadingWidget extends StatelessWidget {
  /// The size of the loading indicator.
  final double size;

  /// Optional message to show below the indicator.
  final String? message;

  /// Whether to center the widget in available space.
  final bool center;

  const AutoLoadingWidget({
    super.key,
    this.size = 40,
    this.message,
    this.center = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    if (center) {
      return Center(child: content);
    }
    return content;
  }
}

/// Shimmer loading placeholder for lists.
class ShimmerLoading extends StatefulWidget {
  /// Number of shimmer items to show.
  final int itemCount;

  /// Height of each shimmer item.
  final double itemHeight;

  const ShimmerLoading({super.key, this.itemCount = 5, this.itemHeight = 80});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          itemBuilder: (context, index) => _buildShimmerItem(context),
        );
      },
    );
  }

  Widget _buildShimmerItem(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlightColor = Theme.of(context).colorScheme.surface;

    return Container(
      height: widget.itemHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [baseColor, highlightColor, baseColor],
          stops: [0.0, _controller.value, 1.0],
        ),
      ),
    );
  }
}
