import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logic/activity_result_service.dart';
import '../logic/lesson_completion_service.dart';
import '../logic/star_service.dart';
import '../logic/user_profile_service.dart';
import '../models/activity_result.dart';
import '../models/lesson_completion.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// Servicio de sincronización entre almacenamiento local y Firebase.
///
/// Sincroniza TODOS los datos del usuario: perfil, estrellas, racha,
/// lecciones completadas, resultados de actividad, badges, práctica,
/// compras de tienda, y datos del diagnóstico.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _lastSyncedStarsKey = 'last_synced_stars';

  final FirebaseService _firebaseService = FirebaseService();
  bool _isSyncing = false;
  Timer? _autoSyncTimer;
  Timer? _debounceTimer;

  /// Delay para el debounce de sincronización inmediata.
  static const Duration _debounceDelay = Duration(seconds: 2);

  // ═══════════════════════════════════════════════════════════════
  // SINCRONIZACIÓN PRINCIPAL: LOCAL → FIRESTORE
  // ═══════════════════════════════════════════════════════════════

  /// Sincronizar TODOS los datos del usuario actual con Firebase.
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

      debugPrint('🔄 Iniciando sincronización completa para ${user.email}');

      // Recopilar todos los datos locales
      final profile = await UserProfileService.loadProfile();
      final stars = await StarService.getTotalStars();
      final loginStreak = await StarService.getLoginStreak();
      final lastLoginDate = await _getLastLoginDate();
      final lessonCompletions = await LessonCompletionService.getCompletions();
      final activityResults = await ActivityResultService.getActivityResults();
      final badges = await _getAllBadgeAwards();
      final practiceProgress = await _getAllPracticeProgress();
      final purchasedItems = await _getPurchasedItems();
      final activeEffects = await _getActiveEffects();
      final activePowerUps = await _getActivePowerUps();
      final diagnosticData = await _getDiagnosticData();

      // Crear referencia al documento del usuario
      final userDoc = _firebaseService.firestore
          .collection('users')
          .doc(user.uid);

      // Subir TODOS los datos a Firebase
      await userDoc.set({
        'profile': {
          'nickname': profile.nickname,
          'avatarId': profile.avatarId,
          'email': user.email,
          'createdAt': profile.createdAt.toIso8601String(),
          'localLastUpdated':
              profile.lastUpdated?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'loginStreak': loginStreak,
          'lastLoginDate': lastLoginDate,
        },
        'progress': {
          'stars': stars,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'syncData': {
          'lessonCompletions':
              lessonCompletions.map((c) => c.toJson()).toList(),
          'activityResultsSummary':
              _buildActivityResultsSummary(activityResults),
          'badges': badges,
          'practiceProgress': practiceProgress,
          'purchasedItems': purchasedItems.toList(),
          'activeEffects': activeEffects.toList(),
          'activePowerUps': activePowerUps.toList(),
          'diagnostic': diagnosticData,
          'syncTimestamp': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      // Registrar timestamp de última sincronización
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_lastSyncedStarsKey, stars);

      debugPrint('✅ Sincronización completa exitosa');
      return true;
    } catch (e) {
      debugPrint('❌ Error al sincronizar: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // DESCARGA: FIRESTORE → LOCAL
  // ═══════════════════════════════════════════════════════════════

  /// Descargar TODOS los datos del usuario desde Firebase y restaurarlos localmente.
  Future<bool> downloadUserData() async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        return false;
      }

      debugPrint('📥 Descargando datos completos de ${user.email}');

      final userDoc = await _firebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        debugPrint('ℹ️ No hay datos remotos, usando datos locales');
        return false;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // ── Restaurar perfil con fusión por timestamps ──
      if (data.containsKey('profile')) {
        final profileData = data['profile'] as Map<String, dynamic>;
        final currentProfile = await UserProfileService.loadProfile();

        // Comparar timestamps para decidir si sobrescribir local
        final remoteLastUpdated = _parseDateTime(
          profileData['localLastUpdated'],
        );
        final localLastUpdated = currentProfile.lastUpdated;

        bool shouldUseRemote = true;
        if (localLastUpdated != null && remoteLastUpdated != null) {
          // Si el perfil local es más reciente que el último sync,
          // NO sobrescribir - el usuario hizo cambios locales después del último sync
          shouldUseRemote = remoteLastUpdated.isAfter(localLastUpdated);
          if (!shouldUseRemote) {
            debugPrint(
              'ℹ️ Perfil local más reciente (${localLastUpdated.toIso8601String()}) '
              'que remoto (${remoteLastUpdated.toIso8601String()}), manteniendo local',
            );
          }
        }

        if (shouldUseRemote) {
          final updatedProfile = UserProfile(
            nickname: profileData['nickname'] ?? currentProfile.nickname,
            avatarId: profileData['avatarId'] ?? currentProfile.avatarId,
            createdAt: currentProfile.createdAt,
            lastUpdated: remoteLastUpdated,
          );

          // Guardar SIN disparar sync para evitar ciclo
          await UserProfileService.saveProfile(
            updatedProfile,
            triggerSync: false,
          );
          debugPrint('👤 Perfil restaurado desde la nube');
        }

        // Restaurar racha de login (siempre usar el valor mayor)
        final prefs = await SharedPreferences.getInstance();
        if (profileData['loginStreak'] != null) {
          final remoteStreak =
              (profileData['loginStreak'] as num).toInt();
          final localStreak = prefs.getInt('login_streak') ?? 0;
          if (remoteStreak > localStreak) {
            await prefs.setInt('login_streak', remoteStreak);
          }
        }
        if (profileData['lastLoginDate'] != null) {
          await prefs.setString(
            'last_login_date',
            profileData['lastLoginDate'] as String,
          );
        }
      }

      // ── Restaurar estrellas (usar el valor mayor) ──
      if (data.containsKey('progress')) {
        final progressData = data['progress'] as Map<String, dynamic>;
        if (progressData.containsKey('stars')) {
          final remoteStars = progressData['stars'] as int;
          final localStars = await StarService.getTotalStars();

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
      }

      // ── Restaurar datos de sincronización ──
      if (data.containsKey('syncData')) {
        final syncData = data['syncData'] as Map<String, dynamic>;

        // Restaurar lecciones completadas (fusión: agregar las que falten)
        if (syncData.containsKey('lessonCompletions')) {
          await _restoreLessonCompletions(
            syncData['lessonCompletions'] as List<dynamic>,
          );
        }

        // Restaurar badges
        if (syncData.containsKey('badges')) {
          await _restoreBadges(syncData['badges'] as Map<String, dynamic>);
        }

        // Restaurar progreso de práctica
        if (syncData.containsKey('practiceProgress')) {
          await _restorePracticeProgress(
            syncData['practiceProgress'] as Map<String, dynamic>,
          );
        }

        // Restaurar compras de tienda
        if (syncData.containsKey('purchasedItems')) {
          await _restorePurchasedItems(
            syncData['purchasedItems'] as List<dynamic>,
          );
        }

        // Restaurar efectos activos
        if (syncData.containsKey('activeEffects')) {
          await _restoreActiveEffects(
            syncData['activeEffects'] as List<dynamic>,
          );
        }

        // Restaurar power-ups activos
        if (syncData.containsKey('activePowerUps')) {
          await _restoreActivePowerUps(
            syncData['activePowerUps'] as List<dynamic>,
          );
        }

        // Restaurar datos del diagnóstico
        if (syncData.containsKey('diagnostic')) {
          await _restoreDiagnosticData(
            syncData['diagnostic'] as Map<String, dynamic>,
          );
        }
      }

      debugPrint('✅ Datos descargados exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error al descargar datos: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MIGRACIÓN: GUEST → USUARIO AUTENTICADO
  // ═══════════════════════════════════════════════════════════════

  /// Migrar TODOS los datos de invitado a usuario registrado.
  ///
  /// Este método lee TODOS los datos locales del guest y los sube
  /// a Firestore bajo el UID del usuario autenticado.
  ///
  /// IMPORTANTE: NO limpia los datos locales porque ahora pertenecen
  /// al usuario autenticado. Después de la migración, se debe llamar
  /// a downloadUserData() para obtener el estado más reciente de la nube.
  Future<bool> migrateGuestData(String guestId) async {
    try {
      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('❌ No hay usuario autenticado');
        return false;
      }

      debugPrint(
        '🔄 Migrando datos completos de invitado ($guestId) a ${user.email}',
      );

      // 1. Recopilar TODOS los datos locales del guest
      final profile = await UserProfileService.loadProfile();
      final stars = await StarService.getTotalStars();
      final loginStreak = await StarService.getLoginStreak();
      final lastLoginDate = await _getLastLoginDate();
      final lessonCompletions = await LessonCompletionService.getCompletions();
      final activityResults = await ActivityResultService.getActivityResults();
      final badges = await _getAllBadgeAwards();
      final practiceProgress = await _getAllPracticeProgress();
      final purchasedItems = await _getPurchasedItems();
      final activeEffects = await _getActiveEffects();
      final activePowerUps = await _getActivePowerUps();
      final diagnosticData = await _getDiagnosticData();

      // 2. Subir TODO a Firestore bajo el UID del usuario autenticado
      final userDoc = _firebaseService.firestore
          .collection('users')
          .doc(user.uid);

      await userDoc.set({
        'profile': {
          'nickname': profile.nickname,
          'avatarId': profile.avatarId,
          'email': user.email,
          'createdAt': profile.createdAt.toIso8601String(),
          'localLastUpdated':
              profile.lastUpdated?.toIso8601String() ??
              DateTime.now().toIso8601String(),
          'loginStreak': loginStreak,
          'lastLoginDate': lastLoginDate,
          'migratedFromGuest': guestId,
        },
        'progress': {
          'stars': stars,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        'syncData': {
          'lessonCompletions':
              lessonCompletions.map((c) => c.toJson()).toList(),
          'activityResultsSummary':
              _buildActivityResultsSummary(activityResults),
          'badges': badges,
          'practiceProgress': practiceProgress,
          'purchasedItems': purchasedItems.toList(),
          'activeEffects': activeEffects.toList(),
          'activePowerUps': activePowerUps.toList(),
          'diagnostic': diagnosticData,
          'syncTimestamp': FieldValue.serverTimestamp(),
          'migratedFrom': 'guest_$guestId',
        },
      }, SetOptions(merge: true));

      // NO limpiar datos locales - ahora pertenecen al usuario autenticado
      // El auth_provider llamará a downloadUserData() para obtener
      // el estado más reciente de la nube

      debugPrint('✅ Migración completa de guest exitosa');
      return true;
    } catch (e) {
      debugPrint('❌ Error al migrar datos: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // SINCRONIZACIÓN AUTOMÁTICA E INMEDIATA
  // ═══════════════════════════════════════════════════════════════

  /// Configurar sincronización automática cada 5 minutos.
  void setupAutoSync() {
    final user = _firebaseService.currentUser;
    if (user == null) return;

    stopAutoSync();

    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      syncUserData();
    });
  }

  /// Detener la sincronización automática.
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Sincroniza datos con debounce para evitar múltiples llamadas rápidas.
  ///
  /// Llamar este método cada vez que cambie cualquier dato del usuario
  /// (perfil, estrellas, lecciones, práctica, etc.).
  ///
  /// El debounce de 2 segundos evita saturar Firestore con escrituras
  /// cuando el usuario hace múltiples cambios rápidos.
  void syncUserDataDebounced() {
    // Solo sincronizar si hay usuario autenticado
    if (_firebaseService.currentUser == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      debugPrint('🔄 Sincronización por cambio de datos...');
      syncUserData();
    });
  }

  /// Libera la instancia singleton (llamar al cerrar la app).
  static void disposeInstance() {
    _instance.stopAutoSync();
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS: LEER DATOS LOCALES
  // ═══════════════════════════════════════════════════════════════

  /// Obtiene la fecha del último login desde SharedPreferences.
  Future<String?> _getLastLoginDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_login_date');
  }

  /// Parsea un valor dinámico a DateTime.
  /// Soporta Timestamp de Firestore y String ISO 8601.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  /// Construye un resumen de resultados de actividad agrupados por lección.
  /// No subimos cada resultado individual para ahorrar espacio en Firestore.
  Map<String, dynamic> _buildActivityResultsSummary(
    List<ActivityResult> results,
  ) {
    final summary = <String, Map<String, dynamic>>{};

    for (final result in results) {
      final lessonId = result.lessonId;
      if (!summary.containsKey(lessonId)) {
        summary[lessonId] = {
          'totalAttempts': 0,
          'correctAttempts': 0,
          'lastAttempt': null,
        };
      }

      summary[lessonId]!['totalAttempts'] =
          (summary[lessonId]!['totalAttempts'] as int) + 1;
      if (result.isCorrect) {
        summary[lessonId]!['correctAttempts'] =
            (summary[lessonId]!['correctAttempts'] as int) + 1;
      }
      summary[lessonId]!['lastAttempt'] = result.timestamp.toIso8601String();
    }

    return summary;
  }

  /// Lee todos los badges otorgados desde SharedPreferences.
  Future<Map<String, bool>> _getAllBadgeAwards() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final badges = <String, bool>{};

    for (final key in keys) {
      if (key.startsWith('badge_awarded_')) {
        badges[key.replaceFirst('badge_awarded_', '')] =
            prefs.getBool(key) ?? false;
      }
    }

    return badges;
  }

  /// Lee todo el progreso de práctica desde SharedPreferences.
  Future<Map<String, dynamic>> _getAllPracticeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final progress = <String, dynamic>{};

    for (final key in keys) {
      if (key.startsWith('practice_progress_')) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final activityId = key.replaceFirst('practice_progress_', '');
            progress[activityId] = jsonDecode(jsonString);
          } catch (e) {
            // Skip corrupted entries
          }
        }
      }
    }

    return progress;
  }

  /// Lee los ítems comprados desde ShopService.
  Future<Set<String>> _getPurchasedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('purchased_shop_items');

    if (jsonString == null || jsonString.isEmpty) return {};

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  /// Lee los efectos activos desde SharedPreferences.
  Future<Set<String>> _getActiveEffects() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('active_effects');
    return list?.toSet() ?? {};
  }

  /// Lee los power-ups activos desde SharedPreferences.
  Future<Set<String>> _getActivePowerUps() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('active_powerups');
    return list?.toSet() ?? {};
  }

  /// Lee los datos del diagnóstico desde SharedPreferences.
  Future<Map<String, dynamic>> _getDiagnosticData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'completed': prefs.getBool('diagnostic_completed') ?? false,
      'level': prefs.getString('diagnostic_level'),
      'result': prefs.getString('diagnostic_result'),
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS: RESTAURAR DATOS LOCALES
  // ═══════════════════════════════════════════════════════════════

  /// Restaura lecciones completadas en SharedPreferences (fusión).
  Future<void> _restoreLessonCompletions(List<dynamic> remoteList) async {
    try {
      final remoteCompletions = remoteList
          .map((item) =>
              LessonCompletion.fromJson(item as Map<String, dynamic>))
          .toList();

      final localCompletions = await LessonCompletionService.getCompletions();
      final localIds = localCompletions.map((c) => c.lessonId).toSet();

      // Agregar solo las que no existan localmente
      for (final remote in remoteCompletions) {
        if (!localIds.contains(remote.lessonId)) {
          await LessonCompletionService.saveCompletion(remote.lessonId);
        }
      }

      debugPrint(
        '📚 Lecciones restauradas: ${remoteCompletions.length} remotas, '
        '${localCompletions.length} locales',
      );
    } catch (e) {
      debugPrint('❌ Error restaurando lecciones: $e');
    }
  }

  /// Restaura badges en SharedPreferences.
  Future<void> _restoreBadges(Map<String, dynamic> badges) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in badges.entries) {
      if (entry.value == true) {
        await prefs.setBool('badge_awarded_${entry.key}', true);
      }
    }
  }

  /// Restaura progreso de práctica en SharedPreferences.
  Future<void> _restorePracticeProgress(
    Map<String, dynamic> progressData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in progressData.entries) {
      try {
        // Verificar si el dato remoto es más reciente
        final remoteJson = entry.value as Map<String, dynamic>;
        final remoteLastPlayed = remoteJson['lastPlayed'] != null
            ? DateTime.tryParse(remoteJson['lastPlayed'] as String)
            : null;

        final key = 'practice_progress_${entry.key}';
        final localJsonString = prefs.getString(key);

        bool shouldRestore = true;
        if (localJsonString != null && remoteLastPlayed != null) {
          final localJson = jsonDecode(localJsonString) as Map<String, dynamic>;
          final localLastPlayed = localJson['lastPlayed'] != null
              ? DateTime.tryParse(localJson['lastPlayed'] as String)
              : null;

          // Solo restaurar si el remoto es más reciente
          if (localLastPlayed != null &&
              localLastPlayed.isAfter(remoteLastPlayed)) {
            shouldRestore = false;
          }
        }

        if (shouldRestore) {
          await prefs.setString(key, jsonEncode(remoteJson));
        }
      } catch (e) {
        // Skip corrupted entries
      }
    }
  }

  /// Restaura ítems comprados en SharedPreferences (fusión).
  Future<void> _restorePurchasedItems(List<dynamic> remoteList) async {
    try {
      final remoteIds = remoteList.cast<String>().toSet();
      final localIds = await _getPurchasedItems();

      // Fusión: unión de ambos sets
      final merged = {...localIds, ...remoteIds};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'purchased_shop_items',
        jsonEncode(merged.toList()),
      );
    } catch (e) {
      debugPrint('❌ Error restaurando compras: $e');
    }
  }

  /// Restaura efectos activos en SharedPreferences (fusión).
  Future<void> _restoreActiveEffects(List<dynamic> remoteList) async {
    try {
      final remoteEffects = remoteList.cast<String>().toSet();
      final localEffects = await _getActiveEffects();
      final merged = {...localEffects, ...remoteEffects};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('active_effects', merged.toList());
    } catch (e) {
      debugPrint('❌ Error restaurando efectos: $e');
    }
  }

  /// Restaura power-ups activos en SharedPreferences (fusión).
  Future<void> _restoreActivePowerUps(List<dynamic> remoteList) async {
    try {
      final remotePowerUps = remoteList.cast<String>().toSet();
      final localPowerUps = await _getActivePowerUps();
      final merged = {...localPowerUps, ...remotePowerUps};

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('active_powerups', merged.toList());
    } catch (e) {
      debugPrint('❌ Error restaurando power-ups: $e');
    }
  }

  /// Restaura datos del diagnóstico en SharedPreferences.
  Future<void> _restoreDiagnosticData(
    Map<String, dynamic> diagnosticData,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (diagnosticData['completed'] == true) {
      await prefs.setBool('diagnostic_completed', true);
    }
    if (diagnosticData['level'] != null) {
      await prefs.setString(
        'diagnostic_level',
        diagnosticData['level'] as String,
      );
    }
    if (diagnosticData['result'] != null) {
      await prefs.setString(
        'diagnostic_result',
        diagnosticData['result'] as String,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LIMPIEZA DE DATOS
  // ═══════════════════════════════════════════════════════════════

  /// Limpia todos los datos locales del usuario (para usar al cerrar sesión).
  /// NO limpia: onboarding_completed, is_first_time, student_id, theme_mode.
  static Future<void> clearAllUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    // Keys que NO deben eliminarse (configuración de la app, no del usuario)
    const keysToKeep = {
      'onboarding_completed',
      'is_first_time',
      'student_id',
      'theme_mode',
      'guest_session_id',
    };

    // Prefijos de keys que deben eliminarse
    const prefixesToRemove = [
      'badge_awarded_',
      'practice_progress_',
      'powerup_expiration_',
    ];

    for (final key in keys) {
      // Mantener keys de configuración de la app
      if (keysToKeep.contains(key)) continue;

      // Eliminar keys con prefijos específicos
      bool shouldRemove = false;
      for (final prefix in prefixesToRemove) {
        if (key.startsWith(prefix)) {
          shouldRemove = true;
          break;
        }
      }

      // Eliminar keys conocidas de datos de usuario
      if (!shouldRemove) {
        shouldRemove = _isUserDataKey(key);
      }

      if (shouldRemove) {
        await prefs.remove(key);
      }
    }

    debugPrint('🧹 Datos locales del usuario limpiados');
  }

  /// Determina si una key es de datos de usuario (debe limpiarse al cerrar sesión).
  static bool _isUserDataKey(String key) {
    const userDataKeys = {
      'user_profile',
      'star_transactions',
      'total_stars',
      'last_daily_reset',
      'daily_stars_earned',
      'last_login_date',
      'login_streak',
      'lesson_completions',
      'activity_results',
      'purchased_shop_items',
      'active_effects',
      'active_powerups',
      'diagnostic_completed',
      'diagnostic_level',
      'diagnostic_result',
      'last_sync_timestamp',
      'last_synced_stars',
      'app_open_count',
      'auth_prompt_shown_after_onboarding',
      'last_prompt_count',
    };
    return userDataKeys.contains(key);
  }
}
