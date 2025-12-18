import 'package:flutter/foundation.dart';

/// A local state slice for managing non-API state within FKernal.
///
/// Use this for state that doesn't come from network calls, like:
/// - Calculator values
/// - Form inputs
/// - UI toggles
/// - Local counters
///
/// Example:
/// ```dart
/// // Define your state
/// class CalculatorState {
///   final String display;
///   final String expression;
///   final List<String> history;
///
///   CalculatorState({
///     this.display = '0',
///     this.expression = '',
///     this.history = const [],
///   });
///
///   CalculatorState copyWith({...}) => ...;
/// }
///
/// // Create a slice
/// final calculatorSlice = LocalSlice<CalculatorState>(
///   initialState: CalculatorState(),
/// );
///
/// // Register during init
/// FKernal.registerLocalSlice('calculator', calculatorSlice);
///
/// // Use in widgets
/// FKernalLocalBuilder<CalculatorState>(
///   slice: 'calculator',
///   builder: (context, state, update) => ...
/// )
/// ```
class LocalSlice<T> extends ChangeNotifier {
  T _state;
  final List<T> _history = [];
  final int maxHistoryLength;
  final bool enableHistory;

  LocalSlice({
    required T initialState,
    this.maxHistoryLength = 50,
    this.enableHistory = false,
  }) : _state = initialState;

  /// The current state value.
  T get state => _state;

  /// Updates the state with a new value.
  void setState(T newState) {
    if (enableHistory) {
      _history.add(_state);
      if (_history.length > maxHistoryLength) {
        _history.removeAt(0);
      }
    }
    _state = newState;
    notifyListeners();
  }

  /// Updates the state using a function that receives the current state.
  void update(T Function(T current) updater) {
    setState(updater(_state));
  }

  /// Resets to initial state (if you store it).
  void reset(T initialState) {
    _history.clear();
    _state = initialState;
    notifyListeners();
  }

  /// Whether undo is available.
  bool get canUndo => _history.isNotEmpty;

  /// Undoes the last state change (if history is enabled).
  void undo() {
    if (_history.isNotEmpty) {
      _state = _history.removeLast();
      notifyListeners();
    }
  }

  /// Clears history.
  void clearHistory() {
    _history.clear();
  }
}

/// A specialized local slice for simple value types.
class ValueSlice<T> extends LocalSlice<T> {
  ValueSlice(T initialValue) : super(initialState: initialValue);

  /// The current value.
  T get value => state;

  /// Sets the value.
  set value(T newValue) => setState(newValue);
}

/// A specialized local slice for lists.
class ListSlice<T> extends LocalSlice<List<T>> {
  ListSlice([List<T>? initialList]) : super(initialState: initialList ?? []);

  /// The current items.
  List<T> get items => state;

  /// Adds an item.
  void add(T item) {
    setState([...state, item]);
  }

  /// Adds multiple items.
  void addAll(Iterable<T> items) {
    setState([...state, ...items]);
  }

  /// Removes an item.
  void remove(T item) {
    setState(state.where((e) => e != item).toList());
  }

  /// Removes item at index.
  void removeAt(int index) {
    final newList = [...state];
    newList.removeAt(index);
    setState(newList);
  }

  /// Clears all items.
  void clear() {
    setState([]);
  }

  /// Updates item at index.
  void updateAt(int index, T item) {
    final newList = [...state];
    newList[index] = item;
    setState(newList);
  }

  /// Updates item matching predicate.
  void updateWhere(bool Function(T) test, T Function(T) updater) {
    setState(state.map((e) => test(e) ? updater(e) : e).toList());
  }

  /// Number of items.
  int get length => state.length;

  /// Whether the list is empty.
  bool get isEmpty => state.isEmpty;

  /// Whether the list is not empty.
  bool get isNotEmpty => state.isNotEmpty;
}

/// A specialized local slice for maps.
class MapSlice<K, V> extends LocalSlice<Map<K, V>> {
  MapSlice([Map<K, V>? initialMap]) : super(initialState: initialMap ?? {});

  /// Gets a value by key.
  V? get(K key) => state[key];

  /// Operator [] for getting values.
  V? operator [](K key) => state[key];

  /// Sets a value.
  void set(K key, V value) {
    setState({...state, key: value});
  }

  /// Removes a key.
  void remove(K key) {
    final newMap = Map<K, V>.from(state);
    newMap.remove(key);
    setState(newMap);
  }

  /// Clears all entries.
  void clear() {
    setState({});
  }

  /// Whether the map contains a key.
  bool containsKey(K key) => state.containsKey(key);

  /// All keys.
  Iterable<K> get keys => state.keys;

  /// All values.
  Iterable<V> get values => state.values;

  /// Number of entries.
  int get length => state.length;
}

/// A specialized slice for boolean toggles.
class ToggleSlice extends ValueSlice<bool> {
  ToggleSlice([bool initial = false]) : super(initial);

  /// Toggles the value.
  void toggle() => value = !value;

  /// Sets to true.
  void setTrue() => value = true;

  /// Sets to false.
  void setFalse() => value = false;
}

/// A specialized slice for counters.
class CounterSlice extends ValueSlice<int> {
  final int? min;
  final int? max;

  CounterSlice({
    int initial = 0,
    this.min,
    this.max,
  }) : super(initial);

  /// Increments the counter.
  void increment([int amount = 1]) {
    var newValue = value + amount;
    if (max != null && newValue > max!) newValue = max!;
    value = newValue;
  }

  /// Decrements the counter.
  void decrement([int amount = 1]) {
    var newValue = value - amount;
    if (min != null && newValue < min!) newValue = min!;
    value = newValue;
  }

  /// Resets to zero or specified value.
  void resetTo([int newValue = 0]) {
    value = newValue;
  }
}
