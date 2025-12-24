import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/resource_repository.dart';
import '../../domain/usecases/fetch_resource.dart';
import '../../domain/usecases/perform_action.dart';
import '../datasources/network_client_adapter.dart';
import '../datasources/storage_provider_adapter.dart';
import '../repositories/resource_repository_impl.dart';
import '../../state/providers.dart';

/// Provider for the [RemoteDataSource] using the existing network client.
final remoteDataSourceProvider = Provider((ref) {
  final networkClient = ref.watch(networkClientProvider);
  return NetworkClientAdapter(networkClient);
});

/// Provider for the [LocalDataSource] using the existing cache provider.
/// Returns null if caching is disabled.
final localDataSourceProvider = Provider<StorageProviderAdapter?>((ref) {
  final storageManager = ref.watch(storageManagerProvider);
  final cacheProvider = storageManager.cacheProvider;
  if (cacheProvider == null) return null;
  return StorageProviderAdapter(cacheProvider);
});

/// Provider for the [ResourceRepository].
final resourceRepositoryProvider = Provider<ResourceRepository>((ref) {
  final remoteDataSource = ref.watch(remoteDataSourceProvider);
  final localDataSource = ref.watch(localDataSourceProvider);
  return ResourceRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
});

/// Provider factory for [FetchResourceUseCase].
///
/// Usage:
/// ```dart
/// final useCase = ref.watch(fetchResourceUseCaseProvider);
/// final result = await useCase(FetchResourceParams(endpoint: myEndpoint));
/// ```
final fetchResourceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(resourceRepositoryProvider);
  return FetchResourceUseCase(repository);
});

/// Provider factory for [PerformActionUseCase].
///
/// Usage:
/// ```dart
/// final useCase = ref.watch(performActionUseCaseProvider);
/// final result = await useCase(PerformActionParams(endpoint: myEndpoint, body: data));
/// ```
final performActionUseCaseProvider = Provider((ref) {
  final repository = ref.watch(resourceRepositoryProvider);
  return PerformActionUseCase(repository);
});

/// Provider factory for [WatchResourceUseCase].
///
/// Usage:
/// ```dart
/// final useCase = ref.watch(watchResourceUseCaseProvider);
/// final stream = useCase(WatchResourceParams(endpoint: myEndpoint));
/// ```
final watchResourceUseCaseProvider = Provider((ref) {
  final repository = ref.watch(resourceRepositoryProvider);
  return WatchResourceUseCase(repository);
});
