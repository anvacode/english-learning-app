import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
import '../logic/user_profile_service.dart';
import '../logic/star_service.dart';
import '../models/user_profile.dart';
import 'usage_tracking_service.dart';

/// Servicio de sincronización entre almacenamiento local y Firebase
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _lastSyncedStarsKey = 'last_synced_stars';
  static const String _lessonCompletionsKey = 'lesson_completions';
  static const String _activityResultsKey = 'activity_results';
  static const String _practiceProgressPrefix = 'practice_progress_';
  static const String _totalActiveSecondsKey = 'total_active_seconds';
  static const String _usageSessionsKey = 'usage_sessions';

  final FirebaseService _firebaseService = FirebaseService();
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  Timer? _scheduledSyncTimer;

  /// Requests one near-future sync. Multiple local changes are coalesced so a
  /// sequence of answers does not create one network request per answer.
  void scheduleSync({Duration delay = const Duration(seconds: 2)}) {
    if (_firebaseService.currentUser == null) return;
    _scheduledSyncTimer?.cancel();
    _scheduledSyncTimer = Timer(delay, syncUserData);
  }

  /// Sincronizar datos del usuario actual con Firebase
  Future<bool> syncUserData() async {
    if (_isSyncing) {
      debugPrint('⏳ Ya hay una sincronización en progreso');
      return false;
    }

    _isSyncing = true;

    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado para sincronizar');
        return false;
      }

      debugPrint('🔄 Iniciando sincronización para ${user.email}');

      // Cargar datos locales
      final profile = await UserProfileService.loadProfile();
      final stars = await StarService.getTotalStars();
      final prefs = await SharedPreferences.getInstance();
      final learningProgress = _readLearningProgress(prefs);
      final totalActiveSeconds = prefs.getInt(_totalActiveSecondsKey) ??
          await UsageTrackingService.instance.getTotalActiveSeconds();

      // Crear referencia al documento del usuario
      final userDoc = _firebaseService.firestore
          .collection('users')
          .doc(user.uid);

      // Subir datos a Firebase
      await userDoc.set({
        'profile': {
          'nickname': profile.nickname,
          'avatarId': profile.avatarId,
          'email': user.email,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'progress': {
          'stars': stars,
          'totalActiveSeconds': totalActiveSeconds,
          'completedLessons': learningProgress['lessonCompletions'].length,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'learningProgress': {
          ...learningProgress,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      await _syncUsageSessions(userDoc, prefs);

      // Registrar timestamp de última sincronización para evitar duplicaciones
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_lastSyncedStarsKey, stars);

      debugPrint('✅ Sincronización completada exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error al sincronizar: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Descargar datos del usuario desde Firebase
  Future<bool> downloadUserData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        return false;
      }

      debugPrint('📥 Descargando datos de ${user.email}');

      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('ℹ️ No hay datos remotos, usando datos locales');
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Actualizar perfil local si hay datos remotos
      if (data.containsKey('profile')) {
        final profileData = data['profile'] as Map<String, dynamic>;
        final currentProfile = await UserProfileService.loadProfile();

        final updatedProfile = UserProfile(
          nickname: profileData['nickname'] ?? currentProfile.nickname,
          avatarId: profileData['avatarId'] ?? currentProfile.avatarId,
          createdAt: currentProfile.createdAt,
        );

        await UserProfileService.saveProfile(updatedProfile);
      }

      // Actualizar estrellas si hay datos remotos
      if (data.containsKey('progress')) {
        final progressData = data['progress'] as Map<String, dynamic>;
        if (progressData.containsKey('stars')) {
          final remoteStars = progressData['stars'] as int;
          final localStars = await StarService.getTotalStars();

          // Usar el valor mayor (fusión de datos)
          if (remoteStars > localStars) {
            final difference = remoteStars - localStars;
            await StarService.addStars(
              difference,
              'cloud_sync',
              description: 'Sincronización desde la nube',
              applyMultiplier: false,
            );
            debugPrint(
              '⭐ Estrellas actualizadas de $localStars a $remoteStars',
            );
          }
        }
        final remoteActiveSeconds = progressData['totalActiveSeconds'];
        if (remoteActiveSeconds is int) {
          final prefs = await SharedPreferences.getInstance();
          final localActiveSeconds = prefs.getInt(_totalActiveSecondsKey) ?? 0;
          if (remoteActiveSeconds > localActiveSeconds) {
            await prefs.setInt(_totalActiveSecondsKey, remoteActiveSeconds);
          }
        }
      }

      if (data['learningProgress'] is Map) {
        final prefs = await SharedPreferences.getInstance();
        await _mergeRemoteLearningProgress(
          prefs,
          Map<String, dynamic>.from(data['learningProgress'] as Map),
        );
      }

      debugPrint('✅ Datos descargados exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error al descargar datos: $e');
      return false;
    }
  }

  /// Migrar datos de invitado a usuario registrado
  Future<bool> migrateGuestData(String guestId) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        return false;
      }

      debugPrint('🔄 Migrando datos de invitado a usuario registrado');

      // Los datos ya están en el almacenamiento local
      // Solo necesitamos subirlos a Firebase
      final success = await syncUserData();

      if (success) {
        debugPrint('✅ Migración completada exitosamente');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error al migrar datos: $e');
      return false;
    }
  }

  /// Configurar sincronización automática
  void setupAutoSync() {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    stopAutoSync();

    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncUserData();
    });
  }

  /// Detener la sincronización automática
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _scheduledSyncTimer?.cancel();
    _scheduledSyncTimer = null;
  }

  Map<String, dynamic> _readLearningProgress(SharedPreferences prefs) {
    final practiceActivities = <Map<String, dynamic>>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_practiceProgressPrefix)) continue;
      final value = prefs.getString(key);
      if (value == null) continue;
      final decoded = _decodeMap(value);
      if (decoded != null) practiceActivities.add(decoded);
    }

    return {
      'lessonCompletions': _decodeList(prefs.getString(_lessonCompletionsKey)),
      'activityResults': _decodeList(prefs.getString(_activityResultsKey)),
      'practiceActivities': practiceActivities,
    };
  }

  Future<void> _syncUsageSessions(
    DocumentReference<Map<String, dynamic>> userDoc,
    SharedPreferences prefs,
  ) async {
    final sessions = _decodeList(prefs.getString(_usageSessionsKey));
    if (sessions.isEmpty) return;

    final batch = _firebaseService.firestore.batch();
    for (final session in sessions) {
      final id = session['id'];
      if (id is! String || id.isEmpty) continue;
      batch.set(
        userDoc.collection('usageSessions').doc(id),
        session,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> _mergeRemoteLearningProgress(
    SharedPreferences prefs,
    Map<String, dynamic> remote,
  ) async {
    final localCompletions = _decodeList(prefs.getString(_lessonCompletionsKey));
    final remoteCompletions = _asMapList(remote['lessonCompletions']);
    final completions = _mergeRecords(
      localCompletions,
      remoteCompletions,
      (record) => record['lessonId'] as String? ?? '',
    );
    await prefs.setString(_lessonCompletionsKey, jsonEncode(completions));

    final localResults = _decodeList(prefs.getString(_activityResultsKey));
    final remoteResults = _asMapList(remote['activityResults']);
    final results = _mergeRecords(localResults, remoteResults, (record) {
      return '${record['lessonId']}:${record['itemId']}:${record['timestamp']}';
    });
    await prefs.setString(_activityResultsKey, jsonEncode(results));

    for (final remotePractice in _asMapList(remote['practiceActivities'])) {
      final activityId = remotePractice['activityId'];
      if (activityId is! String || activityId.isEmpty) continue;
      final key = '$_practiceProgressPrefix$activityId';
      final localPractice = _decodeMap(prefs.getString(key));
      final useRemote = localPractice == null ||
          (remotePractice['lastPlayed'] as String? ?? '').compareTo(
                localPractice['lastPlayed'] as String? ?? '',
              ) >
              0;
      if (useRemote) await prefs.setString(key, jsonEncode(remotePractice));
    }
  }

  List<Map<String, dynamic>> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return _asMapList(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final value = jsonDecode(raw);
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _mergeRecords(
    List<Map<String, dynamic>> local,
    List<Map<String, dynamic>> remote,
    String Function(Map<String, dynamic>) keyFor,
  ) {
    final records = <String, Map<String, dynamic>>{};
    for (final record in [...remote, ...local]) {
      final key = keyFor(record);
      if (key.isNotEmpty) records[key] = record;
    }
    return records.values.toList();
  }

  /// Libera la instancia singleton (llamar al cerrar la app)
  static void disposeInstance() {
    _instance.stopAutoSync();
  }
}
