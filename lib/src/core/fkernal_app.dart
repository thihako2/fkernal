import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../networking/api_client.dart';
import '../networking/endpoint.dart';
import '../networking/endpoint_registry.dart';
import '../state/state_manager.dart';
import '../storage/storage_manager.dart';
import '../storage/default_storage_providers.dart';
import '../error/fkernal_error.dart';
import '../error/error_handler.dart';
import '../state/local_slice.dart';
import '../theme/theme_manager.dart';
import 'environment.dart';
import 'fkernal_config.dart';
import 'interfaces.dart';
import 'observability.dart';

/// Status of the FKernal subsystem.
enum KernelHealthStatus {
  /// Kernel has not been initialized.
  uninitialized,

  /// Kernel is initializing.
  initializing,

  /// Kernel is healthy and ready.
  healthy,

  /// Kernel had a partial failure during initialization.
  degraded,

  /// Kernel failed to initialize.
  failed,
}

/// Main FKernal framework class.
///
/// Use [FKernal.init] to initialize the framework with your configuration,
/// then wrap your app with [FKernalApp] to enable all features.
class FKernal {
  static FKernal? _instance;

  /// The current configuration.
  final FKernalConfig config;

  /// The endpoint registry.
  final EndpointRegistry endpointRegistry;

  /// The network client.
  final INetworkClient networkClient;

  /// The central state manager.
  final StateManager stateManager;

  /// The storage manager for caching and persistence.
  final StorageManager storageManager;

  /// The error handler.
  final ErrorHandler errorHandler;

  /// The theme manager.
  final ThemeManager themeManager;

  /// The kernel observers.
  final List<KernelObserver> observers;

  /// Current health status of the kernel.
  KernelHealthStatus _healthStatus = KernelHealthStatus.uninitialized;

  /// Gets the current health status of the kernel.
  KernelHealthStatus get healthStatus => _healthStatus;

  FKernal._({
    required this.config,
    required this.endpointRegistry,
    required this.networkClient,
    required this.stateManager,
    required this.storageManager,
    required this.errorHandler,
    required this.themeManager,
    this.observers = const [],
  });

  /// Gets the current FKernal instance.
  ///
  /// Throws if [init] has not been called.
  static FKernal get instance {
    if (_instance == null) {
      throw StateError(
        'FKernal has not been initialized. Call FKernal.init() first.',
      );
    }
    return _instance!;
  }

  /// Whether FKernal has been initialized.
  static bool get isInitialized => _instance != null;

  /// Initializes the FKernal framework.
  ///
  /// This should be called once at app startup, before [runApp].
  ///
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///
  ///   await FKernal.init(
  ///     config: FKernalConfig(baseUrl: 'https://api.example.com'),
  ///     endpoints: myEndpoints,
  ///   );
  ///
  ///   runApp(FKernalApp(child: MyApp()));
  /// }
  /// ```
  static Future<FKernal> init({
    required FKernalConfig config,
    required List<Endpoint> endpoints,
    List<KernelObserver> observers = const [],
  }) async {
    if (_instance != null) {
      _log(config, 'FKernal already initialized, returning existing instance');
      return _instance!;
    }

    _log(config, 'Initializing FKernal...');

    try {
      config.validate();
    } catch (e) {
      _log(config, 'Config validation failed: $e');
      throw FKernalError.initialization(
        message: 'Invalid configuration: $e',
        originalError: e,
      );
    }

    final errorHandler = ErrorHandler(environment: config.environment);
    bool isDegraded = false;

    // 1. Initialize Storage
    final storageManager = StorageManager(
      enableCache: config.features.enableCache,
      enableOffline: config.features.enableOffline,
      cacheProvider:
          config.cacheProviderOverride ?? HiveStorageProvider('fkernal_cache'),
      dataProvider:
          config.dataProviderOverride ?? HiveStorageProvider('fkernal_data'),
      secureProvider:
          config.secureProviderOverride ?? DefaultSecureStorageProvider(),
    );

    try {
      await storageManager.init();
      _log(config, 'Storage initialized');
    } catch (e) {
      _log(config, 'Storage initialization failed: $e');
      isDegraded = true;
      errorHandler.handle(FKernalError.initialization(
        message: 'Storage failed to initialize',
        originalError: e,
      ));
    }

    // 2. Initialize Networking
    final endpointRegistry = EndpointRegistry();
    for (final endpoint in endpoints) {
      endpointRegistry.register(endpoint);
    }

    final INetworkClient networkClient = config.networkClientOverride ??
        ApiClient(
          baseUrl: config.baseUrl,
          config: config,
          storageManager: storageManager,
          errorHandler: errorHandler,
        );
    _log(config, 'Network client initialized');

    // 3. Initialize State
    final stateManager = StateManager(
      networkClient: networkClient,
      endpointRegistry: endpointRegistry,
      storageManager: storageManager,
      errorHandler: errorHandler,
      observers: observers,
    );
    _log(config, 'State manager initialized');

    // 4. Initialize Theme
    final themeManager = ThemeManager(config: config.theme);
    _log(config, 'Theme manager initialized');

    _instance = FKernal._(
      config: config,
      endpointRegistry: endpointRegistry,
      networkClient: networkClient,
      stateManager: stateManager,
      storageManager: storageManager,
      errorHandler: errorHandler,
      themeManager: themeManager,
      observers: observers,
    );

    _instance!._healthStatus =
        isDegraded ? KernelHealthStatus.degraded : KernelHealthStatus.healthy;

    _log(
        config, 'FKernal initialization complete: ${_instance!._healthStatus}');
    return _instance!;
  }

  /// Resets the FKernal instance (mainly for testing).
  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.storageManager.dispose();
      _instance = null;
    }
  }

  static void _log(FKernalConfig config, String message) {
    if (config.features.enableLogging && config.environment.shouldLog) {
      debugPrint('[FKernal] $message');
    }
  }

  final Map<String, LocalSlice> _localSlices = {};

  /// Registers a local state slice.
  void registerLocalSlice(String id, LocalSlice slice) {
    _localSlices[id] = slice;
  }

  /// Gets a registered local slice.
  T getLocalSlice<T>(String id) {
    final slice = _localSlices[id];
    if (slice == null) {
      throw StateError('Local slice "$id" not found. Register it first.');
    }
    if (slice is! T) {
      throw StateError(
          'Local slice "$id" is not of type $T. It is ${slice.runtimeType}.');
    }
    return slice as T;
  }

  /// Gets a local slice, registering it if it doesn't exist.
  T getOrRegisterLocalSlice<T>(
      String id, LocalSlice<dynamic> Function() create) {
    if (_localSlices.containsKey(id)) {
      return getLocalSlice<T>(id);
    }

    final newSlice = create();
    registerLocalSlice(id, newSlice);
    return newSlice as T;
  }

  /// Fetches data from an endpoint.
  ///
  /// This is a convenience method that delegates to the state manager.
  Future<T> fetch<T>(
    String endpointId, {
    Map<String, dynamic>? params,
    Map<String, String>? pathParams,
  }) {
    return stateManager.fetch<T>(
      endpointId,
      params: params,
      pathParams: pathParams,
    );
  }

  /// Performs an action (mutation) on an endpoint.
  ///
  /// This is a convenience method that delegates to the state manager.
  Future<T> performAction<T>(
    String endpointId, {
    dynamic payload,
    Map<String, String>? pathParams,
  }) {
    return stateManager.performAction<T>(
      endpointId,
      payload: payload,
      pathParams: pathParams,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Runtime Authentication (Optional)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Optional: Updates the auth token at runtime.
  ///
  /// Use this after login to inject the new token:
  /// ```dart
  /// await authService.login(email, password);
  /// FKernal.instance.updateAuthToken(accessToken);
  /// ```
  void updateAuthToken(String token) {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).updateToken(token);
    }
    _log(config, 'Auth token updated');
  }

  /// Optional: Clears the auth token at runtime.
  ///
  /// Use this on logout to remove the token:
  /// ```dart
  /// await authService.logout();
  /// FKernal.instance.clearAuthToken();
  /// ```
  void clearAuthToken() {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).updateToken(null);
    }
    _log(config, 'Auth token cleared');
  }

  /// Cancels all in-flight requests for a specific endpoint.
  void cancelEndpoint(String endpointId) {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).cancelEndpoint(endpointId);
    }
  }

  /// Cancels all in-flight requests.
  void cancelAllRequests() {
    networkClient.cancelAll();
  }
}

/// Wrapper widget that provides FKernal services to the widget tree.
///
/// Wrap your app with this widget after calling [FKernal.init]:
///
/// ```dart
/// runApp(FKernalApp(child: MyApp()));
/// ```
class FKernalApp extends StatelessWidget {
  /// The child widget (usually your MaterialApp).
  final Widget child;

  const FKernalApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final fkernal = FKernal.instance;

    return MultiProvider(
      providers: [
        Provider.value(value: fkernal.stateManager),
        ChangeNotifierProvider.value(value: fkernal.themeManager),
        Provider.value(value: fkernal.networkClient),
        Provider.value(value: fkernal.errorHandler),
        Provider.value(value: fkernal.storageManager),
        Provider.value(value: fkernal.endpointRegistry),
        Provider.value(value: fkernal.config),
      ],
      child: Builder(
        builder: (context) {
          // Watch theme manager to rebuild on theme changes
          context.watch<ThemeManager>();

          // If child is MaterialApp, we can't easily wrap theme
          // User should use themeManager.theme directly
          return child;
        },
      ),
    );
  }
}
