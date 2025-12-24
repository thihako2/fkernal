/// FKernal Data Layer
///
/// This layer implements domain interfaces with concrete external dependencies.
/// Contains:
/// - Data sources (remote and local)
/// - Repository implementations
/// - Dependency injection providers
library;

// Data Sources
export 'datasources/datasources.dart';

// Repository Implementations
export 'repositories/repositories.dart';

// Dependency Injection
export 'di/di.dart';
