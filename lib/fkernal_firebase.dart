/// FKernal Firebase Integration
///
/// This is an optional module for Firebase/Firestore integration.
///
/// ## Installation
///
/// 1. Add Firebase dependencies to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   cloud_firestore: ^5.0.1
///   firebase_auth: ^5.1.0
///   firebase_storage: ^12.0.1
/// ```
///
/// 2. Import this module instead of the main fkernal:
/// ```dart
/// import 'package:fkernal/fkernal_firebase.dart';
/// ```
///
/// ## Usage
///
/// ```dart
/// await FKernal.init(
///   config: FKernalConfig(
///     baseUrl: '', // Not used for Firebase
///     networkClientOverride: FirebaseNetworkClient(),
///   ),
///   endpoints: firebaseEndpoints,
/// );
/// ```
library fkernal_firebase;

// Re-export everything from main fkernal
export 'fkernal.dart';

// Firebase-specific exports
export 'src/networking/firebase_network_client.dart';
