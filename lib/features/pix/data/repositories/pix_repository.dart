import 'package:cloud_firestore/cloud_firestore.dart';

class PixRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> enviarPix({
    required String chave,
    required String valor,
  }) async {
    await firestore.collection('pix').add({
      'chave': chave,
      'valor': valor,
      'data': DateTime.now(),
    });
  }
}