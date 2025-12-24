# Architecture Deep Dive

FKernal is built on the philosophy of **Configuration over Implementation**. It provides a structured, opinionated, yet extensible architecture for building production-grade Flutter applications.

## Core Concepts

### 1. The Kernel (`FKernal`)

The `FKernal` singleton is the heart of the framework. It orchestrates the initialization and lifecycle of all core services:
- **Network Client**: Manages API communication.
- **Storage Manager**: Handles caching and persistence.
- **State Manager**: Orchestrates reactive state for resources.
- **Theme Manager**: Controls design system tokens and modes.
- **Endpoint Registry**: Validates and stores your API definitions.

It must be initialized before `runApp()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FKernal.init(
    config: myConfig,
    endpoints: myEndpoints,
  );
  
  runApp(const MyApp());
}
```

### 2. Dependency Injection

FKernal uses a service locator pattern internally but exposes services mainly via `BuildContext` extensions. This keeps your widget tree clean of complex provider lookups.

| Service | Accessor | Purpose |
|---------|----------|---------|
| State Manager | `context.stateManager` | Access low-level state logic |
| Theme Manager | `context.themeManager` | Listen to or toggle themes |
| Storage Manager | `context.storageManager` | Direct cache manipulation |
| Error Handler | `context.errorHandler` | Manual error processing |

### 3. The App Wrapper (`FKernalApp`)

The `FKernalApp` widget injects the necessary bindings (ProviderScope, context overrides) into the widget tree. It should wrap your `MaterialApp`:

```dart
FKernalApp(
  child: MaterialApp(...),
)
```

## Configuration (`FKernalConfig`)

`FKernalConfig` is immutable and declarative. It controls the behavior of all subsystems.

```dart
const config = FKernalConfig(
  // Networking
  baseUrl: 'https://api.example.com',
  connectTimeout: 30000,
  
  // Environment
  environment: Environment.production,
  
  // Auth
  auth: AuthConfig.bearer('token'),
  
  // Feature Flags
  features: FeatureFlags(
    enableCache: true,
    enableLogging: false,
  ),
  
  // Customization
  networkClientOverride: null, // Inject custom implementation
  cacheProviderOverride: null, // Inject custom storage
);
```

## Extensibility

FKernal conforms to the Open-Closed Principle. You can extend its behavior without modifying source code by implementing core interfaces:

- `INetworkClient`: For replacing Dio with GraphQL, gRPC, or Mock clients.
- `IStorageProvider`: For changing the cache backing store (e.g., to SQLite or SharedPrefs).
- `ISecureStorageProvider`: For custom sensitive data storage.
- `KernelObserver`: For tapping into the event stream (analytics, logging).
