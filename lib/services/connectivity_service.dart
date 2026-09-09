import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio de conectividad que expone el estado de conexión de la app.
///
/// Usa dos mecanismos para detectar conectividad:
/// 1. `connectivity_plus` para detectar cambios de interfaz de red
/// 2. HTTP ping periódico a un endpoint ligero para verificar internet real
///
/// Esto es crítico en web donde `navigator.onLine` no detecta pérdida real de internet.
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance =
      ConnectivityService._internal();
  static bool _initialized = false;

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _pingTimer;
  bool _isOnline = true;
  bool _wasJustRestored = false;
  int _consecutiveFailures = 0;

  static const int _failuresBeforeOffline = 3;

  bool get isOnline => _isOnline;
  bool get wasJustRestored => _wasJustRestored;

  /// Endpoints usados para verificar conectividad real.
  /// httpbin tiene CORS habilitado, gstatic es el fallback de Google.
  static const String _pingUrl = 'https://httpbin.org/status/200';
  static const String _pingUrlFallback = 'https://www.gstatic.com/generate_204';
  static const String _pingUrlFallback2 = 'https://www.google.com/favicon.ico';

  /// Inicializa el servicio y comienza a monitorizar la conectividad.
  Future<void> initialize() async {
    if (_initialized) return;

    // Verificar estado inicial con HTTP ping real
    _isOnline = await _checkRealConnectivity();
    debugPrint(
      '🌐 ConnectivityService: estado inicial = ${_isOnline ? "ONLINE" : "OFFLINE"}',
    );

    // Suscribirse a cambios de interfaz de red
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      final hadInterface = result != ConnectivityResult.none;
      debugPrint(
        '🌐 ConnectivityService: interfaz de red = ${hadInterface ? "sí" : "no"} ($result)',
      );
      if (!hadInterface && _isOnline) {
        _setOffline();
      } else if (hadInterface && !_isOnline) {
        _consecutiveFailures = 0;
        checkConnection();
      }
    });

    // Iniciar pings periódicos
    _startPingTimer();

    _initialized = true;
  }

  /// Verifica la conectividad actual con un ping HTTP real.
  Future<bool> checkConnection() async {
    final result = await _checkRealConnectivity();
    if (result != _isOnline) {
      if (result) {
        _setOnline();
      } else {
        _setOffline();
      }
    }
    return _isOnline;
  }

  /// Hace un ping HTTP real para verificar si hay internet.
  /// Intenta el endpoint principal y si falla por CORS, usa el fallback.
  Future<bool> _checkRealConnectivity() async {
    // Intento 1: httpbin (CORS habilitado)
    try {
      final response = await http
          .get(Uri.parse(_pingUrl))
          .timeout(const Duration(seconds: 5));
      final ok = response.statusCode < 400;
      debugPrint(
        '🌐 ConnectivityService: ping HTTP = ${ok ? "OK" : "FALLÓ"} (status: ${response.statusCode})',
      );
      return ok;
    } catch (e) {
      debugPrint('🌐 ConnectivityService: ping principal FALLÓ ($e), intentando fallback...');
    }

    // Intento 2: gstatic (fallback de Google con CORS)
    try {
      final response = await http
          .get(Uri.parse(_pingUrlFallback))
          .timeout(const Duration(seconds: 5));
      final ok = response.statusCode < 400;
      debugPrint(
        '🌐 ConnectivityService: ping fallback = ${ok ? "OK" : "FALLÓ"} (status: ${response.statusCode})',
      );
      return ok;
    } catch (e) {
      debugPrint('🌐 ConnectivityService: ping fallback FALLÓ ($e)');
    }

    try {
      final response = await http
          .get(Uri.parse(_pingUrlFallback2))
          .timeout(const Duration(seconds: 5));
      final ok = response.statusCode < 400;
      debugPrint(
        '🌐 ConnectivityService: ping fallback2 = ${ok ? "OK" : "FALLÓ"} (status: ${response.statusCode})',
      );
      return ok;
    } catch (e) {
      debugPrint('🌐 ConnectivityService: ping fallback2 FALLÓ ($e)');
      return false;
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final actuallyOnline = await _checkRealConnectivity();
      if (actuallyOnline) {
        _consecutiveFailures = 0;
        if (!_isOnline) _setOnline();
      } else {
        _consecutiveFailures++;
        if (_consecutiveFailures >= _failuresBeforeOffline && _isOnline) {
          _setOffline();
        }
      }
    });
  }

  void _setOnline() {
    debugPrint('🌐 ConnectivityService: → ONLINE');
    _isOnline = true;
    _wasJustRestored = true;
    _consecutiveFailures = 0;
    notifyListeners();

    // Resetear el flag tras 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      _wasJustRestored = false;
      notifyListeners();
    });
  }

  void _setOffline() {
    debugPrint('🌐 ConnectivityService: → OFFLINE');
    _isOnline = false;
    _wasJustRestored = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _pingTimer?.cancel();
    super.dispose();
  }

  /// Libera la instancia singleton (llamar al cerrar la app).
  static void disposeInstance() {
    _instance.dispose();
  }
}
