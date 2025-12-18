import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../networking/api_client.dart';
import '../networking/endpoint.dart';
import '../networking/endpoint_registry.dart';
import '../state/state_manager.dart';
import '../storage/storage_manager.dart';
import '../error/error_handler.dart';
import '../state/local_slice.dart';
import '../theme/theme_manager.dart';
import 'environment.dart';
import 'fkernal_config.dart';

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

  /// The API client for making network requests.
  final ApiClient apiClient;

  /// The central state manager.
  final StateManager stateManager;

  /// The storage manager for caching and persistence.
  final StorageManager storageManager;

  /// The error handler.
  final ErrorHandler errorHandler;

  /// The theme manager.
  final ThemeManager themeManager;

  FKernal._({
    required this.config,
    required this.endpointRegistry,
    required this.apiClient,
    required this.stateManager,
    required this.storageManager,
    required this.errorHandler,
    required this.themeManager,
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
  }) async {
    if (_instance != null) {
      _log(config, 'FKernal already initialized, returning existing instance');
      return _instance!;
    }

    _log(config, 'Initializing FKernal...');

    // Initialize error handler first to capture any init errors
    final errorHandler = ErrorHandler(environment: config.environment);

    // Initialize storage
    final storageManager = StorageManager(
      enableCache: config.features.enableCache,
      enableOffline: config.features.enableOffline,
    );
    await storageManager.init();
    _log(config, 'Storage initialized');

    // Initialize endpoint registry
    final endpointRegistry = EndpointRegistry();
    for (final endpoint in endpoints) {
      endpointRegistry.register(endpoint);
    }
    _log(config, 'Registered ${endpoints.length} endpoints');

    // Initialize API client
    final apiClient = ApiClient(
      baseUrl: config.baseUrl,
      config: config,
      storageManager: storageManager,
      errorHandler: errorHandler,
    );
    _log(config, 'API client initialized');

    // Initialize state manager with auto-generated slices
    final stateManager = StateManager(
      apiClient: apiClient,
      endpointRegistry: endpointRegistry,
      storageManager: storageManager,
      errorHandler: errorHandler,
    );
    _log(config, 'State manager initialized');

    // Initialize theme manager
    final themeManager = ThemeManager(config: config.theme);
    _log(config, 'Theme manager initialized');

    _instance = FKernal._(
      config: config,
      endpointRegistry: endpointRegistry,
      apiClient: apiClient,
      stateManager: stateManager,
      storageManager: storageManager,
      errorHandler: errorHandler,
      themeManager: themeManager,
    );

    _log(config, 'FKernal initialization complete');
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
        ChangeNotifierProvider.value(value: fkernal.stateManager),
        ChangeNotifierProvider.value(value: fkernal.themeManager),
        Provider.value(value: fkernal.apiClient),
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
