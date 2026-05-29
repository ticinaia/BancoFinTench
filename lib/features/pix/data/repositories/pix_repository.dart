import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/br_formatters.dart';

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

  CollectionReference<Map<String, dynamic>> get _favoritesCollection {
    return _userDoc.collection('pix_favorites');
  }

  CollectionReference<Map<String, dynamic>> get _notificationsCollection {
    return _userDoc.collection('notifications');
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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFavoriteRecipients() {
    try {
      return _favoritesCollection
          .orderBy('lastUsedAt', descending: true)
          .limit(8)
          .snapshots();
    } catch (error) {
      return Stream<QuerySnapshot<Map<String, dynamic>>>.error(error);
    }
  }

  Future<void> saveFavoriteRecipient(PixRecipient recipient) async {
    if (!isAvailable) {
      throw StateError('Favoritos indisponiveis neste ambiente.');
    }

    final now = DateTime.now();
    final normalizedKey = _normalizeKey(recipient.key);
    await _favoritesCollection.doc(normalizedKey).set(
      {
        'name': recipient.name,
        'bank': recipient.bank,
        'key': recipient.key,
        'normalizedKey': normalizedKey,
        'keyType': recipient.keyType,
        'document': recipient.document,
        'updatedAt': now,
        'lastUsedAt': now,
      },
      SetOptions(merge: true),
    );
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

    final favorite = await _findFavoriteRecipient(normalizedKey);
    if (favorite != null) return favorite;

    return PixRecipient(
      name: 'Destinatário não verificado',
      bank: 'Chave PIX informada pelo usuário',
      key: normalizedKey,
      keyType: keyType,
      document: 'Não verificado',
      isVerified: false,
      isFavorite: false,
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
      await _registerNotification(
        type: 'daily_limit',
        title: 'Limite diário atingido',
        body: 'Essa transferência ultrapassa seu limite diário de PIX.',
      );
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
        'transactionType': 'pix',
        'status': 'concluido',
        'data': FieldValue.serverTimestamp(),
        'createdAt': now,
      });
    });

    await _registerNotification(
      type: 'balance_changed',
      title: 'Saldo atualizado',
      body: 'PIX enviado no valor de '
          '${BrFormatters.currencyFromCentavos(valorCentavos)}.',
    );

    return PixReceipt(
      id: docRef.id,
      chave: chave,
      tipoChave: tipoChave,
      recipientName: recipient.name,
      recipientBank: recipient.bank,
      recipientDocument: recipient.document,
      valorCentavos: valorCentavos,
      direction: 'sent',
      transactionType: 'pix',
      status: 'concluido',
      createdAt: now,
    );
  }

  Future<PixReceipt> receberPix({
    required String chave,
    required String tipoChave,
    required int valorCentavos,
    required String payerName,
    required String payerBank,
  }) async {
    if (!isAvailable) {
      throw StateError('Pix indisponivel neste ambiente.');
    }

    if (valorCentavos <= 0) {
      throw StateError('Informe um valor valido.');
    }

    final now = DateTime.now();
    final docRef = _pixCollection.doc();

    await _firestore!.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(_userDoc);
      final balance = _balanceFrom(userSnapshot.data());

      transaction.set(
        _userDoc,
        {
          'balanceCentavos': balance + valorCentavos,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      transaction.set(docRef, {
        'chave': chave,
        'tipoChave': tipoChave,
        'recipientName': payerName,
        'recipientBank': payerBank,
        'recipientDocument': 'Pagador simulado',
        'valorCentavos': valorCentavos,
        'direction': 'received',
        'transactionType': 'pix',
        'status': 'concluido',
        'data': FieldValue.serverTimestamp(),
        'createdAt': now,
      });
    });

    await _registerNotification(
      type: 'pix_received',
      title: 'PIX recebido',
      body: 'Você recebeu um PIX de '
          '${BrFormatters.currencyFromCentavos(valorCentavos)}.',
    );

    return PixReceipt(
      id: docRef.id,
      chave: chave,
      tipoChave: tipoChave,
      recipientName: payerName,
      recipientBank: payerBank,
      recipientDocument: 'Pagador simulado',
      valorCentavos: valorCentavos,
      direction: 'received',
      transactionType: 'pix',
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

  Future<PixRecipient?> _findFavoriteRecipient(String key) async {
    if (!isAvailable) return null;

    try {
      final normalizedKey = _normalizeKey(key);
      final snapshot = await _favoritesCollection.doc(normalizedKey).get();
      final data = snapshot.data();
      if (data == null) return null;
      return PixFavoriteRecipient.fromDoc(snapshot).toRecipient();
    } catch (_) {
      return null;
    }
  }

  Future<void> _registerNotification({
    required String type,
    required String title,
    required String body,
  }) async {
    if (!isAvailable) return;
    try {
      await _notificationsCollection.add({
        'type': type,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': DateTime.now(),
      });
    } catch (_) {
      // Notificacoes internas nao podem desfazer uma operacao financeira.
    }
  }

  static String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll('/', '_');
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
    this.isVerified = true,
    this.isFavorite = false,
  });

  final String name;
  final String bank;
  final String key;
  final String keyType;
  final String document;
  final bool isVerified;
  final bool isFavorite;
}

class PixFavoriteRecipient {
  const PixFavoriteRecipient({
    required this.id,
    required this.name,
    required this.bank,
    required this.key,
    required this.keyType,
    required this.document,
  });

  factory PixFavoriteRecipient.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return PixFavoriteRecipient(
      id: doc.id,
      name: (data['name'] ?? 'Contato PIX').toString(),
      bank: (data['bank'] ?? 'Banco não informado').toString(),
      key: (data['key'] ?? '').toString(),
      keyType: (data['keyType'] ?? 'E-mail').toString(),
      document: (data['document'] ?? 'Salvo pelo usuário').toString(),
    );
  }

  final String id;
  final String name;
  final String bank;
  final String key;
  final String keyType;
  final String document;

  PixRecipient toRecipient() {
    return PixRecipient(
      name: name,
      bank: bank,
      key: key,
      keyType: keyType,
      document: document,
      isFavorite: true,
    );
  }
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
    this.direction = 'sent',
    this.transactionType = 'pix',
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
  final String direction;
  final String transactionType;
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
      'direction': direction,
      'transactionType': transactionType,
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
      direction: map['direction'] as String? ?? 'sent',
      transactionType: map['transactionType'] as String? ?? 'pix',
      status: map['status'].toString(),
      createdAt: date is DateTime ? date : DateTime.now(),
    );
  }
}
