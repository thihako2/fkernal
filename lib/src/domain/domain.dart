/// FKernal Domain Layer
///
/// The innermost layer containing business logic with no external dependencies.
/// This layer defines:
/// - Entities (core business objects)
/// - Repository interfaces (contracts for data operations)
/// - Use cases (application-specific business rules)
library;

// Failure/Error
export 'failure.dart';

// Entities
export 'entities/entities.dart';

// Repositories
export 'repositories/repositories.dart';

// Use Cases
export 'usecases/usecases.dart';
