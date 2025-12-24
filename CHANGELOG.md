# Changelog

All notable changes to the FKernal package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.0] - 2025-12-24

### 🚀 Major Migration: Riverpod

This release replaces the internal `provider` + `ValueNotifier` engine with **Riverpod** for robust state management.

### BREAKING CHANGES
- **Removed `provider` dependency**: All `context.read` / `context.watch` calls depending on `package:provider` will fail.
- **Context Extensions**: `context.useResource` is **NO LONGER REACTIVE**. It returns a snapshot.
  - **Migration**: Use `FKernalBuilder` or convert your widget to `ConsumerWidget` and use `ref.watch`.
- **`watchThemeManager` removed**: Use `context.themeManager` inside a `ListenableBuilder`.

### Added
- **Universal State Management**:
  - **Architecture**: Pluggable state engine supporting Riverpod (default), BLoC, GetX, MobX, Signals, and Provider.
  - **Adapters**: New `StateAdapter` and `ResourceStateAdapter` interfaces for custom implementations.
  - **Configuration**: New `stateManagement`, `stateAdapter`, and `localStateFactory` options in `FKernalConfig`.
- **Riverpod Default**: Optimized internal engine using `UncontrolledProviderScope` and `ProviderContainer`.
- **Multi-State Bridges**: Drop-in bridges (`ResourceCubit`, `ResourceSignal`, etc.) for hybrid architectures.
- **StateManager**: Added `stream()` method for easy integration with external reactive libraries.
- **Improved Type Safety**: Enhanced generic type stability during `ResourceState` transitions (Loading/Error) to prevent casting issues in builders.
- **Global Customizability**: Added `GlobalUIConfig` for default builders, custom network `interceptors` support, and `ProviderContainer` overrides.
- **`FKernalBuilder`**: Updated to be a `ConsumerStatefulWidget` with robust type-safe state observation.

---

## [1.2.0] - 2025-12-24

### 🎉 Highlights

This release introduces major improvements to authentication, networking performance, and testing infrastructure, while making the core package lighter by decoupling Firebase.

### Added

- **Token Refresh & Dynamic Auth**:
  - `AuthConfig.dynamic()` for retrieving tokens from secure storage before each request.
  - `onTokenRefresh` callback for automatic 401 handling and request retry.
  - `onTokenExpired` callback for handling session expiration (e.g., logout).
  - `FKernal.instance.updateAuthToken()` and `clearAuthToken()` for runtime control.
- **Pagination Support**:
  - New `FKernalPaginatedBuilder` widget for infinite scroll lists.
  - Automatic load-more logic and state management (loading more, has more data).
- **Advanced Caching**:
  - Wildcard pattern invalidation: `storageManager.invalidateCachePattern('/users*')`.
  - Endpoint-specific cache clearing: `storageManager.clearEndpointCache('/users')`.
- **Testing Utilities**:
  - Comprehensive mocks in `package:fkernal/testing.dart`.
  - `MockNetworkClient` with request recording and response/error mocking.
  - `MockStorageProvider` and `MockSecureStorageProvider` for in-memory testing.
- **Performance Optimizations**:
  - **Request Deduplication**: Concurrent identical GET requests are now automatically merged into a single network call.
  - **Per-Widget Cancellation**: Requests are now cancellable at the endpoint level via `FKernal.instance.cancelEndpoint()`.

### Changed

- **Firebase Decoupling**: Moved `cloud_firestore`, `firebase_auth`, and `firebase_storage` to a separate optional module.
  - Import `package:fkernal/fkernal_firebase.dart` if you need Firebase integration.
- **Improved Error Mapping**: Detailed mapping of `DioException` types to granular `FKernalErrorType` (timeout, rateLimited, cancelled, etc.).

### Fixed

- Request deduplication now correctly handles cache hits and misses.
- Improved path parameter substitution logic to prevent accidental overlaps.

---

## [1.1.0] - 2025-12-24

### 🎉 Highlights

This release focuses on improving developer experience with comprehensive documentation, a consolidated example app, and new features for type safety and observability.

### Added

#### Documentation & Examples
- **Comprehensive Example App**: Consolidated all individual examples into a single, feature-complete `example/main.dart` demonstrating:
  - FKernal initialization with full configuration
  - Networking with endpoints, caching, and invalidation
  - State management with `FKernalBuilder`
  - Local state with all slice types (Value, Toggle, Counter, List, Map)
  - Theme switching between light/dark modes
  - Error handling patterns
  - All context extensions
- **Documentation Overhaul**: Complete rewrite of `README.md` including:
  - Table of contents for easy navigation
  - Detailed API reference for all widgets
  - Cache strategy explanation with TTL recommendations
  - Advanced patterns (dependent fetches, optimistic updates, pagination)
  - FAQ section addressing common questions
  - Migration guides from BLoC and Riverpod

#### Type Safety
- **`ResourceKey<T>`**: Introduced compile-time type-safe resource access
  ```dart
  // Define typed keys
  const usersKey = ResourceKey<List<User>>('getUsers');
  
  // Use with type safety
  final users = context.useResourceKey(usersKey); // Type inferred!
  ```

#### Observability
- **`KernelObserver`**: Abstract class for implementing custom observers
- **`KernelEvent`**: Sealed class hierarchy for all kernel events:
  - `RequestStarted` - Fired when an API request begins
  - `RequestCompleted` - Fired on successful completion with duration
  - `RequestFailed` - Fired on error with error details
  - `CacheHit` / `CacheMiss` - Cache access events
  - `StateChanged` - Resource state transitions
- **Integration Support**: Easy integration with analytics (Firebase, Mixpanel) and crash reporting (Sentry, Crashlytics)

#### Firebase Integration
- **`FirebaseNetworkClient`**: Drop-in network client for Firebase/Firestore
  ```dart
  await FKernal.init(
    config: config.copyWith(
      networkClientOverride: FirebaseNetworkClient(FirebaseFirestore.instance),
    ),
    endpoints: endpoints,
  );
  ```

#### Architecture Improvements
- **`INetworkClient`**: Interface for custom network implementations (GraphQL, gRPC, etc.)
- **`IStorageProvider`**: Interface for custom cache storage (SQLite, Redis, etc.)
- **`ISecureStorageProvider`**: Interface for custom secure storage (Keychain, biometric, etc.)

### Changed

- **Widget Naming**: Standardized all widget names with `FKernal` prefix:
  - `FBuilder` → `FKernalBuilder`
  - `FActionBuilder` → `FKernalActionBuilder`
  - `FLocalBuilder` → `FKernalLocalBuilder`
- **Local Slices**: Enhanced with history tracking and undo/redo support
  ```dart
  LocalSlice<MyState>(
    initialState: MyState(),
    enableHistory: true, // Enable undo/redo
    maxHistoryLength: 50,
  );
  ```
- **Error Messages**: Improved error messages in development mode with actionable suggestions

### Fixed

- Cache invalidation now properly handles path parameters
- Theme persistence works correctly across app restarts
- Memory leak in `StateManager` when disposing resources

### Deprecated

- `FBuilder` - Use `FKernalBuilder` instead (will be removed in 2.0.0)
- `FActionBuilder` - Use `FKernalActionBuilder` instead (will be removed in 2.0.0)

---

## [1.0.0] - 2025-12-19

### 🎉 Initial Release

The first stable release of FKernal - the configuration-driven Flutter framework.

### Added

#### Core Framework
- **`FKernal`**: Main entry point with `init()` for framework initialization
- **`FKernalApp`**: Widget wrapper that provides kernel context to the widget tree
- **`FKernalConfig`**: Comprehensive configuration object including:
  - `baseUrl`: Base URL for all API requests
  - `environment`: Development, Staging, or Production
  - `features`: Feature flags for caching, retry, logging, etc.
  - `theme`: Theme configuration with Material 3 support
  - `auth`: Authentication configuration (Bearer, API Key, Custom)
  - `pagination`: Pagination defaults
  - `errorConfig`: Global error handling configuration

#### Declarative Networking
- **`Endpoint`**: Immutable endpoint definition with:
  - Path parameters support (`/users/{id}`)
  - Query parameters
  - Custom headers
  - Cache configuration
  - Response parser
  - Cache invalidation rules
- **`HttpMethod`**: Enum for GET, POST, PUT, PATCH, DELETE
- **Built-in Dio integration** with interceptors for:
  - Authentication header injection
  - Request/response logging (development only)
  - Error normalization
  - Automatic retry with exponential backoff

#### State Management
- **`ResourceState<T>`**: Sealed class for API resource states:
  - `ResourceInitial` - Not yet fetched
  - `ResourceLoading` - Request in progress
  - `ResourceData<T>` - Successful response with data
  - `ResourceError` - Failed with error details
- **`StateManager`**: Centralized state orchestration using `ValueNotifier` for efficient updates
- **Pattern Matching**: Full support for Dart 3 sealed class pattern matching

#### Local State Slices
- **`LocalSlice<T>`**: Generic state container for complex UI state
- **`ToggleSlice`**: Boolean state with `toggle()` method
- **`CounterSlice`**: Numeric state with `increment()`, `decrement()`, optional min/max bounds
- **`ListSlice<T>`**: List state with `add()`, `remove()`, `insert()`, `clear()` methods
- **`MapSlice<K, V>`**: Map state with `set()`, `remove()`, `clear()` methods

#### Smart Caching
- **Hive-backed binary storage** for efficient cache persistence
- **TTL-based expiration** with configurable duration
- **Stale-While-Revalidate** pattern support
- **Cache presets**: `none`, `short` (1m), `medium` (5m), `long` (1h), `persistent` (24h)
- **Automatic invalidation** on mutations via `invalidates` configuration

#### Theming System
- **`ThemeConfig`**: Design token configuration:
  - Primary, secondary, tertiary, error colors
  - Typography (font family)
  - Spacing (border radius, padding)
  - Material 3 toggle
- **`ThemeManager`**: Runtime theme control with:
  - Light/dark theme generation
  - `toggleTheme()` method
  - `setThemeMode(ThemeMode)` method
  - Automatic persistence of user preference

#### Error Handling
- **`FKernalError`**: Normalized error type with:
  - `type`: Enum categorizing the error (network, server, validation, etc.)
  - `message`: Human-readable message
  - `statusCode`: HTTP status code (if applicable)
  - `originalError`: Underlying exception
  - `stackTrace`: Stack trace for debugging
- **Error Types**: `network`, `server`, `unauthorized`, `forbidden`, `notFound`, `validation`, `rateLimited`, `timeout`, `cancelled`, `parse`, `unknown`
- **Auto-retry**: Configurable retry logic with exponential backoff

#### Widgets
- **`FKernalBuilder<T>`**: Reactive data consumption with:
  - Automatic loading/error/empty states
  - Custom builders for each state
  - `onData` and `onError` callbacks
- **`FKernalActionBuilder<T>`**: Mutation widget with loading feedback
- **`FKernalLocalBuilder<T>`**: Local state consumption
- **`FKernalToggleBuilder`**: Specialized toggle state builder
- **`FKernalCounterBuilder`**: Specialized counter state builder
- **`FKernalListBuilder<T>`**: Specialized list state builder
- **`AutoLoadingWidget`**: Default loading indicator
- **`AutoErrorWidget`**: Default error display with retry
- **`AutoEmptyWidget`**: Default empty state display

#### Context Extensions
Zero-boilerplate helpers accessible from any `BuildContext`:
- `context.fetchResource<T>(id)` - Imperative fetch
- `context.refreshResource<T>(id)` - Force refresh
- `context.performAction<T>(id, payload)` - Perform mutation
- `context.useResource<T>(id)` - Reactive state access
- `context.localState<T>(id)` - Local state value
- `context.localSlice<T>(id)` - Local slice instance
- `context.updateLocal<T>(id, updater)` - Update local state
- `context.stateManager` - State manager instance
- `context.storageManager` - Storage manager instance
- `context.themeManager` - Theme manager instance
- `context.watchThemeManager()` - Reactive theme access
- `context.errorHandler` - Error handler instance

### Dependencies

- `dio: ^5.4.0` - HTTP client
- `hive: ^2.2.3` - Local storage
- `hive_flutter: ^1.1.0` - Hive Flutter integration

---

## [0.1.0] - 2025-12-15 (Pre-release)

### Added
- Initial pre-release for internal testing
- Core architecture design
- Basic networking and state management

---

## Roadmap

### Planned for 2.0.0
- [ ] Code generation for endpoints (compile-time safety)
- [ ] GraphQL first-class support
- [ ] WebSocket/real-time subscriptions
- [ ] Offline-first mode with sync queue
- [ ] DevTools extension for debugging

### Under Consideration
- [ ] Built-in pagination widget
- [ ] Form validation integration
- [ ] Push notification handling
- [ ] Deep linking support
