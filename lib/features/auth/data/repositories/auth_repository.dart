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

  bool get isAvailable => _firebaseAuth != null;

  User? get currentUser => _firebaseAuth?.currentUser;

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda nao foi inicializado.');
    }

    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _saveAuthenticatedUser(credential, email);
  }

  Future<AppUser> createUser({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw StateError('Firebase Auth ainda nao foi inicializado.');
    }

    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    return _saveAuthenticatedUser(credential, email);
  }

  Future<AppUser> _saveAuthenticatedUser(
    UserCredential credential,
    String email,
  ) async {
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

    if (_userRepository.isAvailable) {
      try {
        await _userRepository.createOrUpdate(appUser);
      } catch (_) {
        // A autenticacao ja foi concluida. O perfil pode ser sincronizado depois.
      }
    }

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
