import 'package:flutter/foundation.dart';

/// Abstract interface for local state management.
///
/// This allows any state management solution to be used for local
/// (non-API) state within FKernal widgets.
abstract class LocalStateAdapter<T> extends ChangeNotifier {
  /// Global factory for creating local state adapters.
  /// Modified by FKernal.init().
  static LocalStateAdapter<S> Function<S>(S initial)? defaultFactory;

  /// Gets the current state value.
  T get state;

  /// Updates the state with a new value.
  void setState(T newState);

  /// Updates the state using a function.
  void update(T Function(T current) updater) {
    setState(updater(state));
  }
}

/// Built-in ValueNotifier-based local state adapter.
///
/// This is the default local state implementation that works
/// without any external state management dependencies.
class ValueNotifierLocalState<T> extends LocalStateAdapter<T> {
  T _state;

  ValueNotifierLocalState(this._state);

  @override
  T get state => _state;

  @override
  void setState(T newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }
}

/// A local state adapter with history/undo support.
class HistoryLocalState<T> extends LocalStateAdapter<T> {
  T _state;
  final List<T> _history = [];
  final int maxHistoryLength;

  HistoryLocalState(T initialState, {this.maxHistoryLength = 50})
      : _state = initialState;

  @override
  T get state => _state;

  @override
  void setState(T newState) {
    _history.add(_state);
    if (_history.length > maxHistoryLength) {
      _history.removeAt(0);
    }
    _state = newState;
    notifyListeners();
  }

  /// Whether undo is available.
  bool get canUndo => _history.isNotEmpty;

  /// Undoes the last state change.
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

/// Toggle state adapter for boolean values.
class ToggleLocalState extends ValueNotifierLocalState<bool> {
  ToggleLocalState([super.initial = false]);

  /// Toggles the value.
  void toggle() => setState(!state);

  /// Convenience getter.
  bool get isOn => state;
}

/// Counter state adapter for integer values.
class CounterLocalState extends ValueNotifierLocalState<int> {
  final int? min;
  final int? max;

  CounterLocalState({int initial = 0, this.min, this.max}) : super(initial);

  /// Increments the counter.
  void increment([int amount = 1]) {
    var newValue = state + amount;
    if (max != null && newValue > max!) newValue = max!;
    setState(newValue);
  }

  /// Decrements the counter.
  void decrement([int amount = 1]) {
    var newValue = state - amount;
    if (min != null && newValue < min!) newValue = min!;
    setState(newValue);
  }

  /// Resets to zero or specified value.
  void reset([int value = 0]) => setState(value);
}

/// List state adapter for managing lists.
class ListLocalState<T> extends ValueNotifierLocalState<List<T>> {
  ListLocalState([List<T>? initial]) : super(initial ?? []);

  /// Adds an item.
  void add(T item) => setState([...state, item]);

  /// Adds multiple items.
  void addAll(Iterable<T> items) => setState([...state, ...items]);

  /// Removes an item.
  void remove(T item) => setState(state.where((e) => e != item).toList());

  /// Removes item at index.
  void removeAt(int index) {
    final newList = [...state];
    newList.removeAt(index);
    setState(newList);
  }

  /// Clears all items.
  void clear() => setState([]);

  /// Updates item at index.
  void updateAt(int index, T item) {
    final newList = [...state];
    newList[index] = item;
    setState(newList);
  }

  /// Updates items matching predicate.
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

/// Map state adapter for managing key-value pairs.
class MapLocalState<K, V> extends ValueNotifierLocalState<Map<K, V>> {
  MapLocalState([Map<K, V>? initial]) : super(initial ?? {});

  /// Gets a value by key.
  V? get(K key) => state[key];

  /// Operator [] for getting values.
  V? operator [](K key) => state[key];

  /// Sets a value.
  void set(K key, V value) => setState({...state, key: value});

  /// Removes a key.
  void remove(K key) {
    final newMap = Map<K, V>.from(state);
    newMap.remove(key);
    setState(newMap);
  }

  /// Clears all entries.
  void clear() => setState({});

  /// Whether the map contains a key.
  bool containsKey(K key) => state.containsKey(key);

  /// All keys.
  Iterable<K> get keys => state.keys;

  /// All values.
  Iterable<V> get values => state.values;

  /// Number of entries.
  int get length => state.length;
}
