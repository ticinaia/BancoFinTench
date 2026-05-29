import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.cpf,
    this.phone,
    this.profileImageBase64,
    this.termsAcceptedAt,
    this.balanceCentavos = AppConstants.initialBalanceCentavos,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String? cpf;
  final String? phone;
  final String? profileImageBase64;
  final DateTime? termsAcceptedAt;
  final int balanceCentavos;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'name': name,
      'cpf': cpf,
      'phone': phone,
      'profileImageBase64': profileImageBase64,
      'termsAcceptedAt': termsAcceptedAt,
      'balanceCentavos': balanceCentavos,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AppUser.fromMap(String id, Map<String, Object?> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      cpf: map['cpf'] as String?,
      phone: map['phone'] as String?,
      profileImageBase64: map['profileImageBase64'] as String?,
      termsAcceptedAt: _optionalDateFrom(map['termsAcceptedAt']),
      balanceCentavos: _intFrom(
        map['balanceCentavos'],
        fallback: AppConstants.initialBalanceCentavos,
      ),
      createdAt: _dateFrom(map['createdAt']),
      updatedAt: _dateFrom(map['updatedAt']),
    );
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _optionalDateFrom(Object? value) {
    if (value == null) return null;
    return _dateFrom(value);
  }

  static int _intFrom(Object? value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }
}
