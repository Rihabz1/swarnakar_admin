import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFirestoreService {
  AdminFirestoreService(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> doc(String collection, String docId) {
    return _firestore.collection(collection).doc(docId);
  }

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  Stream<Map<String, dynamic>?> watchDoc(String collection, String docId) {
    return doc(collection, docId).snapshots().map((snapshot) => snapshot.data());
  }

  Future<Map<String, dynamic>?> getDoc(String collection, String docId) async {
    final snapshot = await doc(collection, docId).get();
    return snapshot.data();
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchCollection(
    String path, {
    String? orderBy,
    bool descending = false,
  }) {
    Query<Map<String, dynamic>> query = collection(path);
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    return query.snapshots().map((snapshot) => snapshot.docs);
  }

  Future<void> setDoc(
    String collection,
    String docId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) {
    return doc(collection, docId).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDoc(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    return doc(collection, docId).update(data);
  }

  Future<void> deleteDoc(String collection, String docId) {
    return doc(collection, docId).delete();
  }
}
