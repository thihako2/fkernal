# FKernal 🚀

**The Configuration-Driven Flutter Kernal**

FKernal is a production-grade, architectural foundation for Flutter applications. It is designed to solve "boilerplate fatigue" by providing a centralized orchestration layer for the most complex aspects of app development: **Networking, State Transitions, Persistence, Error Recovery, and Design Systems**.

By leveraging a declarative configuration model, FKernal enables developers to build scalable, resilient features in a fraction of the time, while maintaining perfect separation of concerns.

---

## 📑 Table of Contents
- [1. Architecture Philosophy](#1-architecture-philosophy)
- [2. Installation & Setup](#2-installation--setup)
- [3. Core Configuration (Deep Dive)](#3-core-configuration-deep-dive)
  - [FKernalConfig](#fkernalconfig)
  - [Feature Flags](#feature-flags)
  - [Authentication (AuthConfig)](#authentication-authconfig)
- [4. Declarative Networking](#4-declarative-networking)
  - [Endpoint Definition](#endpoint-definition)
  - [Response Parsing](#response-parsing)
  - [Automatic Retry System](#automatic-retry-system)
- [5. State Management Engine](#5-state-management-engine)
  - [ResourceState Lifecycle](#resourcestate-lifecycle)
  - [Request Deduplication](#request-deduplication)
  - [Local UI State (Slices)](#local-ui-state-slices)
- [6. Persistence & Caching](#6-persistence--caching)
  - [TTL Systems](#ttl-systems)
  - [Secure Storage](#secure-storage)
- [7. Widget Reference (Full API)](#7-widget-reference-full-api)
  - [FKernalBuilder](#fkernalbuilder)
  - [FKernalActionBuilder](#fkernalactionbuilder)
  - [Local State Builders](#local-state-builders)
- [8. Extension Library](#8-extension-library)
- [9. Theming & Styling](#9-theming--styling)
- [10. Logging & Debugging](#10-logging--debugging)
- [11. Best Practices](#11-best-practices)

---

## 🏗 1. Architecture Philosophy

FKernal is built on the principle of **"Configuration over Implementation"**. In a standard Flutter app, a single feature often requires manual wiring of repositories, BLoCs, caching, and loading/error UI logic.

**With FKernal**, you define the **Endpoint** and **Theme tokens** once. The framework then automatically:
1.  **Orchestrates Networking**: Handles HTTP methods, headers, and timeouts via Dio.
2.  **Manages State**: Generates reactive slices that transition between Loading, Data, and Error.
3.  **Persists Data**: Synchronizes network responses with a Hive-backed local cache.
4.  **Handles Errors**: Normalizes all platform-specific exceptions into a unified `FKernalError` system.

---

## 🚀 2. Installation & Setup

### Add Dependency
```yaml
dependencies:
  fkernal: ^1.0.0
```

### Quick Startup
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FKernal.init(
    config: FKernalConfig(baseUrl: 'https://api.example.com'),
    endpoints: [/* Your Endpoints */],
  );
  
  runApp(FKernalApp(child: MyApp()));
}
```

---

## ⚙️ 3. Core Configuration (Deep Dive)

### FKernalConfig
The central hub for all framework behavior.

| Property | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `baseUrl` | `String` | **Required** | The primary URL for all API requests. |
| `environment` | `Environment` | `dev` | Affects logging and error masking (`dev`, `staging`, `prod`). |
| `connectTimeout` | `int` | `30000` | Connection timeout in milliseconds. |
| `defaultPageSize` | `int` | `20` | Standard size for paginated requests. |

### Feature Flags
Granular control over framework capabilities.

```dart
features: FeatureFlags(
  enableCache: true,          // Toggles the Hive response cache
  enableAutoRetry: true,       // Exponential backoff for network failures
  maxRetryAttempts: 3,         // Retry limit for 5xx and timeouts
  enableLogging: true,         // Visual Dio logs in the console
  enableOffline: false,        // Persistent fallback for offline use
)
```

### Authentication (AuthConfig)
FKernal handles complex auth flows including automatic token refreshment.

```dart
final auth = AuthConfig.bearer(
  'initial-token',
  onTokenRefresh: () async {
    final response = await manualRefreshCall();
    return response.token; // FKernal automatically retries the failed 401 request with this new token
  },
);
```

---

## 📡 4. Declarative Networking

### Endpoint Definition
Endpoints are immutable blueprints for your data layer.

```dart
Endpoint(
  id: 'getUsers',
  path: '/users',
  method: HttpMethod.get,
  cacheConfig: CacheConfig.medium,    // 5-minute TTL
  requiresAuth: true,                 // Adds Authorization headers automatically
  invalidates: ['getStats'],          // Clears 'getStats' cache when this is triggered
)
```

### Response Parsing
FKernal produces the internal `ResourceState<T>` where `T` is your model.

```dart
Endpoint(
  id: 'getUser',
  path: '/users/{id}',
  parser: (json) => User.fromJson(json), // Automatic conversion from JSON to Object
)
```

---

## 🔄 5. State Management Engine

### ResourceState Lifecycle
Every request is tracked as a `ResourceState`, which is a sealed class:
- **`ResourceInitial`**: Resting state before any interaction.
- **`ResourceLoading`**: Request in flight. Contains `previousData` to allow for smooth UI transitions (no flicker).
- **`ResourceData`**: Contains the parsed `data`, a `fetchedAt` timestamp, and a `fromCache` flag.
- **`ResourceError`**: Contains a typed `FKernalError`.

### Request Deduplication
If multiple widgets request `getUsers` simultaneously, FKernal detects the collision and fires **only one network request**. All widgets share the same future and state transition.

### Local UI State (Slices)
For non-API state (temporary UI toggles, multi-step forms), use specialized slices:
- **`ValueSlice<T>`**: Generic value container.
- **`ToggleSlice`**: Specialized boolean container with `toggle()` helper.
- **`CounterSlice`**: Integer container with `increment()`/`decrement()` bounded by min/max.
- **`ListSlice<T>`**: Full list management with built-in history and undo support.

---

## 💾 6. Persistence & Caching

### TTL Systems
Define Exactly how long data should live:
- `CacheConfig.none`: Always fetch from network.
- `CacheConfig.short`: 1-minute TTL.
- `CacheConfig.medium`: 5-minute TTL (Recommended for most GET requests).
- `CacheConfig.long`: 1-hour TTL.
- `CacheConfig.persistent`: 24-hour TTL.

### Secure Storage
FKernal wraps `flutter_secure_storage` for high-security persistence:
```dart
await context.storageManager.setSecure('api_token', 'xyz...');
final token = await context.storageManager.getSecure('api_token');
```

---

## 🧱 7. Widget Reference (Full API)

### FKernalBuilder<T>
The primary way to consume data.

| Attribute | Type | Description |
| :--- | :--- | :--- |
| `resource` | `String` | The unique ID of the endpoint. |
| `params` | `Map` | Query parameters (e.g., `{'q': 'search'}`). |
| `pathParams` | `Map` | Path variables (e.g., replaces `{id}`). |
| `autoFetch` | `bool` | Automatically fire the request on mount. (Default: `true`) |
| `builder` | `fn` | UI builder for the `data` state. |
| `loadingWidget` | `Widget` | Custom widget to show during first load. |

### FKernalActionBuilder<T>
The engine for mutations (POST/PUT/DELETE).

```dart
FKernalActionBuilder<User>(
  action: 'createUser',
  showSuccessSnackbar: true,
  successMessage: 'User created successfully!',
  builder: (context, perform, state) => ElevatedButton(
    onPressed: state.isLoading ? null : () => perform(formData),
    child: Text('Create'),
  ),
)
```

---

## 📊 8. Extension Library
FKernal extends `BuildContext` to provide a zero-effort developer experience.

| Method | Returns | Description |
| :--- | :--- | :--- |
| `context.stateManager` | `StateManager` | Access the global orchestrator. |
| `context.apiClient` | `ApiClient` | Direct access to the Dio-wrapped client. |
| `context.localState<T>(id)` | `T` | Current value of a local state slice. |
| `context.localSlice<T>(id)` | `LocalSlice<T>` | Access the full slice object. |
| `context.updateLocal<T>(id, fn)`| `void` | Update a local state slice reactively. |
| `context.fetchResource(id)` | `Future` | Trigger an imperative data fetch. |
| `context.performAction(id)` | `Future` | Trigger an imperative mutation. |
| `context.refreshResource(id)` | `Future` | Force a network re-fetch (ignores cache). |

---

## 🎨 9. Theming & Styling

FKernal includes a robust design system orchestrator that maps your brand tokens to Material 3 `ThemeData`.

```dart
final theme = ThemeConfig(
  primaryColor: Color(0xFF6366F1),
  fontFamily: 'Outfit',
  borderRadius: 12.0,
  useMaterial3: true,
  defaultThemeMode: ThemeMode.dark,
);
```

**Dynamic Switching:**
Change the global theme mode from anywhere using the context extension:
```dart
onPressed: () => context.themeManager.toggleTheme(),
```

---

## 🛠 10. Logging & Debugging

In `Environment.development`, FKernal provides a rich set of debugging logs:
- **Network Logs**: Every request, response, and error is logged via Dio with detailed headers and payloads.
- **Cache Logs**: Notifications whenever a cache hit or miss occurs.
- **State Logs**: Visual tracking of resource state transitions.

---

## 💡 11. Best Practices

1.  **Endpoint Centralization**: Keep all `Endpoint` definitions in a single `lib/config/endpoints.dart` file.
2.  **Type Safety**: Always provide a `parser` to endpoints to take full advantage of Dart's type system in your UI builders.
3.  **Invalidation**: Use the `invalidates` list to keep your UI consistent without manual state updates. For example, `createUser` should invalidate `getUsers`.
4.  **Optimistic UI**: Use the `previousData` property in `ResourceLoading` to show old data while the fresh data is being fetched.

---

## 📜 License
Licensed under the [MIT License](LICENSE). Built with ❤️ by the FKernal Team.
