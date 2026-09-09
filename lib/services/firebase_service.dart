import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  FirebaseService._internal();

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  bool _initialized = false;

  FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _auth!;
  }

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call initialize() first.');
    }
    return _firestore!;
  }

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      // Configure Firestore settings for offline persistence
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 50 * 1024 * 1024, // 50 MB
      );

      _initialized = true;
      debugPrint('✅ Firebase initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase: $e');
      // Don't rethrow - allow app to continue in offline mode
      _initialized = false;
      throw Exception('Firebase initialization failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _auth?.authStateChanges() ?? Stream.value(null);
  }

  // Get current user
  User? get currentUser {
    return _auth?.currentUser;
  }
}
