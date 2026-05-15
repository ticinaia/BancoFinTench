import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../constants/app_constants.dart';
import 'firebase_service.dart';

/// Centraliza a inicializacao dos plugins usados no app.
class AppPlugins {
  AppPlugins._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.awesomeApiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ),
  );

  static const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  static final LocalAuthentication localAuth = LocalAuthentication();
  static final ImagePicker imagePicker = ImagePicker();

  static FirebaseAuth? get firebaseAuth => FirebaseService.auth;
  static FirebaseFirestore? get firestore => FirebaseService.firestore;

  static Future<void> initialize() async {
    await FirebaseService.initialize();
  }
}
