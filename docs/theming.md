# Theming Deep Dive

FKernal's theming system is designed to provide a consistent design system with zero ongoing effort. It handles theme generation, mode switching, and persistence automatically.

## Configuration logic

The `ThemeManager` does not store hardcoded `ThemeData` objects. Instead, it generates them from a `ThemeConfig` source of truth.

```dart
const themeConfig = ThemeConfig(
  // Colors
  primaryColor: Color(0xFF6200EE),
  secondaryColor: Color(0xFF03DAC6),
  errorColor: Color(0xFFB00020),
  
  // Typography
  fontFamily: 'Roboto',
  
  // Shapes & Spacing
  borderRadius: 8.0,
  defaultPadding: 16.0,
  
  // System
  useMaterial3: true,
  defaultThemeMode: ThemeMode.system,
);
```

## Runtime Management

Access the `ThemeManager` via context:

```dart
final manager = context.themeManager;
```

### Properties
- `manager.lightTheme`: Generated ThemeData for light mode.
- `manager.darkTheme`: Generated ThemeData for dark mode.
- `manager.themeMode`: Current active mode (System, Light, Dark).
- `manager.isDarkMode`: Boolean helper.

### Actions
- `manager.toggleTheme()`: Cycles Light <-> Dark.
- `manager.setThemeMode(ThemeMode.dark)`: Explicit assignment.

## Persistence

The `ThemeManager` automatically persists the user's preference using `StorageManager`. When the app restarts, it restores the last used theme mode without any extra code.

## Customization

While `ThemeConfig` covers 90% of use cases (colors, shapes, type), you might need granular control over specific components.

You can modify the generated themes before passing them to `MaterialApp`, or create a wrapper that applies extra `copyWith` modifications.

```dart
ListenableBuilder(
  listenable: context.themeManager,
  builder: (context, _) {
    final light = context.themeManager.lightTheme.copyWith(
      // Custom overrides
      appBarTheme: AppBarTheme(centerTitle: true),
    );
    
    return MaterialApp(
      theme: light,
      ...
    );
  },
);
```
