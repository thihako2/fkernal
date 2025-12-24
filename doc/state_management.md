# Universal State Management Deep Dive

FKernal 1.3.0 introduced a **Universal State Management** architecture. This means the framework core is decoupled from the specific state library used to manage resources.

By default, FKernal uses an optimized internal engine based on **Riverpod**, but you can swap this out entirely or use bridges to work with BLoC, GetX, Signals, or MobX.

## The State Model

Regardless of the underlying engine, all data resources in FKernal follow a unified state model: `ResourceState<T>`.

```dart
sealed class ResourceState<T> {
  const ResourceState();
}

class ResourceInitial<T> extends ResourceState<T>;
class ResourceLoading<T> extends ResourceState<T>;
class ResourceData<T> extends ResourceState<T> {
  final T data;
  final bool isRefreshing; // True if fetching new data while showing old
}
class ResourceError<T> extends ResourceState<T> {
  final FKernalError error;
  final T? previousData; // Optimistic or previous data
}
```

This ensures predictable UI behavior across your entire app.

## Configuration

You choose your state engine during initialization:

```dart
FKernalConfig(
  // 1. Choose the type
  stateManagement: StateManagementType.riverpod, // or bloc, getx, etc.
  
  // 2. Provide the adapter (if not using Riverpod)
  stateAdapter: MyCustomAdapter(),
  
  // 3. Provide local state factory (optional)
  localStateFactory: <T>(initial) => ValueNotifierLocalState<T>(initial),
)
```

## Consuming State (`FKernalBuilder`)

The `FKernalBuilder` is the primary way to consume state. It automatically handles the `ResourceState` transitions for you.

```dart
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  
  // Optional: transform data before rendering
  // selector: (users) => users.where((u) => u.isActive).toList(),
  
  builder: (context, users) {
    return ListView.builder(itemCount: users.length, ...);
  },
  
  // Optional overrides
  loadingWidget: MySpinner(),
  errorBuilder: (context, error, retry) => MyErrorWidget(error),
)
```

## Hybrid Usage (Bridges)

If you prefer to use FKernal's networking but keep your existing state management solution in the UI layer, use the **Bridge Classes**.

### BLoC / Cubit
Import `package:fkernal/fkernal_bloc.dart`.

```dart
// Auto-fetches and exposes ResourceState
class UserCubit extends ResourceCubit<User> {
  UserCubit() : super('getUser');
  
  void refresh() => fetch(forceRefresh: true);
}
```

### Signals
Import `package:fkernal/fkernal_signals.dart`.

```dart
final userSignal = ResourceSignal<User>('getUser');

// In widget
Watch((context) {
  final state = userSignal.value;
  if (state is ResourceData) return Text(state.data.name);
  return Loading();
})
```

## Local State Slices

FKernal provides a simple way to manage local (ephemeral) UI state without boilerplate.

```dart
// 1. Define a slice
final counterSlice = LocalSlice<int>(initialState: 0);

// 2. Register it (optional, or use direct reference)
FKernal.registerLocalSlice('counter', counterSlice);

// 3. Use it
FKernalLocalBuilder<int>(
  slice: 'counter',
  builder: (context, count, slice) => Text('$count'),
);

// 4. Update it
context.updateLocal<int>('counter', (c) => c + 1);
```

### Undo/Redo
Local slices support history tracking out of the box:

```dart
final formSlice = LocalSlice<FormData>(
  initialState: FormData(),
  enableHistory: true,
);

// ...
if (formSlice.canUndo) formSlice.undo();
```
