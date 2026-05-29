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
      final data = <String, Object?>{
        'email': user.email,
        'name': user.name,
        'updatedAt': user.updatedAt,
      };

      if (user.cpf != null) data['cpf'] = user.cpf;
      if (user.phone != null) data['phone'] = user.phone;
      if (user.profileImageBase64 != null) {
        data['profileImageBase64'] = user.profileImageBase64;
      }

      await docRef.update(data);
      return;
    }

    await docRef.set(user.toMap());
  }

  Future<void> updateProfile({
    required String id,
    required String name,
    required String cpf,
    required String phone,
  }) async {
    await _users.doc(id).set(
      {
        'name': name,
        'cpf': cpf,
        'phone': phone,
        'updatedAt': DateTime.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateProfileImage({
    required String id,
    required String profileImageBase64,
  }) async {
    await _users.doc(id).set(
      {
        'profileImageBase64': profileImageBase64,
        'updatedAt': DateTime.now(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> registerAccessLog({
    required String userId,
    required String action,
    required String platform,
  }) async {
    await _users.doc(userId).collection('accessLogs').add({
      'action': action,
      'platform': platform,
      'createdAt': DateTime.now(),
    });
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
