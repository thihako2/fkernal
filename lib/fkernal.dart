/// FKernal - Configuration-driven Flutter framework
///
/// A framework that lets developers focus solely on UI screens while
/// automatically handling networking, state management, storage,
/// error handling, and theming based on simple configuration constants.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:fkernal/fkernal.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   await FKernal.init(
///     config: FKernalConfig(
///       baseUrl: 'https://api.example.com',
///       environment: Environment.development,
///     ),
///     endpoints: [
///       Endpoint(id: 'getUsers', path: '/users', method: HttpMethod.get),
///     ],
///   );
///
///   runApp(FKernalApp(child: MyApp()));
/// }
/// ```
///
/// ## Clean Architecture
///
/// FKernal follows Clean Architecture principles with three layers:
/// - **Domain**: Core business logic (entities, repositories, use cases)
/// - **Data**: External implementations (data sources, repository implementations)
/// - **Presentation**: UI components (widgets, providers, extensions)
library fkernal;

// =============================================================================
// CLEAN ARCHITECTURE LAYERS
// =============================================================================

// Domain Layer - Business logic (entities, repositories, use cases)
export 'src/domain/domain.dart';

// Data Layer - External implementations (data sources, repository implementations)
export 'src/data/data.dart';

// Presentation Layer - UI components (widgets, providers, extensions)
export 'src/presentation/presentation.dart';

// =============================================================================
// CORE - Framework essentials not covered by Clean Architecture layers
// =============================================================================

// App initialization
export 'src/core/fkernal_app.dart';
export 'src/core/fkernal_config.dart';
export 'src/core/environment.dart';
export 'src/core/models/fkernal_model.dart';
export 'src/core/interfaces.dart';
export 'src/core/observability.dart';

// Networking (not moved to data layer - these are framework core)
export 'src/networking/endpoint.dart';
export 'src/networking/http_method.dart';
export 'src/networking/api_client.dart';
export 'src/networking/endpoint_registry.dart';

// Storage (not moved - these are framework core)
export 'src/storage/cache_config.dart';
export 'src/storage/storage_manager.dart';
export 'src/storage/default_storage_providers.dart';

// Error handling
export 'src/error/fkernal_error.dart';
export 'src/error/error_handler.dart';

// Theme
export 'src/theme/theme_config.dart';
export 'src/theme/theme_manager.dart';

// State Management
export 'src/state/adapters/state_adapter.dart';
export 'src/state/adapters/local_state_adapter.dart';
