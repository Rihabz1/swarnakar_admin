import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import '../services/admin_firestore_service.dart';
import 'firebase_providers.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final adminFirestoreServiceProvider = Provider<AdminFirestoreService>((ref) {
  return AdminFirestoreService(ref.watch(firestoreProvider));
});

final authUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final adminRoleProvider = StreamProvider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestoreService = ref.watch(adminFirestoreServiceProvider);
  return authService.authStateChanges().asyncExpand((user) {
    if (user == null) {
      return Stream.value(false);
    }
    return firestoreService
        .doc('users', user.uid)
        .snapshots()
        .map((snapshot) => snapshot.data()?['role'] == 'admin');
  });
});
