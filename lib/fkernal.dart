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
library fkernal;

// Core
export 'src/core/fkernal_app.dart';
export 'src/core/fkernal_config.dart';
export 'src/core/environment.dart';
export 'src/core/models/fkernal_model.dart';

// Networking
export 'src/networking/endpoint.dart';
export 'src/networking/http_method.dart';
export 'src/networking/api_client.dart';
export 'src/networking/endpoint_registry.dart';

// State
export 'src/state/resource_state.dart';
export 'src/state/state_manager.dart';
export 'src/state/fkernal_provider.dart';
export 'src/state/local_slice.dart';

// Storage
export 'src/storage/cache_config.dart';
export 'src/storage/storage_manager.dart';

// Error
export 'src/error/fkernal_error.dart';
export 'src/error/error_handler.dart';

// Theme
export 'src/theme/theme_config.dart';
export 'src/theme/theme_manager.dart';

// Widgets
export 'src/widgets/fkernal_builder.dart';
export 'src/widgets/fkernal_action_builder.dart';
export 'src/widgets/fkernal_local_builder.dart';
export 'src/widgets/auto_error_widget.dart';
export 'src/widgets/auto_loading_widget.dart';

// Extensions
export 'src/extensions/context_extensions.dart';
