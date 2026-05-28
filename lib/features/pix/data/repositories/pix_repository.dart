import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';

class PixRepository {
  PixRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseService.firestore;

  final FirebaseFirestore? _firestore;

  bool get isAvailable => _firestore != null && FirebaseService.auth != null;

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
    if (!isAvailable) {
      throw StateError('Pix indisponivel neste ambiente.');
    }

    await _pixCollection.add({
      'chave': chave,
      'valorCentavos': valorCentavos,
      'status': 'concluido',
      'data': FieldValue.serverTimestamp(),
      'createdAt': DateTime.now(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPixHistory() {
    try {
      return _pixCollection.orderBy('data', descending: true).snapshots();
    } catch (error) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(error);
    }
  }
}
