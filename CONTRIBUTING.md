# Contributing to FKernal

First off, thank you for considering contributing to FKernal! It's people like you that make FKernal such a great tool for the Flutter community. 🎉

This document provides guidelines and information about contributing to FKernal. Please take a moment to review it before submitting your contribution.

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Pull Requests](#pull-requests)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Design Principles](#design-principles)
- [Release Process](#release-process)

---

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct:

- **Be Respectful**: Treat everyone with respect. No harassment, discrimination, or offensive behavior.
- **Be Collaborative**: Work together constructively. Assume good intentions.
- **Be Inclusive**: Welcome newcomers and help them get started.
- **Be Professional**: Keep discussions focused on the project.

Please report any unacceptable behavior to the project maintainers.

---

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Flutter**: 3.10.0 or higher ([Installation Guide](https://docs.flutter.dev/get-started/install))
- **Dart**: 3.0.0 or higher
- **Git**: For version control
- **IDE**: VS Code with Flutter extension or Android Studio

### Fork and Clone

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/fkernal.git
   cd fkernal
   ```
3. **Add upstream** remote:
   ```bash
   git remote add upstream https://github.com/thihako2/fkernal.git
   ```
4. **Create a branch** for your work:
   ```bash
   git checkout -b feature/your-feature-name
   ```

---

## How Can I Contribute?

### Reporting Bugs

Found a bug? We'd love to hear about it!

**Before submitting:**
- Check if the bug has already been reported in [Issues](https://github.com/thihako2/fkernal/issues)
- Ensure you're using the latest version of FKernal
- Verify the bug is reproducible

**When submitting:**

Use the bug report template and include:

1. **Summary**: A clear, concise description of the bug
2. **Steps to Reproduce**:
   ```
   1. Initialize FKernal with config...
   2. Navigate to screen...
   3. Tap on button...
   4. See error
   ```
3. **Expected Behavior**: What you expected to happen
4. **Actual Behavior**: What actually happened
5. **Environment**:
   - FKernal version: `1.x.x`
   - Flutter version: `flutter --version`
   - Dart version: `dart --version`
   - Platform: iOS/Android/Web/Desktop
   - OS: macOS/Windows/Linux
6. **Code Sample**: Minimal reproducible example
7. **Logs/Screenshots**: If applicable

### Suggesting Enhancements

Have an idea to make FKernal better?

**Before submitting:**
- Check if the enhancement has already been suggested
- Consider if it aligns with FKernal's [design principles](#design-principles)

**When submitting:**

1. **Use Case**: Describe the problem you're trying to solve
2. **Proposed Solution**: How would you solve it?
3. **Alternatives Considered**: Other approaches you've thought about
4. **Examples**: Code snippets or mockups if applicable

### Pull Requests

Ready to contribute code? Awesome! Here's the process:

#### 1. Prepare Your Branch

```bash
# Sync with upstream
git fetch upstream
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
```

#### 2. Make Your Changes

- Follow the [coding standards](#coding-standards)
- Write tests for new functionality
- Update documentation if needed

#### 3. Test Your Changes

```bash
# Run tests
flutter test

# Run analysis
flutter analyze

# Format code
dart format .
```

#### 4. Commit Your Changes

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: type(scope): description
git commit -m "feat(builder): add onEmpty callback to FKernalBuilder"
git commit -m "fix(cache): resolve TTL calculation overflow"
git commit -m "docs(readme): add migration guide section"
```

**Types:**
| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change without feat/fix |
| `test` | Adding tests |
| `chore` | Build, tooling, etc. |

#### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title following conventional commits
- Description of what changed and why
- Reference to related issues (e.g., "Closes #123")
- Screenshots/recordings for UI changes

#### 6. Code Review

- Respond to feedback constructively
- Make requested changes promptly
- Squash commits if requested

---

## Development Setup

### 1. Clone and Install

```bash
git clone https://github.com/thihako2/fkernal.git
cd fkernal/packages/fkernal
flutter pub get
```

### 2. Run Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/core/fkernal_config_test.dart

# With coverage
flutter test --coverage
```

### 3. Run Example App

```bash
cd example
flutter pub get
flutter run
```

### 4. Generate Documentation

```bash
dart doc .
```

---

## Project Structure

```
packages/fkernal/
├── lib/
│   ├── fkernal.dart           # Public API exports
│   └── src/
│       ├── core/              # Core initialization and config
│       │   ├── fkernal_app.dart
│       │   ├── fkernal_config.dart
│       │   ├── environment.dart
│       │   ├── interfaces.dart
│       │   └── observability.dart
│       ├── networking/        # Network layer
│       │   ├── api_client.dart
│       │   ├── endpoint.dart
│       │   ├── endpoint_registry.dart
│       │   └── http_method.dart
│       ├── state/             # State management
│       │   ├── state_manager.dart
│       │   ├── resource_state.dart
│       │   ├── local_slice.dart
│       │   └── resource_key.dart
│       ├── storage/           # Caching and persistence
│       │   ├── storage_manager.dart
│       │   └── cache_config.dart
│       ├── error/             # Error handling
│       │   ├── fkernal_error.dart
│       │   └── error_handler.dart
│       ├── theme/             # Theming
│       │   ├── theme_manager.dart
│       │   └── theme_config.dart
│       ├── widgets/           # Builder widgets
│       │   ├── fkernal_builder.dart
│       │   ├── fkernal_action_builder.dart
│       │   └── fkernal_local_builder.dart
│       └── extensions/        # Context extensions
│           └── context_extensions.dart
├── test/                      # Unit and widget tests
├── example/                   # Example app
├── README.md
├── CHANGELOG.md
└── CONTRIBUTING.md
```

---

## Coding Standards

### Dart Style

We follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines:

```dart
// ✅ Good
class UserService {
  final INetworkClient _client;
  
  UserService(this._client);
  
  Future<User> getUser(int id) async {
    // Implementation
  }
}

// ❌ Bad
class userService {
  INetworkClient? client;
  
  getUser(id) async {
    // Implementation
  }
}
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `FKernalBuilder` |
| Variables | camelCase | `cacheConfig` |
| Constants | camelCase or SCREAMING_SNAKE_CASE | `defaultTimeout` |
| Private | underscore prefix | `_internalState` |
| Files | snake_case | `fkernal_builder.dart` |

### Documentation

All public APIs must have dartdoc comments:

```dart
/// A builder widget that consumes API data reactively.
///
/// [FKernalBuilder] automatically handles loading, error, and empty states.
/// 
/// ## Example
/// 
/// ```dart
/// FKernalBuilder<List<User>>(
///   resource: 'getUsers',
///   builder: (context, users) => UserList(users: users),
/// )
/// ```
/// 
/// See also:
/// * [FKernalActionBuilder], for mutation operations
/// * [FKernalLocalBuilder], for local state
class FKernalBuilder<T> extends StatefulWidget {
  /// The endpoint ID to fetch data from.
  /// 
  /// This must match an endpoint registered during [FKernal.init].
  final String resource;
  
  // ...
}
```

### Linting

We use `very_good_analysis` for strict linting:

```yaml
# analysis_options.yaml
include: package:very_good_analysis/analysis_options.yaml

linter:
  rules:
    public_member_api_docs: true
```

---

## Testing Guidelines

### Test Structure

```dart
void main() {
  group('FKernalBuilder', () {
    testWidgets('shows loading widget while fetching', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: FKernalBuilder<List<User>>(
            resource: 'getUsers',
            builder: (_, users) => Text('${users.length} users'),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows data after successful fetch', (tester) async {
      // ...
    });
  });
}
```

### Test Coverage

- **Unit Tests**: All pure functions and state logic
- **Widget Tests**: All builder widgets
- **Integration Tests**: Critical user flows in example app

Minimum coverage target: **80%**

### Mocking

Use `mocktail` for mocking:

```dart
class MockNetworkClient extends Mock implements INetworkClient {}

setUp(() {
  mockClient = MockNetworkClient();
  when(() => mockClient.request(any())).thenAnswer(
    (_) async => [User(id: 1, name: 'Test')],
  );
});
```

---

## Documentation

### README Updates

Update `README.md` when:
- Adding new features
- Changing public APIs
- Fixing documentation errors

### CHANGELOG Updates

Update `CHANGELOG.md` for every PR:
- Use [Keep a Changelog](https://keepachangelog.com/) format
- Add entry under `[Unreleased]` section
- Include PR number

### API Documentation

Generate and review docs:

```bash
dart doc .
open doc/api/index.html
```

---

## Design Principles

When contributing, please keep these principles in mind:

### 1. Configuration over Implementation

If something can be declared in a config object, it should be:

```dart
// ✅ Good - Configuration
Endpoint(
  id: 'getUsers',
  path: '/users',
  cacheConfig: CacheConfig.medium,
)

// ❌ Avoid - Implementation
class UserRepository {
  Future<List<User>> getUsers() {
    // Manual caching logic
    // Manual error handling
  }
}
```

### 2. Type Safety

Leverage Dart's type system to catch errors at compile time:

```dart
// ✅ Good - Type safe
FKernalBuilder<List<User>>(
  resource: 'getUsers',
  builder: (context, users) => ... // users is List<User>
)

// ❌ Avoid - Dynamic
FKernalBuilder(
  resource: 'getUsers',
  builder: (context, data) => ... // data is dynamic
)
```

### 3. Batteries Included

Provide sensible defaults that work for most apps:

```dart
// Works out of the box with defaults
FKernalBuilder<User>(
  resource: 'getUser',
  builder: (context, user) => Text(user.name),
  // Uses default loading, error, empty widgets
)
```

### 4. Composability

Make components work well together and independently:

```dart
// Nest builders naturally
FKernalBuilder<User>(
  resource: 'getUser',
  builder: (context, user) => FKernalBuilder<List<Post>>(
    resource: 'getUserPosts',
    pathParams: {'userId': user.id.toString()},
    builder: (context, posts) => ...
  ),
)
```

### 5. Performance

Optimize for minimal rebuilds:

```dart
// Uses ValueNotifier for fine-grained updates
// Only rebuilds widgets that depend on changed state
```

---

## Release Process

Releases are managed by maintainers:

1. **Version Bump**: Update version in `pubspec.yaml`
2. **Changelog**: Move `[Unreleased]` to new version
3. **Tag**: Create git tag `v1.x.x`
4. **Publish**: `flutter pub publish`
5. **Announce**: Update GitHub release notes

---

## Questions?

- 📧 Open a [Discussion](https://github.com/thihako2/fkernal/discussions)
- 💬 Join our Discord (coming soon)
- 🐦 Follow updates on Twitter

---

Happy coding! 🚀
