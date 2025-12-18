# FKernal

A **configuration-driven Flutter framework** that lets developers focus solely on UI screens while automatically handling networking, state management, storage, error handling, and theming.

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)

## Features

- 🚀 **Single Initialization** - One call to `FKernal.init()` sets up everything
- 📡 **Declarative Networking** - Define endpoints as constants, get API client automatically
- 🔄 **Auto State Management** - State slices generated per endpoint, no manual Bloc/Provider code
- 💾 **Smart Caching** - Automatic response caching with TTL and invalidation
- ❌ **Built-in Error Handling** - Centralized errors with automatic retry and UI widgets
- 🎨 **Theming System** - Define design tokens once, apply everywhere
- 🔌 **Extensible** - Override interceptors, error widgets, storage backends

## Quick Start

### 1. Add Dependency

```yaml
dependencies:
  fkernal:
    path: packages/fkernal
```

### 2. Configure Your App

```dart
// lib/config/app_config.dart
const appConfig = FKernalConfig(
  baseUrl: 'https://api.example.com',
  environment: Environment.development,
  features: FeatureFlags(
    enableCache: true,
    enableAutoRetry: true,
  ),
);
```

### 3. Define Endpoints

```dart
// lib/config/endpoints.dart
const endpoints = [
  Endpoint(
    id: 'getUsers',
    path: '/users',
    method: HttpMethod.get,
    cacheConfig: CacheConfig(duration: Duration(minutes: 5)),
  ),
  Endpoint(
    id: 'createUser',
    path: '/users',
    method: HttpMethod.post,
    invalidates: ['getUsers'], // Auto-refresh users list
  ),
];
```

### 4. Initialize

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FKernal.init(
    config: appConfig,
    endpoints: endpoints,
  );
  
  runApp(FKernalApp(child: MyApp()));
}
```

### 5. Use in Screens

```dart
class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FKernalBuilder<List<dynamic>>(
      resource: 'getUsers',
      builder: (context, users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) => UserTile(users[i]),
      ),
      // Loading & error states handled automatically!
    );
  }
}
```

## Core Concepts

### Endpoints

Endpoints are the heart of FKernal. Define them once, use everywhere:

```dart
Endpoint(
  id: 'getUserPosts',           // Unique identifier
  path: '/users/{userId}/posts', // Path with parameters
  method: HttpMethod.get,
  cacheConfig: CacheConfig.medium, // 5-minute cache
  invalidates: ['getAllPosts'],    // Invalidate on mutation
)
```

### State Management

FKernal automatically manages state for each endpoint:

```dart
// Get current state
final state = context.stateManager.getState<List<User>>('getUsers');

// Fetch data
await context.fetchResource<List<User>>('getUsers');

// Perform mutation
await context.performAction<User>('createUser', payload: userData);

// Refresh
await context.refreshResource<List<User>>('getUsers');
```

### Resource States

All data goes through these states:

| State | Description |
|-------|-------------|
| `ResourceInitial` | No fetch attempted yet |
| `ResourceLoading` | Currently fetching |
| `ResourceData` | Successfully loaded |
| `ResourceError` | Error occurred |

### Caching

Configure cache per endpoint:

```dart
// Preset durations
CacheConfig.none      // No caching
CacheConfig.short     // 1 minute
CacheConfig.medium    // 5 minutes
CacheConfig.long      // 1 hour
CacheConfig.persistent // 24 hours

// Custom duration
CacheConfig(duration: Duration(minutes: 15))
```

## Local State Management

FKernal also handles local state (non-API) using `LocalSlice`.

### 1. Easy Usage (Lazy Registration)
No need to register in `main.dart`! Just define it where you use it.

```dart
FKernalLocalBuilder<int>(
  slice: 'counter',
  create: () => CounterSlice(initial: 0),
  builder: (context, count, update) => FloatingActionButton(
    onPressed: () => update((c) => c + 1),
    child: Text('$count'),
  ),
)
```

### 2. Context Extensions
Access state anywhere in the widget tree:

```dart
// Get current value
final count = context.localState<int>('counter');

// Update state
context.updateLocal<int>('counter', (c) => c + 1);

// Get the slice object
final slice = context.localSlice<int>('counter');
```

### Available Slices
- `ValueSlice<T>` - Simple value
- `ListSlice<T>` - List management
- `MapSlice<K,V>` - Map management
- `ToggleSlice` - Boolean toggle
- `CounterSlice` - Integer counter (increment/decrement)
- `LocalSlice<T>` - Custom state objects

### Error Handling

Errors are automatically:
- Categorized (network, server, auth, validation, etc.)
- Logged based on environment
- Displayed with built-in widgets
- Retryable when appropriate

```dart
try {
  await context.performAction('createUser', payload: data);
} on FKernalError catch (e) {
  if (e.type == FKernalErrorType.network) {
    // Handle network error
  }
}
```

## Configuration Reference

### FKernalConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `baseUrl` | `String` | required | API base URL |
| `environment` | `Environment` | `development` | App environment |
| `features` | `FeatureFlags` | default | Feature toggles |
| `auth` | `AuthConfig?` | null | Authentication config |
| `defaultCacheConfig` | `CacheConfig` | 5 min | Default caching |
| `connectTimeout` | `int` | 30000 | Connection timeout (ms) |
| `receiveTimeout` | `int` | 30000 | Receive timeout (ms) |
| `defaultPageSize` | `int` | 20 | Pagination size |

### FeatureFlags

| Property | Default | Description |
|----------|---------|-------------|
| `enableCache` | `true` | Enable response caching |
| `enableOffline` | `false` | Enable offline mode |
| `enableAutoRetry` | `true` | Auto-retry on failure |
| `maxRetryAttempts` | `3` | Max retry count |
| `enableLogging` | `true` | Enable request logging |

### AuthConfig

```dart
// Bearer token
AuthConfig.bearer('your-token')

// API Key
AuthConfig.apiKey('your-key', header: 'X-API-Key')

// Custom with token refresh
AuthConfig(
  headers: {'Authorization': 'Bearer $token'},
  onTokenRefresh: () async => getNewToken(),
)
```

## Widgets

### FKernalBuilder

Main widget for consuming data:

```dart
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  params: {'page': 1},
  pathParams: {'teamId': '123'},
  autoFetch: true,
  builder: (context, data) => UserList(data),
  loadingWidget: MyLoader(),
  errorBuilder: (context, error, retry) => MyError(error, retry),
  onData: (data) => print('Loaded ${data.length} users'),
  onError: (error) => showSnackbar(error),
)
```

### FKernalActionBuilder

For mutations with UI feedback:

```dart
FKernalActionBuilder<User>(
  action: 'createUser',
  onSuccess: (user) => Navigator.pop(context),
  showSuccessSnackbar: true,
  builder: (context, perform, state) => ElevatedButton(
    onPressed: state.isLoading ? null : () => perform(userData),
    child: state.isLoading ? Loader() : Text('Create'),
  ),
)
```

## Extension Methods

Access FKernal services via context:

```dart
// State management
context.stateManager
context.fetchResource<T>('endpoint')
context.performAction<T>('endpoint', payload: data)
context.refreshResource<T>('endpoint')

// Other services
context.fkernalConfig
context.apiClient
context.themeManager
context.errorHandler
context.storageManager
```

## Advanced Usage

### Custom Interceptors

```dart
// In your ApiClient subclass or config
config.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      // Modify request
      handler.next(options);
    },
  ),
);
```

### Custom Error Widgets

```dart
FKernalBuilder(
  resource: 'getUsers',
  errorBuilder: (context, error, retry) => Card(
    child: Column(
      children: [
        Text(error.message),
        ElevatedButton(onPressed: retry, child: Text('Retry')),
      ],
    ),
  ),
)
```

### Custom Response Parsing

```dart
Endpoint(
  id: 'getUser',
  path: '/users/{id}',
  parser: (json) => User.fromJson(json['data']),
)
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client with interceptors |
| `hive_flutter` | Fast local storage |
| `flutter_secure_storage` | Secure credential storage |
| `provider` | Dependency injection |
| `connectivity_plus` | Network status monitoring |

## License

MIT License
