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
      throw StateError('Usuário não autenticado.');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> get _userDoc {
    final firestore = _firestore;
    if (firestore == null) {
      throw StateError('Firestore ainda não foi inicializado.');
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

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPixHistory(
      {int limit = 50}) {
    try {
      return _pixCollection
          .orderBy('data', descending: true)
          .limit(limit)
          .snapshots();
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

  Stream<PixSummary> watchMonthlySummary() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1);

    try {
      return _pixCollection
          .where('createdAt', isGreaterThanOrEqualTo: monthStart)
          .where('createdAt', isLessThan: nextMonth)
          .snapshots()
          .map(_summaryFromSnapshot);
    } catch (error) {
      return Stream<PixSummary>.error(error);
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
      throw StateError('Favoritos indisponíveis neste ambiente.');
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
    final cacheKey = '${_userId}_${monthStart.year}_${monthStart.month}';
    final cached = _monthlySummaryCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.summary;
    }

    final summary = await _calculateMonthlySummary(monthStart);
    _monthlySummaryCache[cacheKey] = _MonthlySummaryCache(summary, now);
    return summary;
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
      throw StateError('Informe a chave Pix.');
    }

    final favorite = await _findFavoriteRecipient(normalizedKey);
    if (favorite != null) return favorite;

    return PixRecipient(
      name: 'Destinatário de demonstração',
      bank: 'Banco de demonstração',
      key: normalizedKey,
      keyType: keyType,
      document: 'Simulação Pix',
      isVerified: true,
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
      throw StateError('Pix indisponível neste ambiente.');
    }

    if (valorCentavos <= 0) {
      throw StateError('Informe um valor válido.');
    }

    final now = DateTime.now();
    final docRef = _pixCollection.doc();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dailySent = await _calculateDailySentCentavos(dayStart);

    try {
      await _firestore!.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(_userDoc);
        final userData = userSnapshot.data();
        final balance = _balanceFrom(userData);

        if (dailySent + valorCentavos > dailyLimitCentavos) {
          throw StateError('Você atingiu o limite diário de Pix.');
        }

        if (balance < valorCentavos) {
          throw StateError('Seu saldo não cobre esse Pix.');
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
    } on StateError catch (error) {
      if (error.message == 'Você atingiu o limite diário de Pix.') {
        await _registerNotification(
          type: 'daily_limit',
          title: 'Limite diário atingido',
          body: 'Essa transferência ultrapassa seu limite diário de Pix.',
        );
      }
      rethrow;
    }

    await _registerNotification(
      type: 'balance_changed',
      title: 'Saldo atualizado',
      body: 'Pix enviado no valor de '
          '${BrFormatters.currencyFromCentavos(valorCentavos)}.',
    );
    _clearMonthlySummaryCache();

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
      throw StateError('Pix indisponível neste ambiente.');
    }

    if (valorCentavos <= 0) {
      throw StateError('Informe um valor válido.');
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
        'recipientDocument': 'Pagador de demonstração',
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
      title: 'Pix recebido',
      body: 'Você recebeu um Pix de '
          '${BrFormatters.currencyFromCentavos(valorCentavos)}.',
    );
    _clearMonthlySummaryCache();

    return PixReceipt(
      id: docRef.id,
      chave: chave,
      tipoChave: tipoChave,
      recipientName: payerName,
      recipientBank: payerBank,
      recipientDocument: 'Pagador de demonstração',
      valorCentavos: valorCentavos,
      direction: 'received',
      transactionType: 'pix',
      status: 'concluido',
      createdAt: now,
    );
  }

  Future<void> cancelPendingPix(String id) async {
    final docRef = _pixCollection.doc(id);
    final existingSnapshot = await docRef.get();
    final existingData = existingSnapshot.data();
    if (existingData == null) {
      throw StateError('Pix não encontrado.');
    }

    final existingStatus = (existingData['status'] ?? '').toString();
    if (existingStatus != 'pendente') {
      throw StateError('Somente Pix pendente pode ser cancelado.');
    }

    await _firestore!.runTransaction((transaction) async {
      final pixSnapshot = await transaction.get(docRef);
      final pixData = pixSnapshot.data();

      if (pixData == null) {
        throw StateError('Pix não encontrado.');
      }

      final status = (pixData['status'] ?? '').toString();
      if (status != 'pendente') {
        throw StateError('Somente Pix pendente pode ser cancelado.');
      }

      final value = _intFrom(pixData['valorCentavos']);
      final direction = (pixData['direction'] ?? 'sent').toString();
      final userSnapshot = await transaction.get(_userDoc);
      final balance = _balanceFrom(userSnapshot.data());
      final balanceDelta = direction == 'received' ? -value : value;

      transaction.update(docRef, {
        'status': 'cancelado',
        'cancelledAt': DateTime.now(),
      });
      transaction.update(_userDoc, {
        'balanceCentavos': balance + balanceDelta,
        'updatedAt': DateTime.now(),
      });
    });
    _clearMonthlySummaryCache();
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

  Future<PixSummary> _calculateMonthlySummary(DateTime monthStart) async {
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
    final snapshot = await _pixCollection
        .where('createdAt', isGreaterThanOrEqualTo: monthStart)
        .where('createdAt', isLessThan: nextMonth)
        .get();

    return _summaryFromDocs(snapshot.docs);
  }

  Future<int> _calculateDailySentCentavos(DateTime dayStart) async {
    final nextDay = DateTime(dayStart.year, dayStart.month, dayStart.day + 1);
    final snapshot = await _pixCollection
        .where('createdAt', isGreaterThanOrEqualTo: dayStart)
        .where('createdAt', isLessThan: nextDay)
        .get();

    var sentCentavos = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if ((data['direction'] ?? 'sent') != 'sent') continue;
      if ((data['status'] ?? 'concluido') == 'cancelado') continue;
      sentCentavos += _intFrom(data['valorCentavos']);
    }

    return sentCentavos;
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
      // Notificações internas não podem desfazer uma operação financeira.
    }
  }

  static String _normalizeKey(String key) {
    return key.trim().toLowerCase().replaceAll('/', '_');
  }

  static PixSummary _summaryFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return _summaryFromDocs(snapshot.docs);
  }

  static PixSummary _summaryFromDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    var entradas = 0;
    var saidas = 0;

    for (final doc in docs) {
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

  static int _balanceFrom(Map<String, dynamic>? data) {
    return _intFrom(data?['balanceCentavos'], fallback: initialBalanceCentavos);
  }

  static int _intFrom(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  static final Map<String, _MonthlySummaryCache> _monthlySummaryCache = {};

  void _clearMonthlySummaryCache() {
    final prefix = '${_userId}_';
    _monthlySummaryCache.removeWhere((key, _) => key.startsWith(prefix));
  }
}

class _MonthlySummaryCache {
  _MonthlySummaryCache(this.summary, this.createdAt);

  final PixSummary summary;
  final DateTime createdAt;

  bool get isExpired {
    return DateTime.now().difference(createdAt) > const Duration(minutes: 5);
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
      name: (data['name'] ?? 'Contato Pix').toString(),
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
