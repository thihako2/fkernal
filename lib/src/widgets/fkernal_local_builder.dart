import 'package:flutter/material.dart';

import '../state/local_slice.dart';
import '../core/fkernal_app.dart';

/// Builder widget for consuming local (non-API) state from FKernal.
///
/// Example:
/// ```dart
/// FKernalLocalBuilder<CalculatorState>(
///   slice: 'calculator',
///   create: () => CalculatorState(), // Lazy registration
///   builder: (context, state, update) => Column(
///     children: [
///       Text(state.display),
///       ElevatedButton(
///         onPressed: () => update((s) => s.copyWith(display: '0')),
///         child: Text('Clear'),
///       ),
///     ],
///   ),
/// )
/// ```
class FKernalLocalBuilder<T> extends StatefulWidget {
  /// The slice ID to listen to.
  final String slice;

  /// Optional builder to create the slice if it doesn't exist.
  final LocalSlice<T> Function()? create;

  /// Builder function that receives state and update function.
  final Widget Function(
    BuildContext context,
    T state,
    void Function(T Function(T) updater) update,
  ) builder;

  const FKernalLocalBuilder({
    super.key,
    required this.slice,
    this.create,
    required this.builder,
  });

  @override
  State<FKernalLocalBuilder<T>> createState() => _FKernalLocalBuilderState<T>();
}

class _FKernalLocalBuilderState<T> extends State<FKernalLocalBuilder<T>> {
  late LocalSlice<T> _localSlice;

  @override
  void initState() {
    super.initState();
    if (widget.create != null) {
      _localSlice = FKernal.instance.getOrRegisterLocalSlice<LocalSlice<T>>(
        widget.slice,
        widget.create!,
      );
    } else {
      _localSlice = FKernal.instance.getLocalSlice<LocalSlice<T>>(widget.slice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _localSlice,
      builder: (context, _) => widget.builder(
        context,
        _localSlice.state,
        _localSlice.update,
      ),
    );
  }
}

/// Builder for ValueSlice (simple single values).
class FKernalValueBuilder<T> extends StatefulWidget {
  final String slice;
  final ValueSlice<T> Function()? create;
  final Widget Function(
      BuildContext context, T value, void Function(T) setValue) builder;

  const FKernalValueBuilder({
    super.key,
    required this.slice,
    this.create,
    required this.builder,
  });

  @override
  State<FKernalValueBuilder<T>> createState() => _FKernalValueBuilderState<T>();
}

class _FKernalValueBuilderState<T> extends State<FKernalValueBuilder<T>> {
  late ValueSlice<T> _slice;

  @override
  void initState() {
    super.initState();
    if (widget.create != null) {
      _slice = FKernal.instance.getOrRegisterLocalSlice<ValueSlice<T>>(
        widget.slice,
        widget.create!,
      );
    } else {
      _slice = FKernal.instance.getLocalSlice<ValueSlice<T>>(widget.slice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _slice,
      builder: (context, _) => widget.builder(
        context,
        _slice.value,
        (v) => _slice.value = v,
      ),
    );
  }
}

/// Builder for ListSlice.
class FKernalListBuilder<T> extends StatefulWidget {
  final String slice;
  final ListSlice<T> Function()? create;
  final Widget Function(BuildContext context, List<T> items, ListSlice<T> slice)
      builder;

  const FKernalListBuilder({
    super.key,
    required this.slice,
    this.create,
    required this.builder,
  });

  @override
  State<FKernalListBuilder<T>> createState() => _FKernalListBuilderState<T>();
}

class _FKernalListBuilderState<T> extends State<FKernalListBuilder<T>> {
  late ListSlice<T> _slice;

  @override
  void initState() {
    super.initState();
    if (widget.create != null) {
      _slice = FKernal.instance.getOrRegisterLocalSlice<ListSlice<T>>(
        widget.slice,
        widget.create!,
      );
    } else {
      _slice = FKernal.instance.getLocalSlice<ListSlice<T>>(widget.slice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _slice,
      builder: (context, _) => widget.builder(context, _slice.items, _slice),
    );
  }
}

/// Builder for ToggleSlice (booleans).
class FKernalToggleBuilder extends StatefulWidget {
  final String slice;
  final ToggleSlice Function()? create;
  final Widget Function(BuildContext context, bool value, ToggleSlice toggle)
      builder;

  const FKernalToggleBuilder({
    super.key,
    required this.slice,
    this.create,
    required this.builder,
  });

  @override
  State<FKernalToggleBuilder> createState() => _FKernalToggleBuilderState();
}

class _FKernalToggleBuilderState extends State<FKernalToggleBuilder> {
  late ToggleSlice _slice;

  @override
  void initState() {
    super.initState();
    if (widget.create != null) {
      _slice = FKernal.instance.getOrRegisterLocalSlice<ToggleSlice>(
        widget.slice,
        widget.create!,
      );
    } else {
      _slice = FKernal.instance.getLocalSlice<ToggleSlice>(widget.slice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _slice,
      builder: (context, _) => widget.builder(context, _slice.value, _slice),
    );
  }
}

/// Builder for CounterSlice.
class FKernalCounterBuilder extends StatefulWidget {
  final String slice;
  final CounterSlice Function()? create;
  final Widget Function(BuildContext context, int value, CounterSlice counter)
      builder;

  const FKernalCounterBuilder({
    super.key,
    required this.slice,
    this.create,
    required this.builder,
  });

  @override
  State<FKernalCounterBuilder> createState() => _FKernalCounterBuilderState();
}

class _FKernalCounterBuilderState extends State<FKernalCounterBuilder> {
  late CounterSlice _slice;

  @override
  void initState() {
    super.initState();
    if (widget.create != null) {
      _slice = FKernal.instance.getOrRegisterLocalSlice<CounterSlice>(
        widget.slice,
        widget.create!,
      );
    } else {
      _slice = FKernal.instance.getLocalSlice<CounterSlice>(widget.slice);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _slice,
      builder: (context, _) => widget.builder(context, _slice.value, _slice),
    );
  }
}
