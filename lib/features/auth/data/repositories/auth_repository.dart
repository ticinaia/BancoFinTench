import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/firebase_service.dart';
import '../../domain/models/app_user.dart';
import '../services/auth_session_service.dart';
import '../services/auth_security_service.dart';
import 'user_repository.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    UserRepository? userRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseService.auth,
        _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth? _firebaseAuth;
  final UserRepository _userRepository;

  bool get isAvailable => _firebaseAuth != null;

  User? get currentUser => _firebaseAuth?.currentUser;

  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda não foi inicializado.');
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final appUser = await _saveAuthenticatedUser(credential, email);
    await _registerAccessLog(action: 'login');
    return appUser;
  }

  Future<AppUser> createUser({
    required String email,
    required String password,
    required String name,
    required String cpf,
    required String phone,
    required bool acceptedTerms,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda não foi inicializado.');
    }

    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    try {
      await credential.user?.updateDisplayName(name);
    } catch (_) {
      // O perfil local no Firestore ainda guarda o nome informado.
    }

    try {
      await credential.user?.sendEmailVerification();
    } catch (_) {
      // A tela de verificação permite reenviar caso o primeiro envio falhe.
    }

    final appUser = await _saveAuthenticatedUser(
      credential,
      email,
      name: name,
      cpf: cpf,
      phone: phone,
      termsAcceptedAt: acceptedTerms ? DateTime.now() : null,
    );
    await _registerAccessLog(action: 'account_created');
    return appUser;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda não foi inicializado.');
    }

    await auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadCurrentUser() async {
    await currentUser?.reload();
  }

  Future<bool> hasAppPin() async {
    final user = currentUser;
    if (user == null) return false;
    return AuthSecurityService.hasPin(user.uid);
  }

  Future<void> saveAppPin(String pin) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    await AuthSecurityService.savePin(userId: user.uid, pin: pin);
  }

  Future<bool> validateAppPin(String pin) async {
    final user = currentUser;
    if (user == null) return false;
    return AuthSecurityService.validatePin(userId: user.uid, pin: pin);
  }

  Future<void> changeAppPin({
    required String currentPin,
    required String newPin,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    final valid = await validateAppPin(currentPin);
    if (!valid) {
      throw StateError('PIN atual incorreto.');
    }

    await AuthSecurityService.savePin(userId: user.uid, pin: newPin);
  }

  Future<AppUser?> currentAppUser() async {
    final user = currentUser;
    if (user == null || !_userRepository.isAvailable) return null;
    return _userRepository.findById(user.uid);
  }

  Future<void> updateProfile({
    required String name,
    required String cpf,
    required String phone,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    await user.updateDisplayName(name);

    if (_userRepository.isAvailable) {
      await _userRepository.updateProfile(
        id: user.uid,
        name: name,
        cpf: cpf,
        phone: phone,
      );
    }
  }

  Future<void> updateProfileImageBytes(Uint8List bytes) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }

    if (_userRepository.isAvailable) {
      await _userRepository.updateProfileImage(
        id: user.uid,
        profileImageBase64: base64Encode(bytes),
      );
    }
  }

  Future<void> requestEmailChange(String newEmail) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    await user.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> sendPasswordResetForCurrentUser() async {
    final email = currentUser?.email;
    if (email == null || email.isEmpty) {
      throw StateError('Usuário sem e-mail cadastrado.');
    }
    await sendPasswordResetEmail(email);
  }

  Future<void> deleteCurrentAccount() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    await AuthSecurityService.clearPin(user.uid);
    await user.delete();
    AuthSessionService.lock();
  }

  Future<AppUser> _saveAuthenticatedUser(
    UserCredential credential,
    String email, {
    String? name,
    String? cpf,
    String? phone,
    DateTime? termsAcceptedAt,
  }) async {
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Não foi possível obter o usuário autenticado.');
    }

    final now = DateTime.now();
    final appUser = AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      name: _resolveName(firebaseUser, email, name),
      cpf: cpf,
      phone: phone,
      termsAcceptedAt: termsAcceptedAt,
      createdAt: now,
      updatedAt: now,
    );

    if (_userRepository.isAvailable) {
      try {
        await _userRepository.createOrUpdate(appUser);
      } catch (_) {
        // A autenticação já foi concluída. O perfil pode ser sincronizado depois.
      }
    }

    return appUser;
  }

  Future<void> signOut() async {
    AuthSessionService.lock();
    await _firebaseAuth?.signOut();
  }

  Future<void> _registerAccessLog({required String action}) async {
    final user = currentUser;
    if (user == null || !_userRepository.isAvailable) return;

    try {
      await _userRepository.registerAccessLog(
        userId: user.uid,
        action: action,
        platform: defaultTargetPlatform.name,
      );
    } catch (_) {
      // Logs não devem bloquear a autenticação.
    }
  }

  String _nameFromEmail(String email) {
    final name = email.split('@').first.trim();
    if (name.isEmpty) return 'Cliente';
    return name;
  }

  String _resolveName(User firebaseUser, String email, String? name) {
    final providedName = name?.trim();
    if (providedName != null && providedName.isNotEmpty) return providedName;

    final displayName = firebaseUser.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    return _nameFromEmail(email);
  }
}
