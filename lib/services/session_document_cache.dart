import 'dart:async';

import 'admin_firestore_service.dart';

class SessionDocumentCache {
  SessionDocumentCache._();

  static final Map<String, Map<String, dynamic>?> _documents = {};

  static String _key(String collection, String docId) => '$collection/$docId';

  static bool has(String collection, String docId) {
    return _documents.containsKey(_key(collection, docId));
  }

  static Map<String, dynamic>? get(String collection, String docId) {
    return _documents[_key(collection, docId)];
  }

  static Future<Map<String, dynamic>?> load(
    AdminFirestoreService service,
    String collection,
    String docId, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = _key(collection, docId);
    if (!forceRefresh && _documents.containsKey(cacheKey)) {
      return _documents[cacheKey];
    }

    final data = await service
        .getDoc(collection, docId)
        .timeout(const Duration(seconds: 15));
    _documents[cacheKey] = data;
    return data;
  }

  static void set(String collection, String docId, Map<String, dynamic>? data) {
    _documents[_key(collection, docId)] = data;
  }
}
