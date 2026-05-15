import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../domain/models/app_user.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore? _firestore;

  bool get isAvailable => _firestore != null;

  CollectionReference<Map<String, dynamic>> get _users {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firestore ainda nao foi inicializado.');
    }
    return firestore.collection(AppConstants.usersCollection);
  }

  Future<void> createOrUpdate(AppUser user) async {
    final docRef = _users.doc(user.id);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update({
        'email': user.email,
        'name': user.name,
        'updatedAt': user.updatedAt,
      });
      return;
    }

    await docRef.set(user.toMap());
  }

  Future<AppUser?> findById(String id) async {
    final snapshot = await _users.doc(id).get();
    final data = snapshot.data();
    if (data == null) return null;
    return AppUser.fromMap(snapshot.id, data);
  }

  Stream<AppUser?> watchById(String id) {
    return _users.doc(id).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUser.fromMap(snapshot.id, data);
    });
  }
}
