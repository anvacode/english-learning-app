import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/admin_auth_service.dart';
import '../services/firebase_service.dart';
import '../services/sync_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, guest }

class AuthProvider extends ChangeNotifier {
  static const String _guestIdKey = 'guest_session_id';

  final FirebaseService _firebaseService = FirebaseService();
  final SyncService _syncService = SyncService();

  StreamSubscription<User?>? _authSubscription;
  AuthStatus _status = AuthStatus.uninitialized;
  User? _user;
  String? _guestId;
  bool _isDisposed = false;

  /// Completer que se completa cuando el auth state está listo.
  final Completer<void> _authReadyCompleter = Completer<void>();

  /// Future que se completa cuando el auth state está listo.
  /// Usar en splash screen en lugar de un delay fijo.
  Future<void> get authReady => _authReadyCompleter.future;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get guestId => _guestId;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isAdmin =>
      _user != null && AdminAuthService.isAdminEmail(_user!.email ?? '');

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    // Check if Firebase is initialized
    if (!_firebaseService.isInitialized) {
      debugPrint(
        '⚠️ Firebase not initialized. Auth will work in offline/guest mode only.',
      );
      _status = AuthStatus.unauthenticated;
      _checkGuestSession();
      notifyListeners();
      return;
    }

    // Listen to auth state changes
    _authSubscription = _firebaseService.authStateChanges.listen((
      User? user,
    ) async {
      if (_isDisposed) return;

      _user = user;
      if (user != null) {
        _status = AuthStatus.authenticated;

        // Si había una sesión de invitado, migrar TODOS los datos
        if (_guestId != null) {
          debugPrint('🔄 Migrando datos completos de invitado...');
          final migrationSuccess = await _syncService.migrateGuestData(
            _guestId!,
          );
          if (_isDisposed) return;

          // Limpiar guestId de SharedPreferences solo si migración exitosa
          if (migrationSuccess) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove(_guestIdKey);
            _guestId = null;

            // Descargar datos de la nube para tener el estado más reciente
            // (por si el usuario ya tenía datos en otro dispositivo)
            await _syncService.downloadUserData();
            if (_isDisposed) return;
          }
        } else {
          // Usuario existente: primero subir cambios locales, luego descargar
          // Esto evita que cambios locales no sincronizados se pierdan
          await _syncService.syncUserData();
          if (_isDisposed) return;
          await _syncService.downloadUserData();
          if (_isDisposed) return;
        }

        // Iniciar sincronización automática
        _syncService.setupAutoSync();

        // NO llamar syncUserData() aquí - ya se hizo arriba
      } else {
        // Check if there's a guest session
        await _checkGuestSession();
      }

      // Completar el completer en la primera emisión del auth state
      if (!_authReadyCompleter.isCompleted) {
        _authReadyCompleter.complete();
      }

      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (!_firebaseService.isInitialized) {
        throw 'Servicios de autenticación no disponibles. Intenta más tarde.';
      }
      await _firebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error signing in: ${e.code}');
      throw _getSpanishErrorMessage(e.code);
    } catch (e) {
      debugPrint('Error signing in: $e');
      if (e.toString().contains('no disponibles')) {
        rethrow;
      }
      throw 'Error al iniciar sesión. Verifica tu conexión.';
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (!_firebaseService.isInitialized) {
        throw 'Servicios de autenticación no disponibles. Intenta más tarde.';
      }
      await _firebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('Error creating user: ${e.code}');
      throw _getSpanishErrorMessage(e.code);
    } catch (e) {
      debugPrint('Error creating user: $e');
      if (e.toString().contains('no disponibles')) {
        rethrow;
      }
      throw 'Error al crear cuenta. Verifica tu conexión.';
    }
  }

  /// Cierra sesión y limpia todos los datos locales del usuario.
  ///
  /// 1. Sincroniza los datos actuales a Firestore (para no perder nada)
  /// 2. Limpia SharedPreferences (datos del usuario)
  /// 3. Cierra sesión en Firebase Auth
  Future<void> signOut() async {
    try {
      _syncService.stopAutoSync();

      // 1. Sincronizar datos actuales antes de cerrar sesión
      await _syncService.syncUserData();

      // 2. Limpiar datos locales del usuario
      await SyncService.clearAllUserData();

      // 3. Cerrar sesión en Firebase
      await _firebaseService.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (!_firebaseService.isInitialized) {
        throw 'Servicios de autenticación no disponibles. Intenta más tarde.';
      }
      await _firebaseService.auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      rethrow;
    }
  }

  /// Inicia sesión con Google (soporta web y móvil)
  Future<void> signInWithGoogle() async {
    try {
      if (!_firebaseService.isInitialized) {
        throw 'Servicios de autenticación no disponibles. Intenta más tarde.';
      }

      if (kIsWeb) {
        // Versión web: usar Firebase Auth directamente con popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();

        // Configurar los scopes necesarios
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Usar signInWithPopup para web
        debugPrint('🔵 Iniciando Google Sign-In con popup (web)...');
        await _firebaseService.auth.signInWithPopup(googleProvider);

        debugPrint('✅ Inicio de sesión con Google exitoso (web)');
      } else {
        // Versión móvil: usar google_sign_in package
        debugPrint('🔵 Iniciando Google Sign-In (móvil)...');

        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        // Iniciar el flujo de autenticación de Google
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          // El usuario canceló el inicio de sesión
          debugPrint('❌ Google Sign-In cancelado por el usuario');
          throw 'Inicio de sesión cancelado';
        }

        // Obtener los detalles de autenticación del usuario
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Crear una credencial de Firebase con los tokens de Google
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Autenticarse con Firebase usando la credencial de Google
        await _firebaseService.auth.signInWithCredential(credential);

        debugPrint('✅ Inicio de sesión con Google exitoso (móvil)');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Error con Google Sign-In (Firebase): ${e.code}');

      // Errores específicos de popup (solo web)
      if (kIsWeb) {
        if (e.code == 'popup-closed-by-user') {
          throw 'Inicio de sesión cancelado';
        }
        if (e.code == 'popup-blocked') {
          throw 'El popup fue bloqueado por el navegador. Habilita popups para este sitio.';
        }
      }

      throw _getSpanishErrorMessage(e.code);
    } catch (e) {
      debugPrint('Error con Google Sign-In: $e');
      if (e.toString().contains('no disponibles')) {
        rethrow;
      }
      if (e.toString().contains('cancelado') ||
          e.toString().contains('closed') ||
          e.toString().contains('sign_in_canceled')) {
        throw 'Inicio de sesión cancelado';
      }
      throw 'Error al iniciar sesión con Google. Inténtalo de nuevo.';
    }
  }

  // Guest session methods
  Future<void> createGuestSession() async {
    final guestId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestIdKey, guestId);

    _guestId = guestId;
    _status = AuthStatus.guest;
    _user = null;
    notifyListeners();
  }

  Future<void> _checkGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGuestId = prefs.getString(_guestIdKey);

    if (savedGuestId != null) {
      _guestId = savedGuestId;
      _status = AuthStatus.guest;
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  void migrateGuestToUser(User newUser) {
    // TODO: Implement migration logic
    _user = newUser;
    _guestId = null;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Convierte códigos de error de Firebase a mensajes en español
  String _getSpanishErrorMessage(String errorCode) {
    switch (errorCode) {
      // Errores de registro
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Intenta iniciar sesión.';
      case 'invalid-email':
        return 'El correo electrónico no es válido.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Contacta soporte.';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';

      // Errores de inicio de sesión
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'user-not-found':
        return 'No existe una cuenta con este correo. Regístrate primero.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo de nuevo.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';

      // Errores de red
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos.';

      // Otros errores
      case 'invalid-verification-code':
        return 'Código de verificación inválido.';
      case 'invalid-verification-id':
        return 'ID de verificación inválido.';

      default:
        return 'Error: $errorCode. Contacta soporte si persiste.';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _syncService.stopAutoSync();
    _authSubscription?.cancel();
    super.dispose();
  }
}
