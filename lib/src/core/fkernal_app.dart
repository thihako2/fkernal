import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../networking/api_client.dart';
import '../networking/endpoint.dart';
import '../networking/endpoint_registry.dart';
import '../state/state_manager.dart';
import '../state/providers.dart';
import '../storage/storage_manager.dart';
import '../storage/default_storage_providers.dart';
import '../error/fkernal_error.dart';
import '../error/error_handler.dart';
import '../state/local_slice.dart';
import '../state/adapters/adapters.dart';
import '../theme/theme_manager.dart';
import 'environment.dart';
import 'fkernal_config.dart';
import 'interfaces.dart';
import 'observability.dart';

/// Status of the FKernal subsystem.
enum KernelHealthStatus {
  uninitialized,
  initializing,
  healthy,
  degraded,
  failed,
}

/// Main FKernal framework class.
class FKernal {
  static FKernal? _instance;

  final FKernalConfig config;
  final EndpointRegistry endpointRegistry;
  final INetworkClient networkClient;
  final StateManager stateManager;
  final StorageManager storageManager;
  final ErrorHandler errorHandler;
  final ThemeManager themeManager;
  final List<KernelObserver> observers;

  /// The Riverpod container holding all state.
  final ProviderContainer container;

  KernelHealthStatus _healthStatus = KernelHealthStatus.uninitialized;
  KernelHealthStatus get healthStatus => _healthStatus;

  FKernal._({
    required this.config,
    required this.endpointRegistry,
    required this.networkClient,
    required this.stateManager,
    required this.storageManager,
    required this.errorHandler,
    required this.themeManager,
    required this.container,
    this.observers = const [],
  });

  static FKernal get instance {
    if (_instance == null) {
      throw StateError(
        'FKernal has not been initialized. Call FKernal.init() first.',
      );
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

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

    // 3. Initialize Theme
    final themeManager = ThemeManager(config: config.theme);
    _log(config, 'Theme manager initialized');

    // 4. Initialize Riverpod Container & State Manager
    final container = config.providerContainerOverride ??
        ProviderContainer(
          overrides: [
            fkernalConfigProvider.overrideWithValue(config),
            networkClientProvider.overrideWithValue(networkClient),
            storageManagerProvider.overrideWithValue(storageManager),
            endpointRegistryProvider.overrideWithValue(endpointRegistry),
            errorHandlerProvider.overrideWithValue(errorHandler),
            observersProvider.overrideWithValue(observers),
          ],
        );

    final stateManager = StateManager(
      container: container,
      adapter: config.stateAdapter,
    );

    // 5. Initialize Local State Factory
    LocalStateAdapter.defaultFactory = config.localStateFactory;

    _log(config, 'State manager initialized');

    _instance = FKernal._(
      config: config,
      endpointRegistry: endpointRegistry,
      networkClient: networkClient,
      stateManager: stateManager,
      storageManager: storageManager,
      errorHandler: errorHandler,
      themeManager: themeManager,
      container: container,
      observers: observers,
    );

    _instance!._healthStatus =
        isDegraded ? KernelHealthStatus.degraded : KernelHealthStatus.healthy;

    _log(
        config, 'FKernal initialization complete: ${_instance!._healthStatus}');
    return _instance!;
  }

  static Future<void> reset() async {
    if (_instance != null) {
      await _instance!.storageManager.dispose();
      _instance!.container.dispose();
      _instance = null;
    }
  }

  static void _log(FKernalConfig config, String message) {
    if (config.features.enableLogging && config.environment.shouldLog) {
      debugPrint('[FKernal] $message');
    }
  }

  final Map<String, LocalSlice> _localSlices = {};

  void registerLocalSlice(String id, LocalSlice slice) {
    _localSlices[id] = slice;
  }

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

  T getOrRegisterLocalSlice<T>(
      String id, LocalSlice<dynamic> Function() create) {
    if (_localSlices.containsKey(id)) {
      return getLocalSlice<T>(id);
    }

    final newSlice = create();
    registerLocalSlice(id, newSlice);
    return newSlice as T;
  }

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

  void updateAuthToken(String token) {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).updateToken(token);
    }
    _log(config, 'Auth token updated');
  }

  void clearAuthToken() {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).updateToken(null);
    }
    _log(config, 'Auth token cleared');
  }

  void cancelEndpoint(String endpointId) {
    if (networkClient is ApiClient) {
      (networkClient as ApiClient).cancelEndpoint(endpointId);
    }
  }

  void cancelAllRequests() {
    networkClient.cancelAll();
  }
}

/// Wrapper widget that provides FKernal services to the widget tree.
class FKernalApp extends StatelessWidget {
  final Widget child;

  const FKernalApp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final fkernal = FKernal.instance;

    return UncontrolledProviderScope(
      container: fkernal.container,
      child: Builder(
        builder: (context) {
          // We can't provide ThemeManager via Provider anymore.
          // Users should use context.themeManager or listenable builder.
          return child;
        },
      ),
    );
  }
}
