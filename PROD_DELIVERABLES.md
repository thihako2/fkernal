# FKernal Project Deliverables

This document provides comprehensive technical specifications, architecture details, and production deployment guidance for the FKernal framework.

---

## 📑 Table of Contents

- [Architecture Overview](#1-architecture-overview)
- [Scalable Folder Structure](#2-scalable-folder-structure)
- [Initialization Flow](#3-initialization-flow)
- [Complete Configuration Reference](#4-complete-configuration-reference)
- [State Management Deep Dive](#5-state-management-deep-dive)
- [Caching Architecture](#6-caching-architecture)
- [Sample UI Patterns](#7-sample-ui-patterns)
- [Extensibility Points](#8-extensibility-points)
- [Performance Considerations](#9-performance-considerations)
- [Production Checklist](#10-production-checklist)
- [Tradeoffs & Limitations](#11-tradeoffs--limitations)
- [Troubleshooting Guide](#12-troubleshooting-guide)

---

## 1. Architecture Overview

### High-Level Diagram

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              APPLICATION LAYER                               │
│     (UI Screens - Pure Functions of State - Zero Business Logic)            │
│                                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ HomeScreen   │  │ UserScreen   │  │ PostScreen   │  │ SettingsScreen│    │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│         │                 │                 │                 │             │
└─────────┼─────────────────┼─────────────────┼─────────────────┼─────────────┘
          │                 │                 │                 │
          ▼                 ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              KERNEL LAYER                                    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        StateManager (Riverpod Container)            │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│   │
│  │  │   Provider  │  │   Provider  │  │   Provider  │  │   Provider  ││   │
│  │  │  getUsers   │  │   getUser   │  │  getPosts   │  │ LocalSlices ││   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘│   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐         │
│  │    ApiClient     │  │  StorageManager  │  │   ThemeManager   │         │
│  │  ┌────────────┐  │  │  ┌────────────┐  │  │  ┌────────────┐  │         │
│  │  │    Dio     │  │  │  │    Hive    │  │  │  │  Material  │  │         │
│  │  │ Interceptors│  │  │  │   Cache    │  │  │  │  Themes    │  │         │
│  │  └────────────┘  │  │  └────────────┘  │  │  └────────────┘  │         │
│  └────────┬─────────┘  └────────┬─────────┘  └──────────────────┘         │
│           │                     │                                          │
│  ┌────────┴─────────────────────┴────────┐  ┌──────────────────┐         │
│  │           ErrorHandler                 │  │  KernelObserver  │         │
│  │  (Normalization + Retry + Logging)     │  │  (Events/Debug)  │         │
│  └────────────────────────────────────────┘  └──────────────────┘         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
          │                     │
          ▼                     ▼
┌──────────────────┐  ┌──────────────────┐
│   External API   │  │  Local Storage   │
│    REST/HTTP     │  │   Hive/Secure    │
└──────────────────┘  └──────────────────┘
```

### Data Flow

```text
User Action → Widget → Ref/Context → StateManager → ApiClient → Server
                                              ↓
                                         StorageManager (Cache)
                                              ↓
User ← Widget ← Consumer(Ref) ← StateManager ← ResourceState<T>
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| **FKernalApp** | Provides kernel context to widget tree via UncontrolledProviderScope |
| **StateManager** | Orchestrates resource states, manages Riverpod providers per resource |
| **ApiClient** | Handles HTTP requests via Dio, applies interceptors, normalizes responses |
| **StorageManager** | Manages cache reads/writes with TTL, handles persistence |
| **ThemeManager** | Generates and switches Material themes based on configuration |
| **ErrorHandler** | Normalizes all errors to FKernalError, handles global callbacks |
| **KernelObserver** | Emits events for debugging, analytics, and monitoring |

---

## 2. Scalable Folder Structure

### Recommended Project Layout

```text
my_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # FKernalApp wrapper
│   │
│   ├── config/                      # 🔧 Configuration
│   │   ├── app_config.dart          # FKernalConfig definition
│   │   ├── endpoints.dart           # All endpoint definitions
│   │   ├── theme_config.dart        # ThemeConfig tokens
│   │   └── feature_flags.dart       # Feature toggles
│   │
│   ├── models/                      # 📦 Data Models
│   │   ├── user.dart
│   │   ├── post.dart
│   │   └── comment.dart
│   │
│   ├── screens/                     # 📱 UI Screens
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── widgets/
│   │   ├── users/
│   │   │   ├── users_screen.dart
│   │   │   ├── user_detail_screen.dart
│   │   │   └── widgets/
│   │   └── settings/
│   │       └── settings_screen.dart
│   │
│   ├── widgets/                     # 🧱 Shared Widgets
│   │   ├── app_bar.dart
│   │   ├── loading_shimmer.dart
│   │   └── error_card.dart
│   │
│   └── utils/                       # 🔨 Utilities
│       ├── extensions.dart
│       └── constants.dart
│
├── test/
│   ├── config/
│   ├── models/
│   ├── screens/
│   └── widgets/
│
└── pubspec.yaml
```

### FKernal Package Structure

```text
packages/fkernal/
├── lib/
│   ├── fkernal.dart                 # Public API exports
│   └── src/
│       ├── core/                    # Core initialization
│       │   ├── fkernal_app.dart     # InheritedWidget provider
│       │   ├── fkernal_config.dart  # Configuration classes
│       │   ├── environment.dart     # Environment enum
│       │   ├── interfaces.dart      # INetworkClient, IStorageProvider
│       │   ├── observability.dart   # KernelObserver, KernelEvent
│       │   └── models/
│       │       └── fkernal_model.dart
│       │
│       ├── networking/              # Network abstraction
│       │   ├── api_client.dart      # Dio-based implementation
│       │   ├── endpoint.dart        # Endpoint definition
│       │   ├── endpoint_registry.dart
│       │   ├── http_method.dart
│       │   └── firebase_network_client.dart
│       │
│       ├── state/                   # State management
│       │   ├── state_manager.dart   # Central state orchestrator
│       │   ├── resource_state.dart  # Sealed state classes
│       │   ├── local_slice.dart     # Local state containers
│       │   ├── fkernal_provider.dart
│       │   └── resource_key.dart    # Type-safe resource keys
│       │
│       ├── storage/                 # Caching and persistence
│       │   ├── storage_manager.dart
│       │   ├── cache_config.dart
│       │   └── default_storage_providers.dart
│       │
│       ├── error/                   # Error normalization
│       │   ├── fkernal_error.dart
│       │   └── error_handler.dart
│       │
│       ├── theme/                   # Design system
│       │   ├── theme_manager.dart
│       │   └── theme_config.dart
│       │
│       ├── widgets/                 # Builder widgets
│       │   ├── fkernal_builder.dart
│       │   ├── fkernal_action_builder.dart
│       │   ├── fkernal_local_builder.dart
│       │   ├── auto_error_widget.dart
│       │   ├── auto_loading_widget.dart
│       │   └── auto_empty_widget.dart
│       │
│       └── extensions/              # Context extensions
│           └── context_extensions.dart
│
├── test/
├── example/
└── pubspec.yaml
```

---

## 3. Initialization Flow

### Sequence Diagram

```text
main() 
  │
  ├──▶ WidgetsFlutterBinding.ensureInitialized()
  │
  ├──▶ FKernal.init(config, endpoints, observers?)
  │       │
  │       ├──▶ Validate configuration
  │       │
  │       ├──▶ Initialize Hive for caching
  │       │       └──▶ Open cache box
  │       │
  │       ├──▶ Create StorageManager
  │       │       └──▶ Load persisted theme preference
  │       │
  │       ├──▶ Create ApiClient with Dio
  │       │       ├──▶ Configure base URL
  │       │       ├──▶ Add auth interceptor
  │       │       ├──▶ Add retry interceptor
  │       │       └──▶ Add logging interceptor (dev only)
  │       │
  │       ├──▶ Create EndpointRegistry
  │       │       └──▶ Register all endpoints by ID
  │       │
  │       ├──▶ Create StateManager
  │       │       └──▶ Initialize ProviderContainer with overrides
  │       │
  │       ├──▶ Create ThemeManager
  │       │       └──▶ Generate light/dark themes
  │       │
  │       ├──▶ Register observers (if any)
  │       │
  │       └──▶ Return FKernal instance with health status
  │
  └──▶ runApp(FKernalApp(child: MyApp()))
          │
          └──▶ Provides UncontrolledProviderScope
```

### Initialization Example

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with full configuration
  final kernel = await FKernal.init(
    config: appConfig,
    endpoints: appEndpoints,
    observers: [
      if (kDebugMode) DebugObserver(),
      AnalyticsObserver(FirebaseAnalytics.instance),
    ],
  );

  // Optional: Check initialization health
  if (kernel.healthStatus == KernelHealthStatus.degraded) {
    debugPrint('⚠️ Kernel initialized with warnings');
  }

  // Pre-fetch critical data (optional)
  await kernel.preFetch(['getConfig', 'getCurrentUser']);

  runApp(FKernalApp(child: const MyApp()));
}
```

---

## 4. Complete Configuration Reference

### FKernalConfig

```dart
const appConfig = FKernalConfig(
  // ═══════════════════════════════════════════════════════════════════
  // REQUIRED
  // ═══════════════════════════════════════════════════════════════════
  
  /// Base URL for all API requests (no trailing slash)
  baseUrl: 'https://api.myapp.com/v1',
  
  /// Environment affects logging verbosity, error details, mock support
  environment: Environment.production,
  
  // ═══════════════════════════════════════════════════════════════════
  // AUTHENTICATION (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  /// Bearer token authentication
  auth: AuthConfig.bearer('initial-token'),
  
  /// OR API Key authentication
  // auth: AuthConfig.apiKey('X-API-Key', 'your-api-key'),
  
  /// OR Custom authentication
  // auth: AuthConfig.custom(
  //   headerName: 'Authorization',
  //   tokenProvider: () async => secureStorage.read('token'),
  // ),
  
  // ═══════════════════════════════════════════════════════════════════
  // FEATURE FLAGS (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  features: FeatureFlags(
    /// Enable/disable caching globally
    enableCache: true,
    
    /// Enable offline mode (serve stale data when offline)
    enableOffline: true,
    
    /// Auto-retry failed requests
    enableAutoRetry: true,
    
    /// Maximum retry attempts
    maxRetryAttempts: 3,
    
    /// Initial retry delay (doubles each attempt)
    retryDelay: Duration(seconds: 1),
    
    /// Enable request/response logging (dev only recommended)
    enableLogging: false,
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // CACHING (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  /// Default cache configuration for endpoints without explicit config
  defaultCacheConfig: CacheConfig(
    duration: Duration(minutes: 5),
    staleWhileRevalidate: true,
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // PAGINATION (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  pagination: PaginationConfig(
    /// Default page size
    pageSize: 30,
    
    /// Query parameter for page/offset
    pageParam: 'offset',
    
    /// Query parameter for limit
    limitParam: 'limit',
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // NETWORK (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  /// Connection timeout in milliseconds
  connectTimeout: 30000,
  
  /// Response receive timeout in milliseconds
  receiveTimeout: 30000,
  
  /// Custom headers for all requests
  defaultHeaders: {
    'X-App-Version': '1.0.0',
    'X-Platform': Platform.operatingSystem,
  },
  
  // ═══════════════════════════════════════════════════════════════════
  // THEMING (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  theme: ThemeConfig(
    primaryColor: Color(0xFF1E3A8A),
    secondaryColor: Color(0xFF8B5CF6),
    tertiaryColor: Color(0xFF06B6D4),
    errorColor: Color(0xFFEF4444),
    
    fontFamily: 'Inter',
    
    useMaterial3: true,
    defaultThemeMode: ThemeMode.system,
    
    borderRadius: 12.0,
    defaultPadding: 16.0,
    cardElevation: 2.0,
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // ERROR HANDLING (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  errorConfig: ErrorConfig(
    /// Show snackbar for errors automatically
    showSnackbars: true,
    
    /// Global error handler
    onGlobalError: (error) {
      // Log to analytics
      FirebaseAnalytics.instance.logEvent(name: 'api_error', parameters: {
        'type': error.type.name,
        'message': error.message,
        'statusCode': error.statusCode,
      });
      
      // Report to crash service
      FirebaseCrashlytics.instance.recordError(
        error.originalError,
        error.stackTrace,
      );
    },
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // EXTENSIBILITY (Optional)
  // ═══════════════════════════════════════════════════════════════════
  
  /// Override default Dio-based network client
  // networkClientOverride: MyGraphQLClient(),
  
  /// Override default Hive-based cache provider
  // cacheProviderOverride: SQLiteCacheProvider(),
  
  /// Override default secure storage
  // secureProviderOverride: BiometricSecureStorage(),
);
```

### Endpoint Configuration

```dart
final appEndpoints = <Endpoint>[
  // ═══════════════════════════════════════════════════════════════════
  // GET Request with Caching
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'getUsers',
    path: '/users',
    method: HttpMethod.get,
    cacheConfig: CacheConfig(
      duration: Duration(minutes: 10),
      staleWhileRevalidate: true,
    ),
    parser: (json) => (json as List)
        .map((u) => User.fromJson(Map<String, dynamic>.from(u)))
        .toList(),
    description: 'Fetches all users with 10-minute cache',
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // GET with Path Parameters
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'getUser',
    path: '/users/{id}',           // {id} is replaced at runtime
    method: HttpMethod.get,
    cacheConfig: CacheConfig.long, // 1 hour
    requiresAuth: true,
    parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // POST with Cache Invalidation
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'createUser',
    path: '/users',
    method: HttpMethod.post,
    invalidates: ['getUsers'],     // Clears getUsers cache on success
    requiresAuth: true,
    parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // PUT/PATCH with Multiple Invalidations
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'updateUser',
    path: '/users/{id}',
    method: HttpMethod.put,
    invalidates: ['getUsers', 'getUser'], // Clears both caches
    requiresAuth: true,
    parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'deleteUser',
    path: '/users/{id}',
    method: HttpMethod.delete,
    invalidates: ['getUsers'],
    requiresAuth: true,
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // No Caching (Real-time Data)
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'getNotifications',
    path: '/notifications',
    method: HttpMethod.get,
    cacheConfig: CacheConfig.none, // Always fetch fresh
    requiresAuth: true,
    parser: (json) => (json as List)
        .map((n) => Notification.fromJson(n))
        .toList(),
  ),
  
  // ═══════════════════════════════════════════════════════════════════
  // Custom Headers
  // ═══════════════════════════════════════════════════════════════════
  Endpoint(
    id: 'uploadFile',
    path: '/files/upload',
    method: HttpMethod.post,
    headers: {'Content-Type': 'multipart/form-data'},
    requiresAuth: true,
  ),
];
```

---

## 5. State Management Deep Dive

### ResourceState Lifecycle

```text
┌─────────────────────────────────────────────────────────────────┐
│                    ResourceState<T> Lifecycle                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ResourceInitial ──(fetch)──▶ ResourceLoading                  │
│                                      │                          │
│                          ┌───────────┴───────────┐              │
│                          ▼                       ▼              │
│                   ResourceData<T>         ResourceError         │
│                          │                       │              │
│                          ├──(refresh)────────────┤              │
│                          ▼                       ▼              │
│                   ResourceLoading         ResourceLoading       │
│                          │                       │              │
│                          └───────────┬───────────┘              │
│                                      ▼                          │
│                            (success or error)                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Riverpod Architecture

```dart
// Each resource is managed by a StateNotifier provider family
final resourceProvider = StateNotifierProvider.family<ResourceNotifier, ResourceState, ResourceKey>(
  (ref, key) => ResourceNotifier(ref, key),
);

// StateManager orchestrates these providers
class StateManager {
  final ProviderContainer container;
  
  void updateState<T>(String resourceId, ResourceState<T> state) {
    // Updates propagate through the container to all listeners (Consumers)
  }
}
```

### Local Slices

```dart
// Generic slice with optional history
class LocalSlice<T> {
  final T _initialState;
  final bool enableHistory;
  final int maxHistoryLength;
  
  T _state;
  final List<T> _history = [];
  int _historyIndex = -1;
  
  T get state => _state;
  
  void update(T Function(T current) updater) {
    if (enableHistory) {
      // Trim future history if we're not at the end
      if (_historyIndex < _history.length - 1) {
        _history.removeRange(_historyIndex + 1, _history.length);
      }
      _history.add(_state);
      if (_history.length > maxHistoryLength) {
        _history.removeAt(0);
      }
      _historyIndex = _history.length - 1;
    }
    
    _state = updater(_state);
    _notifier.value = _state;
  }
  
  void undo() {
    if (_historyIndex > 0) {
      _historyIndex--;
      _state = _history[_historyIndex];
      _notifier.value = _state;
    }
  }
  
  void redo() {
    if (_historyIndex < _history.length - 1) {
      _historyIndex++;
      _state = _history[_historyIndex];
      _notifier.value = _state;
    }
  }
}
```

---

## 6. Caching Architecture

### Cache Flow

```text
Request for "getUsers"
         │
         ▼
┌────────────────────┐
│  Check Cache       │
│  (by resource ID)  │
└────────┬───────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
 Cache      Cache
  Hit        Miss
    │         │
    │         ▼
    │   ┌─────────────┐
    │   │ Fetch from  │
    │   │   Network   │
    │   └──────┬──────┘
    │          │
    │          ▼
    │   ┌─────────────┐
    │   │ Store in    │
    │   │   Cache     │
    │   └──────┬──────┘
    │          │
    └────┬─────┘
         │
         ▼
  Return ResourceData<T>
```

### Stale-While-Revalidate

```text
Request for "getUsers" (SWR enabled, cache expired)
         │
         ▼
┌────────────────────┐
│  Return Stale Data │◀────── Immediate response
│  (from cache)      │
└────────┬───────────┘
         │
         ▼ (async)
┌────────────────────┐
│  Fetch Fresh Data  │
│  (in background)   │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Update Cache      │
│  Notify Listeners  │◀────── Widget rebuilds with fresh data
└────────────────────┘
```

### Cache Key Generation

```dart
String generateCacheKey({
  required String endpointId,
  Map<String, dynamic>? params,
  Map<String, String>? pathParams,
}) {
  final parts = [endpointId];
  
  if (pathParams != null && pathParams.isNotEmpty) {
    final sortedPath = SplayTreeMap<String, String>.from(pathParams);
    parts.add('path:${sortedPath.toString()}');
  }
  
  if (params != null && params.isNotEmpty) {
    final sortedParams = SplayTreeMap<String, dynamic>.from(params);
    parts.add('query:${sortedParams.toString()}');
  }
  
  return parts.join('::');
}

// Examples:
// "getUsers" → "getUsers"
// "getUser" with pathParams: {id: "123"} → "getUsers::path:{id: 123}"
// "getUsers" with params: {limit: 10, status: "active"} 
//   → "getUsers::query:{limit: 10, status: active}"
```

---

## 7. Sample UI Patterns

### Pattern 1: Master-Detail with Nested Builders

```dart
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: FKernalBuilder<List<User>>(
        resource: 'getUsers',
        builder: (context, users) => ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailScreen(userId: user.id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final int userId;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FKernalBuilder<User>(
        resource: 'getUser',
        pathParams: {'id': userId.toString()},
        builder: (context, user) => Column(
          children: [
            Text(user.name),
            
            // Nested builder for user's posts
            Expanded(
              child: FKernalBuilder<List<Post>>(
                resource: 'getUserPosts',
                pathParams: {'userId': userId.toString()},
                builder: (context, posts) => ListView(
                  children: posts.map((p) => PostCard(post: p)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 2: Form with Local State

```dart
class CreateUserScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FKernalMapBuilder<String, dynamic>(
      slice: 'createUserForm',
      create: () => MapSlice({}),
      builder: (context, formData, slice) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create User')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  onChanged: (v) => slice.set('name', v),
                ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  onChanged: (v) => slice.set('email', v),
                ),
                const SizedBox(height: 24),
                
                FKernalActionBuilder<User>(
                  endpoint: 'createUser',
                  builder: (context, isLoading, perform) {
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final user = await perform(payload: formData);
                              if (user != null && context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Create'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### Pattern 3: Pull-to-Refresh with Error Retry

```dart
class PostsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FKernalBuilder<List<Post>>(
        resource: 'getPosts',
        builder: (context, posts) => RefreshIndicator(
          onRefresh: () => context.refreshResource<List<Post>>('getPosts'),
          child: ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(post: posts[i]),
          ),
        ),
        errorBuilder: (context, error, retry) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(error.message, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 8. Extensibility Points

### Custom Network Client (GraphQL)

```dart
class GraphQLNetworkClient implements INetworkClient {
  final GraphQLClient _client;

  GraphQLNetworkClient(this._client);

  @override
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
    dynamic payload,
    Map<String, String>? headers,
  }) async {
    final operation = _buildOperation(endpoint, params, payload);
    
    final result = await _client.query(
      QueryOptions(
        document: gql(operation),
        variables: params ?? {},
      ),
    );

    if (result.hasException) {
      throw _mapToFKernalError(result.exception!);
    }

    return endpoint.parser?.call(result.data) ?? result.data as T;
  }

  String _buildOperation(Endpoint endpoint, params, payload) {
    // Map endpoint to GraphQL query or mutation
    if (endpoint.method == HttpMethod.get) {
      return '''
        query ${endpoint.id} {
          ${endpoint.path}(${_buildArgs(params)}) {
            ... fields
          }
        }
      ''';
    } else {
      return '''
        mutation ${endpoint.id}(\$input: ${endpoint.id}Input!) {
          ${endpoint.path}(input: \$input) {
            ... fields
          }
        }
      ''';
    }
  }

  FKernalError _mapToFKernalError(OperationException e) {
    if (e.linkException != null) {
      return const FKernalError(
        type: FKernalErrorType.network,
        message: 'Network error',
      );
    }
    return FKernalError(
      type: FKernalErrorType.server,
      message: e.graphqlErrors.first.message,
    );
  }

  @override
  void updateAuthToken(String? token) {
    // Update auth link
  }

  @override
  void dispose() {}
}
```

### Custom Cache Provider (SQLite)

```dart
class SQLiteCacheProvider implements IStorageProvider {
  final Database _db;

  SQLiteCacheProvider(this._db);

  @override
  Future<void> init() async {
    await _db.execute('''
      CREATE TABLE IF NOT EXISTS cache (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        expires_at INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    
    // Create index for expiration queries
    await _db.execute('''
      CREATE INDEX IF NOT EXISTS idx_expires_at ON cache(expires_at)
    ''');
  }

  @override
  Future<T?> read<T>(String key) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final result = await _db.query(
      'cache',
      where: 'key = ? AND expires_at > ?',
      whereArgs: [key, now],
    );

    if (result.isEmpty) return null;
    
    final json = jsonDecode(result.first['value'] as String);
    return json as T;
  }

  @override
  Future<void> write<T>(String key, T value, {Duration? ttl}) async {
    final now = DateTime.now();
    final expiresAt = ttl != null
        ? now.add(ttl).millisecondsSinceEpoch
        : now.add(const Duration(days: 365)).millisecondsSinceEpoch;

    await _db.insert(
      'cache',
      {
        'key': key,
        'value': jsonEncode(value),
        'expires_at': expiresAt,
        'created_at': now.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> delete(String key) async {
    await _db.delete('cache', where: 'key = ?', whereArgs: [key]);
  }

  @override
  Future<void> clear() async {
    await _db.delete('cache');
  }

  @override
  void dispose() {
    _db.close();
  }
}
```

---

## 9. Performance Considerations

### Memory Management

| Strategy | Implementation |
|----------|----------------|
| **Fine-grained updates** | Each resource has its own Provider; only affected Consumer widgets rebuild |
| **Cache size limits** | Configure maximum cache entries to prevent memory bloat |
| **Dispose resources** | Riverpod handles disposal (autoDispose) or via ProviderContainer disposal |
| **Lazy initialization** | Resources are only created when first accessed |

### Network Optimization

| Strategy | Implementation |
|----------|----------------|
| **Request deduplication** | Concurrent requests for same resource share single network call |
| **Stale-While-Revalidate** | Return cached data immediately, fetch in background |
| **Connection pooling** | Dio maintains connection pool for HTTP/2 multiplexing |
| **Request cancellation** | Dispose widgets cancel in-flight requests |

### Rendering Performance

```dart
// ✅ Good - Only rebuilds when getUsers changes
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  builder: (context, users) => UserList(users: users),
)

// ❌ Bad - Rebuilds on ANY state change
Builder(
  builder: (context) {
    final state = context.stateManager; // Watches everything
    return UserList(users: state.getResource('getUsers').data);
  },
)
```

---

## 10. Production Checklist

### Pre-Launch Checklist

- [ ] **Environment**: Set `environment: Environment.production`
- [ ] **Logging**: Set `enableLogging: false` in feature flags
- [ ] **Error Reporting**: Configure `onGlobalError` with crash reporting
- [ ] **Cache Strategy**: Review and set appropriate TTLs for all endpoints
- [ ] **Authentication**: Implement token refresh logic
- [ ] **Offline Mode**: Test offline behavior with cached data
- [ ] **Error Messages**: Ensure user-facing error messages are helpful

### Monitoring Setup

```dart
// Analytics Observer
class ProductionObserver extends KernelObserver {
  final FirebaseAnalytics analytics;
  final FirebaseCrashlytics crashlytics;

  ProductionObserver(this.analytics, this.crashlytics);

  @override
  void onEvent(KernelEvent event) {
    switch (event) {
      case RequestCompleted(:final endpoint, :final duration):
        // Track API performance
        analytics.logEvent(name: 'api_request', parameters: {
          'endpoint': endpoint.id,
          'duration_ms': duration.inMilliseconds,
          'status': 'success',
        });
        break;
        
      case RequestFailed(:final endpoint, :final error):
        // Log errors
        analytics.logEvent(name: 'api_request', parameters: {
          'endpoint': endpoint.id,
          'status': 'error',
          'error_type': error.type.name,
        });
        
        // Report to Crashlytics
        crashlytics.recordError(error.originalError, error.stackTrace);
        break;
        
      case CacheHit(:final key):
        analytics.logEvent(name: 'cache_hit', parameters: {'key': key});
        break;
        
      default:
        break;
    }
  }
}
```

---

## 11. Tradeoffs & Limitations

### Tradeoffs

| Tradeoff | Benefit | Cost |
|----------|---------|------|
| **Convention over Configuration** | Faster development, consistent patterns | Learning curve for "The Kernel Way" |
| **Runtime Registry** | No code generation needed | Endpoint ID typos not caught at compile time (mitigated by ResourceKey) |
| **Single Instance** | Simple wiring, predictable state | Multi-kernel apps are harder (rare use case) |
| **Hive for Cache** | Fast binary storage, cross-platform | Additional dependency, migration complexity |

### Limitations

| Limitation | Workaround |
|------------|------------|
| **Highly custom UI transitions** | Use raw StateManager for complex animation-driven state |
| **Extreme performance (games)** | Not designed for 60fps game loops; use dedicated game engines |
| **Legacy SOAP APIs** | Implement custom INetworkClient with SOAP transformation |
| **WebSocket/Real-time** | Currently requires manual integration (planned for 2.0) |
| **Complex form validation** | Use dedicated form library alongside FKernal |

### When NOT to Use FKernal

- **AAA Mobile Games**: Use Unity, Unreal, or Flame
- **Offline-First Apps**: Use Isar or ObjectBox with custom sync
- **Complex Spreadsheet UIs**: Consider dedicated table/grid libraries
- **Apps with 100+ distinct API endpoints**: Code generation might be preferred

---

## 12. Troubleshooting Guide

### Common Issues

#### "Endpoint not found" Error

```dart
// ❌ Problem: Endpoint ID doesn't match
await context.fetchResource('getuser'); // lowercase 'u'

// ✅ Solution: Use exact ID from endpoint definition
await context.fetchResource('getUser'); // matches Endpoint(id: 'getUser')
```

#### Widget Not Rebuilding

```dart
// ❌ Problem: Not using reactive builder
final users = context.stateManager.getResource('getUsers');

// ✅ Solution: Use FKernalBuilder or useResource
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  builder: (context, users) => ...,
)
// OR
final state = context.useResource<List<User>>('getUsers');
```

#### Cache Not Invalidating

```dart
// ❌ Problem: Missing invalidates configuration
Endpoint(
  id: 'createUser',
  path: '/users',
  method: HttpMethod.post,
  // Missing: invalidates: ['getUsers'],
)

// ✅ Solution: Add invalidates array
Endpoint(
  id: 'createUser',
  path: '/users',
  method: HttpMethod.post,
  invalidates: ['getUsers'], // Now clears cache on success
)
```

#### Type Mismatch in Parser

```dart
// ❌ Problem: Direct json cast fails
parser: (json) => User.fromJson(json), // json might be Map<dynamic, dynamic>

// ✅ Solution: Explicitly cast to Map<String, dynamic>
parser: (json) => User.fromJson(Map<String, dynamic>.from(json)),

// For lists:
parser: (json) => (json as List)
    .map((u) => User.fromJson(Map<String, dynamic>.from(u)))
    .toList(),
```

#### "No FKernalApp Found" Error

```dart
// ❌ Problem: FKernalApp not in widget tree
runApp(MaterialApp(home: MyScreen()));

// ✅ Solution: Wrap with FKernalApp
runApp(FKernalApp(
  child: MaterialApp(home: MyScreen()),
));
```

### Debug Mode Tips

```dart
// Enable verbose logging in development
const config = FKernalConfig(
  environment: Environment.development,
  features: FeatureFlags(
    enableLogging: true, // Logs all requests/responses
  ),
);

// Add debug observer
await FKernal.init(
  config: config,
  endpoints: endpoints,
  observers: [if (kDebugMode) DebugObserver()],
);

class DebugObserver extends KernelObserver {
  @override
  void onEvent(KernelEvent event) {
    debugPrint('[FKernal] ${event.runtimeType}: $event');
  }
}
```

---

## Resources

- [Full API Documentation](https://pub.dev/documentation/fkernal/latest/)
- [Example App Source](https://github.com/thihako2/fkernal/tree/main/example)
- [GitHub Issues](https://github.com/thihako2/fkernal/issues)
- [Discord Community](https://discord.gg/fkernal) (coming soon)
