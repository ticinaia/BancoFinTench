import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';

class PixRepository {
  PixRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseService.firestore;

  static const int initialBalanceCentavos = AppConstants.initialBalanceCentavos;
  static const int dailyLimitCentavos = AppConstants.pixDailyLimitCentavos;

  final FirebaseFirestore? _firestore;

  bool get isAvailable => _firestore != null && FirebaseService.auth != null;

  String get _userId {
    final user = FirebaseService.auth?.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firestore ainda nao foi inicializado.');
    }

    return firestore.collection(AppConstants.usersCollection).doc(_userId);
  }

  CollectionReference<Map<String, dynamic>> get _pixCollection {
    return _userDoc.collection('pix');
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAccount() {
    try {
      return _userDoc.snapshots();
    } catch (error) {
      return Stream<DocumentSnapshot<Map<String, dynamic>>>.error(error);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPixHistory() {
    try {
      return _pixCollection.orderBy('data', descending: true).snapshots();
    } catch (error) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(error);
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentPix({int limit = 3}) {
    try {
      return _pixCollection
          .orderBy('data', descending: true)
          .limit(limit)
          .snapshots();
    } catch (error) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(error);
    }
  }

  Future<PixSummary> getMonthlySummary() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);

    final snapshot = await _pixCollection
        .where('createdAt', isGreaterThanOrEqualTo: monthStart)
        .get();

    var entradas = 0;
    var saidas = 0;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final value = _intFrom(data['valorCentavos']);
      final direction = (data['direction'] ?? 'sent').toString();
      final status = (data['status'] ?? 'concluido').toString();

      if (status == 'cancelado') continue;
      if (direction == 'received') {
        entradas += value;
      } else {
        saidas += value;
      }
    }

    return PixSummary(
      entradasCentavos: entradas,
      saidasCentavos: saidas,
    );
  }

  Future<int> getBalanceCentavos() async {
    final snapshot = await _userDoc.get();
    return _balanceFrom(snapshot.data());
  }

  Future<PixRecipient> resolveRecipient({
    required String keyType,
    required String key,
  }) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw StateError('Informe a chave PIX.');
    }

    final seed = normalizedKey.codeUnits.fold<int>(
      0,
      (previous, value) => previous + value,
    );
    final names = [
      'Marina Costa',
      'Lucas Almeida',
      'Beatriz Rocha',
      'Rafael Mendes',
      'Camila Ferreira',
    ];

    return PixRecipient(
      name: names[seed % names.length],
      bank: 'Banco parceiro ${100 + (seed % 899)}',
      key: normalizedKey,
      keyType: keyType,
      document: '***.${(seed % 900 + 100)}.${(seed % 900 + 100)}-**',
    );
  }

  Future<PixReceipt> enviarPix({
    required String chave,
    required String tipoChave,
    required int valorCentavos,
    required PixRecipient recipient,
  }) async {
    if (!isAvailable) {
      throw StateError('Pix indisponivel neste ambiente.');
    }

    if (valorCentavos <= 0) {
      throw StateError('Informe um valor valido.');
    }

    final dailySent = await _dailySentCentavos();
    if (dailySent + valorCentavos > dailyLimitCentavos) {
      throw StateError('Limite diario de PIX excedido.');
    }

    final now = DateTime.now();
    final docRef = _pixCollection.doc();

    await _firestore!.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(_userDoc);
      final userData = userSnapshot.data();
      final balance = _balanceFrom(userData);

      if (balance < valorCentavos) {
        throw StateError('Saldo insuficiente para enviar este PIX.');
      }

      if (!userSnapshot.exists) {
        transaction.set(
            _userDoc,
            {
              'balanceCentavos': initialBalanceCentavos - valorCentavos,
              'updatedAt': now,
            },
            SetOptions(merge: true));
      } else {
        transaction.update(_userDoc, {
          'balanceCentavos': balance - valorCentavos,
          'updatedAt': now,
        });
      }

      transaction.set(docRef, {
        'chave': chave,
        'tipoChave': tipoChave,
        'recipientName': recipient.name,
        'recipientBank': recipient.bank,
        'recipientDocument': recipient.document,
        'valorCentavos': valorCentavos,
        'direction': 'sent',
        'status': 'concluido',
        'data': FieldValue.serverTimestamp(),
        'createdAt': now,
      });
    });

    return PixReceipt(
      id: docRef.id,
      chave: chave,
      tipoChave: tipoChave,
      recipientName: recipient.name,
      recipientBank: recipient.bank,
      recipientDocument: recipient.document,
      valorCentavos: valorCentavos,
      status: 'concluido',
      createdAt: now,
    );
  }

  Future<void> cancelPendingPix(String id) async {
    final docRef = _pixCollection.doc(id);

    await _firestore!.runTransaction((transaction) async {
      final pixSnapshot = await transaction.get(docRef);
      final pixData = pixSnapshot.data();

      if (pixData == null) {
        throw StateError('PIX nao encontrado.');
      }

      final status = (pixData['status'] ?? '').toString();
      if (status != 'pendente') {
        throw StateError('Somente PIX pendente pode ser cancelado.');
      }

      final value = _intFrom(pixData['valorCentavos']);
      final userSnapshot = await transaction.get(_userDoc);
      final balance = _balanceFrom(userSnapshot.data());

      transaction.update(docRef, {
        'status': 'cancelado',
        'cancelledAt': DateTime.now(),
      });
      transaction.update(_userDoc, {
        'balanceCentavos': balance + value,
        'updatedAt': DateTime.now(),
      });
    });
  }

  Future<int> _dailySentCentavos() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);

    final snapshot = await _pixCollection
        .where('createdAt', isGreaterThanOrEqualTo: dayStart)
        .get();

    var total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['direction'] ?? 'sent') != 'sent') continue;
      if ((data['status'] ?? 'concluido') == 'cancelado') continue;
      total += _intFrom(data['valorCentavos']);
    }
    return total;
  }

  static int _balanceFrom(Map<String, dynamic>? data) {
    return _intFrom(data?['balanceCentavos'], fallback: initialBalanceCentavos);
  }

  static int _intFrom(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }
}

class PixSummary {
  const PixSummary({
    required this.entradasCentavos,
    required this.saidasCentavos,
  });

  final int entradasCentavos;
  final int saidasCentavos;
}

class PixRecipient {
  const PixRecipient({
    required this.name,
    required this.bank,
    required this.key,
    required this.keyType,
    required this.document,
  });

  final String name;
  final String bank;
  final String key;
  final String keyType;
  final String document;
}

class PixReceipt {
  const PixReceipt({
    required this.id,
    required this.chave,
    required this.tipoChave,
    required this.recipientName,
    required this.recipientBank,
    required this.recipientDocument,
    required this.valorCentavos,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String chave;
  final String tipoChave;
  final String recipientName;
  final String recipientBank;
  final String recipientDocument;
  final int valorCentavos;
  final String status;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'chave': chave,
      'tipoChave': tipoChave,
      'recipientName': recipientName,
      'recipientBank': recipientBank,
      'recipientDocument': recipientDocument,
      'valorCentavos': valorCentavos,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory PixReceipt.fromMap(Map<String, Object?> map) {
    final date = map['createdAt'];

    return PixReceipt(
      id: map['id'].toString(),
      chave: map['chave'].toString(),
      tipoChave: map['tipoChave'].toString(),
      recipientName: map['recipientName'].toString(),
      recipientBank: map['recipientBank'].toString(),
      recipientDocument: map['recipientDocument'].toString(),
      valorCentavos: PixRepository._intFrom(map['valorCentavos']),
      status: map['status'].toString(),
      createdAt: date is DateTime ? date : DateTime.now(),
    );
  }
}
