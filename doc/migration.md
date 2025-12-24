# Migration Guide

## 1.3.0 (Universal State Management)

Version 1.3.0 introduces a major architectural shift to support universal state management, replacing the internal `provider` + `ValueNotifier` engine with a pluggable adapter system (defaulting to Riverpod) and removing the hard dependency on `package:provider`.

### Breaking Changes

#### 1. Removal of `package:provider` dependency

FKernal no longer exports or uses `provider`.

**Before:**
```dart
context.read<ThemeManager>();
context.watch<StateManager>();
```

**After:**
Use the new context extensions:
```dart
context.themeManager;
context.stateManager;
```

#### 2. `context.useResource` behavior change

`context.useResource` now returns a **snapshot** of the data and does NOT automatically rebuild the widget on changes. This allows for usage in callbacks or non-reactive contexts.

**Before:**
```dart
Widget build(BuildContext context) {
  final users = context.useResource<List<User>>('getUsers');
  return ListView(...); // Rebuilds automatically
}
```

**After:**
Use `FKernalBuilder` for reactive UI:
```dart
Widget build(BuildContext context) {
  return FKernalBuilder<List<User>>(
    resource: 'getUsers',
    builder: (context, users) => ListView(...),
  );
}
```

Or convert to a `ConsumerWidget` (Riverpod) or similar if using another state manager.

#### 3. `watchThemeManager` removed

Use `ListenableBuilder` or `AnimatedBuilder` to listen to theme changes.

**Before:**
```dart
final theme = context.watchThemeManager();
```

**After:**
```dart
ListenableBuilder(
  listenable: context.themeManager,
  builder: (context, _) {
    return MaterialApp(
      theme: context.themeManager.lightTheme,
      ...
    );
  },
);
```

### New Features

#### Universal Configuration

You can now use any state management solution (BLoC, GetX, etc.) as the core engine.

```dart
FKernalConfig(
  stateManagement: StateManagementType.bloc,
  stateAdapter: MyBlocAdapter(),
);
```

See [README.md](../README.md#universal-state-management) for details.
