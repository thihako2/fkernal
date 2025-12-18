# FKernal 🚀

**The Configuration-Driven Flutter Kernal**

FKernal is a powerful, opinionated framework built on top of Flutter that allows developers to focus **exclusively on building UI**. It eliminates boilerplate by automatically orchestrating networking, state management, local storage, error handling, and theming based on simple configuration constants.

---

## 🌟 Key Features

### ⚡️ Zero-Boilerplate State Management
Forget manual `ChangeNotifier`, `Bloc`, or `Riverpod` setups. FKernal automatically generates specialized `ResourceState` (Loading, Data, Error) for every API endpoint you define.

### 📡 Declarative Networking
Define your API structure once. FKernal handles:
- **Dio Integration**: Fully configured HTTP client.
- **Auto-Parsing**: Type-safe response parsing via custom parsers.
- **Interceptors**: Global and per-request interceptors for auth, logging, and more.

### 💾 Smart Caching & Offline Support
Performant local storage powered by **Hive**:
- **TTL Caching**: Define cache durations (Short, Medium, Long, Persistent).
- **Auto-Invalidation**: Mutations can automatically trigger re-fetches of related data.
- **Offline Resilience**: Serve cached data when the network is unavailable.

### 🎨 Design System & Theming
A centralized `ThemeConfig` that generates consistent Light and Dark Material 3 themes:
- Unified typography and color tokens.
- Custom border radius and elevation systems.
- Automatic theme switching based on system settings.

### 🧩 Local State Slices
Optimized widgets for managing non-API state (counters, toggles, form inputs):
- **Specialized Slices**: `ValueSlice`, `ListSlice`, `MapSlice`, `ToggleSlice`, `CounterSlice`.
- **History & Undo**: Built-in support for state history and undo/redo operations.

---

## 🚀 Quick Start

### 1. Add Dependency
Add FKernal to your `pubspec.yaml`:

```yaml
dependencies:
  fkernal: ^1.0.0
```

### 2. Configure Your App
Define your endpoints and theme in a central configuration.

```dart
// lib/config.dart
final appConfig = FKernalConfig(
  baseUrl: 'https://api.myapp.com',
  environment: Environment.development,
  theme: ThemeConfig(
    primaryColor: Color(0xFF6366F1),
    borderRadius: 16.0,
  ),
);

final myEndpoints = [
  Endpoint(
    id: 'getUsers',
    path: '/users',
    method: HttpMethod.get,
    cacheConfig: CacheConfig.medium,
  ),
  Endpoint(
    id: 'createUser',
    path: '/users',
    method: HttpMethod.post,
    invalidates: ['getUsers'], // Refreshes the user list automatically!
  ),
];
```

### 3. Initialize FKernal
Wrap your application entry point:

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FKernal.init(
    config: appConfig,
    endpoints: myEndpoints,
  );
  
  runApp(FKernalApp(child: MyApp()));
}
```

### 4. Build UI Screens
Consume data directly in your widgets without writing business logic.

```dart
class UsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FKernalBuilder<List<User>>(
      resource: 'getUsers',
      builder: (context, users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (_, i) => UserCard(users[i]),
      ),
      // Loading spinner and Error handling are injected automatically!
    );
  }
}
```

---

## 🧠 Core Concepts

### Resource States
Every API request in FKernal goes through a standardized lifecycle:
- `ResourceInitial`: The request hasn't started.
- `ResourceLoading`: Data is being fetched (optionally shows previous data if cached).
- `ResourceData`: Successfully fetched and parsed data.
- `ResourceError`: A typed error occurred (Network, Server, Auth, etc.).

### Local State Slices
Use `FKernalLocalBuilder` for ephemeral UI state. It's faster than `setState` and more organized.

```dart
FKernalLocalBuilder<int>(
  slice: 'main_counter',
  create: () => CounterSlice(initial: 0),
  builder: (context, count, update) => Column(
    children: [
      Text('Count: $count'),
      ElevatedButton(
        onPressed: () => context.updateLocal<int>('main_counter', (c) => c + 1),
        child: Text('Increment'),
      ),
    ],
  ),
)
```

---

## 🛠 Advanced Usage

### Custom Interceptors
Add custom logic to every request, such as adding dynamic headers or custom logging.

```dart
appConfig.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      options.headers['X-Device-ID'] = deviceId;
      return handler.next(options);
    },
  ),
);
```

### Type-Safe Action Builders
Handle mutations (POST, PUT, DELETE) with built-in loading states and snackbars.

```dart
FKernalActionBuilder<User>(
  action: 'createUser',
  onSuccess: (user) => Navigator.pop(context),
  showSuccessSnackbar: true,
  builder: (context, perform, state) => ElevatedButton(
    onPressed: state.isLoading ? null : () => perform(userData),
    child: state.isLoading ? CircularProgressIndicator() : Text('Save User'),
  ),
)
```

---

## 📊 Extension Library
Access all FKernal services through the `BuildContext`:

| Extension | Service | Usage |
| :--- | :--- | :--- |
| `context.stateManager` | Central State | Access any resource state |
| `context.apiClient` | Networking | Manual API calls |
| `context.themeManager` | UI | Dynamic theme switching |
| `context.localState<T>(id)` | Local State | Get ephemeral state values |
| `context.refreshResource(id)` | Networking | Force re-fetch data |

---

## 📦 Built on Giants
FKernal orchestrates these world-class packages:
- **Dio**: The powerful HTTP client for Dart.
- **Hive**: Lightweight and blazing fast key-value database.
- **Provider**: Standardized dependency injection.
- **Connectivity Plus**: Real-time network status monitoring.

---

## 📜 License
Licensed under the [MIT License](LICENSE).
