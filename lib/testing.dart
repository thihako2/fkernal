/// FKernal Testing Utilities
///
/// Import this module to get mock implementations for testing:
///
/// ```dart
/// import 'package:fkernal/testing.dart';
///
/// void main() {
///   final mockClient = MockNetworkClient();
///   mockClient.mockResponse('getUsers', [...]);
///
///   final mockStorage = MockStorageProvider();
///   final mockSecureStorage = MockSecureStorageProvider();
/// }
/// ```
library fkernal_testing;

export 'src/testing/mock_network_client.dart';
export 'src/testing/mock_storage_provider.dart';
