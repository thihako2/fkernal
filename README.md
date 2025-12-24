# FKernal 🚀

[![Pub Version](https://img.shields.io/pub/v/fkernal)](https://pub.dev/packages/fkernal)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)
[![Style: Very Good Analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)

**The Configuration-Driven Flutter Kernel** — Build production-grade Flutter apps in a fraction of the time.

FKernal eliminates boilerplate by providing a centralized orchestration layer for **Networking, State Management, Persistence, Error Recovery, and Design Systems**. Define your endpoints and theme tokens once — FKernal handles everything else automatically.

> 💡 **Philosophy**: Configuration over Implementation. If something can be declared in a config object, it should be.

---

## 📑 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Core Concepts](#-core-concepts)
- [Widgets Reference](#-widgets-reference)
- [Context Extensions](#-context-extensions)
- [Theming](#-theming)
- [Error Handling](#️-error-handling)
- [Models](#-models)
- [Caching Strategy](#-caching-strategy)
- [Extensibility](#-extensibility)
- [Advanced Patterns](#-advanced-patterns)
- [Best Practices](#-best-practices)
- [FAQ](#-faq)
- [Migration Guide](#-migration-guide)
- [License](#-license)
- [Contributing](#-contributing)

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🌐 **Declarative Networking** | Define endpoints as constants. No more repositories, clients, or interceptors. Supports REST out of the box with extension points for GraphQL/gRPC. |
| 🔄 **Automatic State Management** | Every endpoint gets a reactive state slice with Loading, Data, and Error states. Built on `ValueNotifier` for fine-grained, efficient updates. |
| 💾 **Smart Caching** | TTL-based caching with automatic invalidation on mutations. Supports Stale-While-Revalidate pattern. Backed by Hive for binary storage. |
| 🎨 **Theming System** | Define theme tokens once, apply everywhere with dynamic light/dark switching. Full Material 3 support with automatic persistence. |
| ⚠️ **Unified Error Handling** | All errors normalized into typed `FKernalError` objects with automatic retry logic, exponential backoff, and environment-aware logging. |
| 📦 **Local State Slices** | Manage UI state with Value, Toggle, Counter, List, and Map slices. Includes undo/redo support with history tracking. |
| 🔌 **Extensible Architecture** | Override network client, storage providers, and add observers. Implement `INetworkClient`, `IStorageProvider`, or `ISecureStorageProvider` for full customization. |
| 🔍 **Observability** | Built-in `KernelObserver` and `KernelEvent` systems for structured runtime monitoring, debugging, and analytics integration. |
| 🔥 **Optional Firebase** | Separated Firebase module for Firestore/Auth/Storage. Keeps core package light while providing deep integration when needed. |
| 🔐 **Type-Safe Resources** | Use `ResourceKey<T>` for compile-time type safety when accessing state. Catch typos at build time. |
| 🔄 **Token Refresh & Auth** | Opt-in 401 token refresh, dynamic token providers, and runtime auth controls. |
| 📑 **Pagination Support** | Built-in `FKernalPaginatedBuilder` for effortless infinite scrolling and list management. |
| 🧪 **First-Class Testing** | Comprehensive mocks for networking and storage included. |
| 🚀 **High Performance** | Automatic request deduplication and per-widget cancellation to save bandwidth and battery. |

---

## 📦 Installation

Add FKernal to your `pubspec.yaml`:

dependencies:
  fkernal: ^1.2.0
```

Then run:
```bash
flutter pub get
```

### Requirements

| Requirement | Minimum Version |
|-------------|-----------------|
| **Flutter** | 3.10.0+ |
| **Dart** | 3.0.0+ |
| **Platforms** | iOS, Android, Web, macOS, Windows, Linux |

### Optional Dependencies

For secure storage on mobile platforms (recommended for auth tokens):
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

For Firebase/Firestore integration, use the optional module:
```dart
import 'package:fkernal/fkernal_firebase.dart';
```

Then add these to your `pubspec.yaml`:
```yaml
dependencies:
  cloud_firestore: ^5.0.0
  firebase_auth: ^5.0.0
  firebase_storage: ^12.0.0
```

---

## 🚀 Quick Start

### 1. Initialize FKernal

```dart
import 'package:fkernal/fkernal.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FKernal.init(
    config: const FKernalConfig(
      baseUrl: 'https://api.example.com',
      environment: Environment.development,
      theme: ThemeConfig(
        primaryColor: Color(0xFF6366F1),
        useMaterial3: true,
      ),
    ),
    endpoints: [
      Endpoint(
        id: 'getUsers',
        path: '/users',
        parser: (json) => (json as List)
            .map((u) => User.fromJson(u))
            .toList(),
      ),
      Endpoint(
        id: 'createUser',
        path: '/users',
        method: HttpMethod.post,
        invalidates: ['getUsers'], // Auto-refresh users list
      ),
    ],
  );

  runApp(const MyApp());
}
```

### 2. Wrap Your App

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FKernalApp(
      child: Builder(
        builder: (context) {
          final theme = context.watchThemeManager();
          return MaterialApp(
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            themeMode: theme.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
```

### 3. Consume Data

```dart
class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FKernalBuilder<List<User>>(
        resource: 'getUsers',
        builder: (context, users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, i) => ListTile(title: Text(users[i].name)),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.performAction('createUser', 
          payload: {'name': 'New User'}),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

That's it! No BLoCs, no repositories, no API client setup.

---

## 📖 Core Concepts

### Configuration

`FKernalConfig` is the central hub for all framework behavior:

```dart
const config = FKernalConfig(
  baseUrl: 'https://api.example.com',
  environment: Environment.production,
  
  features: FeatureFlags(
    enableCache: true,
    enableAutoRetry: true,
    maxRetryAttempts: 3,
    enableLogging: false,
  ),
  
  defaultCacheConfig: CacheConfig(
    duration: Duration(minutes: 5),
  ),
  
  connectTimeout: 30000,
  receiveTimeout: 30000,
);
```

### Endpoints

Endpoints are immutable blueprints for your API layer:

```dart
Endpoint(
  id: 'getUser',              // Unique identifier
  path: '/users/{id}',        // Path with parameters
  method: HttpMethod.get,     // HTTP method
  cacheConfig: CacheConfig.medium,  // 5-minute TTL
  requiresAuth: true,         // Add auth headers
  invalidates: ['getUsers'],  // Clear on success
  parser: (json) => User.fromJson(json),
  description: 'Fetches a user by ID',
)
```

**Cache Presets:**
- `CacheConfig.none` - Always fetch fresh
- `CacheConfig.short` - 1 minute
- `CacheConfig.medium` - 5 minutes
- `CacheConfig.long` - 1 hour
- `CacheConfig.persistent` - 24 hours

### State Management

Every request is tracked as a `ResourceState<T>`:

```dart
// Pattern matching (recommended)
switch (state) {
  ResourceLoading() => CircularProgressIndicator(),
  ResourceData(:final data) => Text(data.name),
  ResourceError(:final error) => Text(error.message),
  _ => SizedBox(),
}
```

---

## 🧩 Widgets Reference

### FKernalBuilder

The primary widget for consuming API data:

```dart
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  params: {'limit': 10},           // Query parameters
  pathParams: {'orgId': '123'},    // Path parameters
  autoFetch: true,                 // Fetch on mount
  
  builder: (context, users) => ListView(...),
  
  loadingWidget: ShimmerLoading(), // Custom loading
  errorBuilder: (ctx, err, retry) => RetryButton(err, retry),
  emptyWidget: EmptyState(),
  
  onData: (users) => print('Got ${users.length} users'),
  onError: (error) => analytics.log(error),
)
```

### Local State Builders

For non-API state (forms, UI toggles, etc.):

```dart
// Complex state with history
FKernalLocalBuilder<CalculatorState>(
  slice: 'calculator',
  create: () => LocalSlice(initialState: CalculatorState()),
  builder: (context, state, update) => Column(
    children: [
      Text(state.display),
      ElevatedButton(
        onPressed: () => update((s) => s.copyWith(display: '0')),
        child: Text('Clear'),
      ),
    ],
  ),
)

// Simple toggle
FKernalToggleBuilder(
  slice: 'darkMode',
  create: () => ToggleSlice(false),
  builder: (context, value, toggle) => Switch(
    value: value,
    onChanged: (_) => toggle.toggle(),
  ),
)

// Counter with bounds
FKernalCounterBuilder(
  slice: 'quantity',
  create: () => CounterSlice(initial: 1, min: 1, max: 99),
  builder: (context, value, counter) => Row(
    children: [
      IconButton(onPressed: counter.decrement, icon: Icon(Icons.remove)),
      Text('$value'),
      IconButton(onPressed: counter.increment, icon: Icon(Icons.add)),
    ],
  ),
)

// List management
FKernalListBuilder<String>(
  slice: 'tags',
  create: () => ListSlice(['flutter', 'dart']),
  builder: (context, items, slice) => Wrap(
    children: [
      ...items.map((tag) => Chip(
        label: Text(tag),
        onDeleted: () => slice.remove(tag),
      )),
      ActionChip(
        label: Text('Add'),
        onPressed: () => slice.add('new-tag'),
      ),
    ],
  ),
)
```

### Built-in UI Widgets

```dart
// Loading indicator
AutoLoadingWidget(
  size: 40,
  message: 'Loading users...',
)

// Error with retry
AutoErrorWidget(
  error: FKernalError.network('Connection failed'),
  onRetry: () => context.refreshResource('getUsers'),
  compact: false,
)

// Empty state
AutoEmptyWidget(
  title: 'No Users',
  subtitle: 'Add your first user to get started',
  icon: Icons.people_outline,
  actionText: 'Add User',
  onAction: () => showAddUserDialog(context),
)
```

---

## 🔧 Context Extensions

Access FKernal services from any widget:

```dart
// State Management
context.useResource<List<User>>('getUsers');      // Reactive state
context.fetchResource<List<User>>('getUsers');    // Imperative fetch
context.refreshResource<List<User>>('getUsers');  // Force refresh
context.performAction<User>('createUser', payload: user);

// Managers
context.stateManager;    // StateManager instance
context.storageManager;  // StorageManager instance
context.themeManager;    // ThemeManager instance
context.errorHandler;    // ErrorHandler instance

// Theme
context.watchThemeManager();    // Reactive theme
context.themeManager.toggleTheme();  // Switch light/dark

// Local State
context.localState<int>('counter');     // Get value
context.localSlice<int>('counter');     // Get slice
context.updateLocal<int>('counter', (v) => v + 1);
```

---

## 🎨 Theming

Define your design system tokens:

```dart
const theme = ThemeConfig(
  primaryColor: Color(0xFF6366F1),
  secondaryColor: Color(0xFF8B5CF6),
  
  useMaterial3: true,
  defaultThemeMode: ThemeMode.system,
  
  borderRadius: 12.0,
  defaultPadding: 16.0,
  cardElevation: 2.0,
  
  fontFamily: 'Inter',
);
```

Toggle theme from anywhere:

```dart
IconButton(
  icon: Icon(Icons.dark_mode),
  onPressed: () => context.themeManager.toggleTheme(),
)
```

---

## 🛡️ Error Handling

All errors are normalized to `FKernalError`:

```dart
const error = FKernalError(
  type: FKernalErrorType.network,
  message: 'Connection failed',
  statusCode: null,
  originalError: SocketException('...'),
);

// Error types
FKernalErrorType.network      // Connection issues
FKernalErrorType.server       // 5xx responses
FKernalErrorType.unauthorized // 401
FKernalErrorType.forbidden    // 403
FKernalErrorType.notFound     // 404
FKernalErrorType.validation   // Invalid data
FKernalErrorType.rateLimited  // 429
FKernalErrorType.timeout      // Request timeout
FKernalErrorType.unknown      // Unexpected errors
FKernalErrorType.cancelled    // Request manually cancelled
```
```

---

## 🏗️ Models

Implement `FKernalModel` for type-safe API handling:

```dart
class User implements FKernalModel {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'],
    name: json['name'],
    email: json['email'],
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
  };

  @override
  void validate() {
    if (name.isEmpty) {
      throw FKernalError(
        type: FKernalErrorType.validation,
        message: 'Name is required',
      );
    }
  }
}
```

---

## 🔌 Extensibility

### Custom Network Client

```dart
class MyNetworkClient implements INetworkClient {
  @override
  Future<T> request<T>(Endpoint endpoint, {...}) async {
    // Your implementation
  }
}

await FKernal.init(
  config: config.copyWith(
    networkClientOverride: MyNetworkClient(),
  ),
  endpoints: endpoints,
);
```

### Custom Storage Providers

```dart
await FKernal.init(
  config: config.copyWith(
    cacheProviderOverride: MyCustomCacheProvider(),
    secureProviderOverride: MySecureStorageProvider(),
  ),
  endpoints: endpoints,
);
```

### Observers

```dart
class AnalyticsObserver extends KernelObserver {
  @override
  void onEvent(KernelEvent event) {
    analytics.track(event.name, event.data);
  }
}

await FKernal.init(
  config: config,
  endpoints: endpoints,
  observers: [AnalyticsObserver()],
);
```

---

## 📋 Best Practices

### 1. Centralize Endpoints
Keep all endpoints in a single configuration file for maintainability:
```dart
// lib/config/endpoints.dart
final appEndpoints = <Endpoint>[
  // Auth
  Endpoint(id: 'login', path: '/auth/login', method: HttpMethod.post),
  // Users
  Endpoint(id: 'getUsers', path: '/users', ...),
];
```

### 2. Use Parsers for Type Safety
Always provide a `parser` function to ensure type-safe data handling:
```dart
parser: (json) => (json as List)
    .map((u) => User.fromJson(Map<String, dynamic>.from(u)))
    .toList(),
```

### 3. Leverage Cache Invalidation
Use `invalidates` to keep UI consistent without manual refreshes:
```dart
Endpoint(
  id: 'createPost',
  invalidates: ['getPosts', 'getUserPosts', 'getPostStats'],
),
```

### 4. Use Appropriate Cache TTLs
Match cache duration to data volatility:
| Data Type | Recommended TTL |
|-----------|-----------------|
| User session/auth | No cache |
| Notifications | 1 minute |
| Feed/Timeline | 2-5 minutes |
| User profile | 5-15 minutes |
| Static content | 24 hours |

### 5. Handle Empty States
Always provide feedback for empty data:
```dart
emptyWidget: const AutoEmptyWidget(
  title: 'No Users',
  subtitle: 'Invite team members to get started',
  icon: Icons.group_add,
),
```

### 6. Validate Models Before Mutations
Always validate data before sending to the API to provide immediate feedback.

---

## ❓ FAQ

### How does FKernal compare to BLoC/Riverpod/Provider?
FKernal is **not a replacement** for state management libraries — it's a **higher-level abstraction** that handles the common patterns (API calls, caching, loading states) that these libraries require you to implement manually. Typical code reduction is 80-90%.

### Can I use FKernal with an existing app?
Yes! FKernal can be adopted incrementally. Initialize alongside your existing setup and migrate one screen at a time.

### Does FKernal work with GraphQL?
Yes, by implementing `INetworkClient` to translate endpoints to GraphQL queries.

### How do I handle authentication?

FKernal supports three ways to handle auth:

1. **Static Token**:
```dart
AuthConfig.bearer('token', onTokenRefresh: () => auth.refresh())
```

2. **Dynamic Provider** (Recommended for Secure Storage):
```dart
AuthConfig.dynamic(
  tokenProvider: () => secureStorage.read('access_token'),
  onTokenExpired: () => handleLogout(),
)
```

3. **Runtime Updates**:
```dart
FKernal.instance.updateAuthToken(newToken);
FKernal.instance.clearAuthToken();
```

### Does it support request cancellation?
Yes! Every widget can cancel its own requests, or you can do it manually:
```dart
FKernal.instance.cancelEndpoint('getUsers');
```

### Is FKernal production-ready?
Yes! FKernal includes comprehensive error handling, automatic retry with exponential backoff, memory-efficient state management, automatic request deduplication, and built-in observability.

---

## 🔄 Migration Guide

### From BLoC Pattern
**Before**: 80+ lines (Bloc class + Repository + Screen)
**After**: 10-15 lines (Endpoint config + FKernalBuilder)

### From Riverpod
**Before**: FutureProvider + Consumer with `.when()` handling
**After**: Endpoint config + FKernalBuilder with automatic state handling

See the [full migration guide](https://github.com/thihako2/fkernal/blob/main/docs/migration.md) for detailed examples.

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on:
- Code of conduct
- Development setup
- Pull request process
- Design principles

---

## 🔗 Resources

- [API Documentation](https://pub.dev/documentation/fkernal/latest/)
- [Example App](https://github.com/thihako2/fkernal/tree/main/example)
- [GitHub Issues](https://github.com/thihako2/fkernal/issues)
- [Changelog](CHANGELOG.md)

---

Built with ❤️ by the FKernal Team
