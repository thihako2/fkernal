# Changelog

All notable changes to the FKernal package will be documented in this file.

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
