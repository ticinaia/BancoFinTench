import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.cpf,
    this.phone,
    this.termsAcceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String name;
  final String? cpf;
  final String? phone;
  final DateTime? termsAcceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'name': name,
      'cpf': cpf,
      'phone': phone,
      'termsAcceptedAt': termsAcceptedAt,
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
      termsAcceptedAt: _optionalDateFrom(map['termsAcceptedAt']),
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
}
