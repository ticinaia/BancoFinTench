import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';

class PixRepository {
  PixRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore? _firestore;

  String get _userId {
    final user = FirebaseService.auth?.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _pixCollection {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firestore ainda nao foi inicializado.');
    }

    return firestore
        .collection(AppConstants.usersCollection)
        .doc(_userId)
        .collection('pix');
  }

  Future<void> enviarPix({
    required String chave,
    required int valorCentavos,
  }) async {
    await _pixCollection.add({
      'chave': chave,
      'valorCentavos': valorCentavos,
      'status': 'concluido',
      'data': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPixHistory() {
    return _pixCollection.orderBy('data', descending: true).snapshots();
  }
}
