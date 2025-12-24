import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/interfaces.dart';
import 'endpoint.dart';

/// Firebase Implementation of INetworkClient.
/// Fully utilizes Firestore, Auth, and Storage.
class FirebaseNetworkClient implements INetworkClient {
  @override
  final String baseUrl;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseNetworkClient({this.baseUrl = ''});

  @override
  Future<T> request<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
    dynamic body,
  }) async {
    final path = endpoint.buildPath(pathParams);

    if (endpoint.requiresAuth && _auth.currentUser == null) {
      throw Exception('Authentication required for endpoint: ${endpoint.id}');
    }

    // Handle Storage requests
    if (path.startsWith('storage://')) {
      return _handleStorageRequest<T>(endpoint, path, body);
    }

    try {
      final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

      if (pathSegments.length % 2 == 0) {
        // Document path
        final docRef = _firestore.doc(path);

        if (body != null) {
          final enrichedBody = _enrichData(body);
          await docRef.set(enrichedBody, SetOptions(merge: true));
          return enrichedBody as T;
        } else {
          final snapshot = await docRef.get();
          final data = snapshot.data();
          if (data == null) throw Exception('Document not found at $path');

          final enrichedData = _attachMetadata(data, snapshot.id);
          return endpoint.parser != null
              ? endpoint.parser!(enrichedData) as T
              : enrichedData as T;
        }
      } else {
        // Collection path
        final colRef = _firestore.collection(path);

        if (body != null) {
          final enrichedBody = _enrichData(body);
          final doc = await colRef.add(enrichedBody);
          final data = {...enrichedBody, 'id': doc.id};
          return data as T;
        } else {
          Query query = _applyQueries(colRef, queryParams);
          final snapshot = await query.get();
          final list = snapshot.docs
              .map((d) =>
                  _attachMetadata(d.data() as Map<String, dynamic>, d.id))
              .toList();

          return endpoint.parser != null
              ? endpoint.parser!(list) as T
              : list as T;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<T> watch<T>(
    Endpoint endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? pathParams,
  }) {
    final path = endpoint.buildPath(pathParams);

    if (endpoint.requiresAuth && _auth.currentUser == null) {
      throw Exception('Authentication required for watching: ${endpoint.id}');
    }

    final pathSegments = path.split('/').where((s) => s.isNotEmpty).toList();

    if (pathSegments.length % 2 == 0) {
      // Watch Document
      return _firestore.doc(path).snapshots().map((snapshot) {
        final data = snapshot.data();
        if (data == null) throw Exception('Document not found at $path');
        final enrichedData = _attachMetadata(data, snapshot.id);
        return endpoint.parser != null
            ? endpoint.parser!(enrichedData) as T
            : enrichedData as T;
      });
    } else {
      // Watch Collection
      Query query = _applyQueries(_firestore.collection(path), queryParams);
      return query.snapshots().map((snapshot) {
        final list = snapshot.docs
            .map((d) => _attachMetadata(d.data() as Map<String, dynamic>, d.id))
            .toList();
        return endpoint.parser != null
            ? endpoint.parser!(list) as T
            : list as T;
      });
    }
  }

  /// Handles Firebase Storage operations.
  /// Expects paths like 'storage://bucket/path/to/file'.
  Future<T> _handleStorageRequest<T>(
      Endpoint endpoint, String path, dynamic body) async {
    final storagePath = path.replaceFirst('storage://', '');
    final ref = _storage.ref(storagePath);

    if (body != null && body is File) {
      // Upload
      final uploadTask = await ref.putFile(body);
      final url = await uploadTask.ref.getDownloadURL();
      return {'url': url} as T;
    } else if (body != null && body is List<int>) {
      // Upload bytes
      final uploadTask = await ref.putData(Uint8List.fromList(body));
      final url = await uploadTask.ref.getDownloadURL();
      return {'url': url} as T;
    } else {
      // Download URL
      final url = await ref.getDownloadURL();
      return {'url': url} as T;
    }
  }

  /// Appends standard metadata like userId and timestamp.
  Map<String, dynamic> _enrichData(dynamic body) {
    if (body is! Map<String, dynamic>) return body;

    final enriched = Map<String, dynamic>.from(body);
    final user = _auth.currentUser;

    if (user != null) {
      enriched['userId'] = user.uid;
      enriched['updatedBy'] = user.email ?? user.uid;
    }

    enriched['updatedAt'] = FieldValue.serverTimestamp();
    return enriched;
  }

  /// Attaches Firestore metadata (ID) to the data map.
  Map<String, dynamic> _attachMetadata(Map<String, dynamic> data, String id) {
    return {...data, 'id': id};
  }

  /// Applies query parameters (orderBy, limit, where) to a Firestore query.
  Query _applyQueries(Query initialQuery, Map<String, dynamic>? params) {
    Query query = initialQuery;
    if (params == null) return query;

    params.forEach((key, value) {
      if (key == '_orderBy') {
        query = query.orderBy(value.toString());
      } else if (key == '_orderByDesc') {
        query = query.orderBy(value.toString(), descending: true);
      } else if (key == '_limit') {
        query = query.limit(int.parse(value.toString()));
      } else if (key == '_startAfter') {
        query = query.startAfter([value]);
      } else if (key == '_where') {
        // Expects format {field: [operator, value]}
        if (value is Map) {
          value.forEach((field, condition) {
            if (condition is List && condition.length == 2) {
              final op = condition[0];
              final val = condition[1];
              switch (op) {
                case '==':
                  query = query.where(field, isEqualTo: val);
                  break;
                case '<':
                  query = query.where(field, isLessThan: val);
                  break;
                case '>':
                  query = query.where(field, isGreaterThan: val);
                  break;
              }
            }
          });
        }
      } else {
        // Default equality check for other params
        query = query.where(key, isEqualTo: value);
      }
    });

    return query;
  }

  @override
  void cancelAll() {}

  @override
  void dispose() {}
}
