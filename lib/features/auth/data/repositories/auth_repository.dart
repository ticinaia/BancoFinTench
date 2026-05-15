import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/firebase_service.dart';
import '../../domain/models/app_user.dart';
import 'user_repository.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    UserRepository? userRepository,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseService.auth,
        _userRepository = userRepository ?? UserRepository();

  final FirebaseAuth? _firebaseAuth;
  final UserRepository _userRepository;

  bool get isAvailable => _firebaseAuth != null && _userRepository.isAvailable;

  Future<AppUser> signInOrCreateUser({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda nao foi inicializado.');
    }

    UserCredential credential;
    try {
      credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
      credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw StateError('Nao foi possivel obter o usuario autenticado.');
    }

    final now = DateTime.now();
    final appUser = AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? email,
      name: _nameFromEmail(email),
      createdAt: now,
      updatedAt: now,
    );

    await _userRepository.createOrUpdate(appUser);
    return appUser;
  }

  Future<void> signOut() async {
    await _firebaseAuth?.signOut();
  }

  String _nameFromEmail(String email) {
    final name = email.split('@').first.trim();
    if (name.isEmpty) return 'Cliente';
    return name;
  }
}
