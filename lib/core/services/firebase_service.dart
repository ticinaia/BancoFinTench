import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  static bool _isReady = false;
  static Object? _lastError;

  static bool get isReady => _isReady;
  static Object? get lastError => _lastError;

  static FirebaseAuth? get auth {
    if (!_isReady) return null;
    return FirebaseAuth.instance;
  }

  static FirebaseFirestore? get firestore {
    if (!_isReady) return null;
    return FirebaseFirestore.instance;
  }

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isReady = true;
    } catch (error) {
      _lastError = error;
      _isReady = false;
    }
  }
}
