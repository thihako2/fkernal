# FKernal Project Deliverables

## 1. Architecture Diagram (ASCII)

```text
+-------------------------------------------------------------+
|                        APP LAYER                            |
|  (UI Screens, Pure Function of State, Zero Business Logic)  |
+------------------------------+------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                        KERNEL LAYER                         |
|                                                             |
|  +------------------+   +-------------------+   +--------+  |
|  |  State Manager   <---+  Local Slices     |   | Theme  |  |
|  | (Auto-wiring)    |   | (Custom logic)    |   | Manager|  |
|  +--------+---------+   +-------------------+   +----+---+  |
|           |                                          |      |
|           v                                          v      |
|  +------------------+   +-------------------+   +--------+  |
|  |   API Client     |   +   Storage Manager |   | Design |  |
|  | (REST/Extensible)|   | (Cache/Persistent)|   | Tokens |  |
|  +--------+---------+   +---------+---------+   +--------+  |
|           |                       |                         |
+-----------|-----------------------|-------------------------+
            |                       |
            v                       v
    +---------------+       +---------------+
    |  External API |       | Local Storage |
    +---------------+       +---------------+
```

## 2. Scalable Folder Structure

```text
lib/
├── src/
│   ├── core/               # Kernal initialization and core config
│   │   ├── fkernal_app.dart
│   │   ├── fkernal_config.dart
│   │   └── environment.dart
│   ├── networking/         # Network abstraction (REST, etc.)
│   │   ├── api_client.dart
│   │   ├── endpoint.dart
│   │   └── endpoint_registry.dart
│   ├── state/              # Global and local state management
│   │   ├── state_manager.dart
│   │   ├── resource_state.dart
│   │   └── local_slice.dart
│   ├── storage/            # Caching and persistence
│   │   ├── storage_manager.dart
│   │   └── cache_config.dart
│   ├── error/              # Centralized error normalization
│   │   ├── error_handler.dart
│   │   └── fkernal_error.dart
│   ├── theme/              # Design tokens and theme engine
│   │   ├── theme_manager.dart
│   │   └── theme_config.dart
│   ├── widgets/            # High-level declarative builders
│   │   ├── fkernal_builder.dart
│   │   ├── action_builder.dart
│   │   └── auto_loading_error.dart
│   └── extensions/         # Context hooks (useResource, etc.)
│       └── context_extensions.dart
└── fkernal.dart            # Public API exports
```

## 3. Initialization Example

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Kernel with typed configuration
  final kernel = await FKernal.init(
    config: appConfig,
    endpoints: appEndpoints,
  );

  // 2. Check health status if needed
  if (kernel.healthStatus == KernelHealthStatus.degraded) {
    print('Kernel initialized with warnings (check storage)');
  }

  // 3. Launch App wrapped in KernalApp
  runApp(FKernalApp(child: MyApp()));
}
```

## 4. Complete Configuration Example

```dart
final appConfig = FKernalConfig(
  baseUrl: 'https://api.myapp.com/v1',
  environment: Environment.production,
  auth: AuthConfig.bearer(myInitialToken),
  features: FeatureFlags(
    enableCache: true,
    enableOffline: true,
    enableLogging: false,
  ),
  pagination: PaginationConfig(
    pageSize: 30,
    pageParam: 'offset',
    limitParam: 'limit',
  ),
  theme: ThemeConfig(
    primaryColor: Color(0xFF1E3A8A),
    fontFamily: 'Inter',
    borderRadius: 8.0,
  ),
  errorConfig: ErrorConfig(
    showSnackbars: true,
    onGlobalError: (error) => Sentry.captureException(error),
  ),
);

final appEndpoints = [
  Endpoint(
    id: 'getUsers',
    path: '/users',
    method: HttpMethod.get,
    cacheConfig: CacheConfig(duration: Duration(minutes: 10)),
    parser: (json) => (json as List).map((u) => User.fromJson(u)).toList(),
  ),
  Endpoint(
    id: 'createUser',
    path: '/users',
    method: HttpMethod.post,
    invalidates: ['getUsers'], // Auto-refreshes list after creation
  ),
];
```

## 5. Sample UI Screen (Zero Non-UI Logic)

```dart
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 1. Purely reactive data consumption
    final usersState = context.useResource<List<User>>('getUsers');

    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: usersState.when(
        data: (users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, i) => UserTile(user: users[i]),
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err) => Center(child: Text('Failed to load users')),
      ),
      floatingActionButton: AddUserButton(),
    );
  }
}

class AddUserButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 2. Declarative action hook
    final createUser = context.useAction('createUser');

    return FloatingActionButton(
      onPressed: () async {
        await createUser(payload: {'name': 'New User'});
        // Success: List auto-invalidates and refreshes based on config
      },
      child: Icon(Icons.add),
    );
  }
}
```

## 6. Extensibility Explanation

The FKernal is designed around **Composition of Handlers**.

- **Networking**: The `ApiClient` uses Dio interceptors. To support **GraphQL** or **gRPC**, you can swap the `ApiClient` implementation or add custom interceptors that route specific endpoint protocols through different transport layers.
- **Storage**: The `StorageManager` uses Hive for caching. To use **SQLite** or **ProtoBuf**, you can implement a new Storage Provider and inject it during `init`.
- **State**: New state behavior can be added via `LocalSlice`. If "auto-wiring" isn't enough, developers can bridge to their own Bloc/Cubit by observing the `StateManager`.

## 7. Tradeoffs & Limitations

### Tradeoffs
- **Convention over Configuration**: Boosts speed but requires learning the "Kernel Way".
- **Runtime Registry**: Endpoints are defined as data, which avoids large code-gen but lacks some compile-time safety (e.g. typos in endpoint IDs).
- **Single Instance**: Simplifies wiring but makes multi-kernel apps (rare) harder.

### Limitations
- **Highly Custom Transitions**: Not suitable for apps where UI state is extremely complex and separate from API state (e.g. Photoshop-like apps).
- **Extreme Performance**: While performant, the abstraction layer adds a tiny overhead. Not for AAA mobile games.
- **Legacy APIs**: Works best with RESTful/Clean APIs; legacy SOAP or very irregular APIs might need more manual override code.
