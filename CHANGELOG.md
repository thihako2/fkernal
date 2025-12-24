# Changelog

All notable changes to the FKernal package will be documented in this file.

## [1.1.0] - 2025-12-24

### Added
- **Comprehensive Example**: Consolidated all individual examples into a single, feature-complete `example/main.dart` demonstrating everything from networking to complex local state.
- **Documentation Overhaul**: Complete rewrite of `README.md` with deep-dives into core concepts, widget references, and best practices.
- **Type-Safe Resource Access**: Introduced `ResourceKey<T>` for compile-time safety when accessing state.
- **Observability Layer**: Added `KernelObserver` and `KernelEvent` systems for structured runtime monitoring.
- **Firebase Support**: Added `FirebaseNetworkClient` for seamless integration with Firebase services.
- **Decoupled Architecture**: Finalized interfaces for `INetworkClient` and storage providers to allow complete platform customization.

### Changed
- Standardized all widget naming conventions (e.g., `FKernalBuilder` instead of `FBuilder`).
- Enhanced `LocalStorage` with history and undo/redo support.

## [1.0.0] - 2025-12-19

### Added
- **Initial Release**: Launched the configuration-driven Flutter Kernal.
- **Declarative Networking**: Define endpoints as configuration objects with built-in Dio integration.
- **Automated State Management**: Optimized `ResourceState` (Initial, Loading, Data, Error) orchestration.
- **Smart Caching**: Hive-backed binary storage engine with TTL and "Stale-While-Revalidate" support.
- **Design System**: Centralized `ThemeConfig` for unified Material 3 Light and Dark themes.
- **Local State Slices**: specialized slices for UI state management (`ValueSlice`, `ListSlice`, `ToggleSlice`, `CounterSlice`).
- **Context Extensions**: Zero-boilerplate helpers for networking and local state access:
  - `context.fetchResource<T>(id)`
  - `context.performAction<T>(id)`
  - `context.refreshResource<T>(id)`
  - `context.localState<T>(id)`
  - `context.updateLocal<T>(id, updater)`
  - `context.localSlice<T>(id)`
- **Standardized Error Handling**: Unified `FKernalError` types with automatic retry logic and environment-aware logging.
- **Advanced UI Widgets**:
  - `FKernalBuilder`: Reactive data consumption.
  - `FKernalActionBuilder`: Managed mutation feedback.
  - `FKernalLocalBuilder`: Efficient local state listening.
