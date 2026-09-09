import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import '../services/firebase_service.dart';

/// Servicio dedicado para escribir métricas de progreso a Firestore.
///
/// Todas las escrituras van dentro del documento users/{uid},
/// sin crear colecciones nuevas. Usa FieldValue para evitar race conditions.
class FirestoreProgressService {
  static final FirestoreProgressService _instance =
      FirestoreProgressService._internal();
  factory FirestoreProgressService() => _instance;
  FirestoreProgressService._internal();

  final FirebaseService _firebaseService = FirebaseService();

  /// Registra una sesión de usuario (contador + timestamp + racha).
  /// Se llama UNA vez al entrar al HomeScreen.
  Future<void> registerSession() async {
    try {
      if (!_firebaseService.isInitialized) {
        debugPrint('⚠️ Firebase no inicializado, sesión no registrada');
        return;
      }

      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario autenticado para registrar sesión');
        return;
      }

      // Leer racha de login local para sincronizarla
      final prefs = await SharedPreferences.getInstance();
      final loginStreak = prefs.getInt('login_streak') ?? 0;
      final lastLoginDate = prefs.getString('last_login_date');

      await _firebaseService.firestore.collection('users').doc(user.uid).set({
        'profile.totalSessions': FieldValue.increment(1),
        'profile.lastActive': FieldValue.serverTimestamp(),
        'profile.sessionsByDay.${formatDayKey(DateTime.now())}':
            FieldValue.increment(1),
        'profile.loginStreak': loginStreak,
        'profile.lastLoginDate': lastLoginDate,
      }, SetOptions(merge: true));

      debugPrint('✅ Sesión registrada para ${user.email} (racha: $loginStreak)');
    } catch (e) {
      debugPrint('❌ Error al registrar sesión: $e');
    }
  }

  /// Guarda el progreso de una lección completada.
  ///
  /// - [lessonId]: identificador único de la lección
  /// - [starsEarned]: estrellas ganadas en este intento (se acumulan)
  /// - [accuracy]: precisión del intento actual (0-100)
  Future<void> saveLessonProgress({
    required String lessonId,
    required int starsEarned,
    required double accuracy,
  }) async {
    try {
      if (!_firebaseService.isInitialized) {
        debugPrint('⚠️ Firebase no inicializado, progreso no guardado');
        return;
      }

      final user = _firebaseService.currentUser;
      if (user == null) {
        debugPrint('⚠️ No hay usuario autenticado para guardar progreso');
        return;
      }

      final docRef = _firebaseService.firestore
          .collection('users')
          .doc(user.uid);

      final doc = await docRef.get();
      final data = doc.data();

      double currentBestAccuracy = 0.0;
      if (data != null) {
        final progressMap = data['progress'] as Map<String, dynamic>?;
        if (progressMap != null) {
          final lessonData = progressMap[lessonId] as Map<String, dynamic>?;
          if (lessonData != null) {
            currentBestAccuracy =
                (lessonData['bestAccuracy'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      final newAccuracy = accuracy.clamp(0.0, 100.0);
      final shouldUpdateAccuracy = newAccuracy > currentBestAccuracy;

      final updateData = <String, dynamic>{
        'progress.$lessonId.completed': true,
        'progress.$lessonId.stars': FieldValue.increment(starsEarned),
        'progress.$lessonId.attempts': FieldValue.increment(1),
        'progress.$lessonId.lastPlayed': FieldValue.serverTimestamp(),
      };

      if (shouldUpdateAccuracy) {
        updateData['progress.$lessonId.bestAccuracy'] = newAccuracy;
      }

      await docRef.set(updateData, SetOptions(merge: true));

      debugPrint(
        '✅ Progreso guardado: $lessonId | '
        'stars: +$starsEarned | '
        'accuracy: ${newAccuracy.toStringAsFixed(1)}% '
        '${shouldUpdateAccuracy ? "(nuevo récord)" : "(no superó $currentBestAccuracy%)"}',
      );
    } catch (e) {
      debugPrint('❌ Error al guardar progreso de lección: $e');
    }
  }

  /// Obtiene todas las métricas del usuario actual desde Firestore.
  /// Retorna null si no hay usuario o error.
  Future<UserMetrics?> getUserMetrics() async {
    try {
      if (!_firebaseService.isInitialized) {
        return null;
      }

      final user = _firebaseService.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      final profileData = data['profile'] as Map<String, dynamic>?;
      final progressData = data['progress'] as Map<String, dynamic>?;

      final totalSessions =
          (profileData?['totalSessions'] as num?)?.toInt() ?? 0;

      DateTime? lastActive;
      if (profileData?['lastActive'] != null) {
        final ts = profileData!['lastActive'];
        if (ts is Timestamp) {
          lastActive = ts.toDate();
        }
      }

      final lessonProgressMap = <String, LessonProgress>{};
      if (progressData != null) {
        progressData.forEach((key, value) {
          if (value is Map<String, dynamic> &&
              value.containsKey('completed')) {
            lessonProgressMap[key] = LessonProgress.fromJson(value);
          }
        });
      }

      return UserMetrics(
        totalSessions: totalSessions,
        lastActive: lastActive,
        progress: lessonProgressMap,
      );
    } catch (e) {
      debugPrint('❌ Error al obtener métricas: $e');
      return null;
    }
  }

  /// Obtiene las métricas de un usuario específico por su UID.
  /// Usado por el admin para revisar usuarios individuales.
  Future<UserMetrics?> getUserMetricsByUid(String uid) async {
    try {
      if (!_firebaseService.isInitialized) {
        return null;
      }

      final doc = await _firebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      final profileData = data['profile'] as Map<String, dynamic>?;
      final progressData = data['progress'] as Map<String, dynamic>?;

      final email = profileData?['email'] as String?;
      final nickname = profileData?['nickname'] as String?;
      final totalSessions =
          (profileData?['totalSessions'] as num?)?.toInt() ?? 0;
      final loginStreak =
          (profileData?['loginStreak'] as num?)?.toInt() ?? 0;

      DateTime? lastActive;
      if (profileData?['lastActive'] != null) {
        final ts = profileData!['lastActive'];
        if (ts is Timestamp) {
          lastActive = ts.toDate();
        }
      }

      DateTime? lastLoginDate;
      if (profileData?['lastLoginDate'] != null) {
        final str = profileData!['lastLoginDate'] as String?;
        if (str != null) {
          lastLoginDate = DateTime.tryParse(str);
        }
      }

      final lessonProgressMap = <String, LessonProgress>{};
      if (progressData != null) {
        progressData.forEach((key, value) {
          if (value is Map<String, dynamic> &&
              value.containsKey('completed')) {
            lessonProgressMap[key] = LessonProgress.fromJson(value);
          }
        });
      }

      return UserMetrics(
        totalSessions: totalSessions,
        lastActive: lastActive,
        progress: lessonProgressMap,
        email: email,
        nickname: nickname,
        loginStreak: loginStreak,
        lastLoginDate: lastLoginDate,
      );
    } catch (e) {
      debugPrint('❌ Error al obtener métricas de $uid: $e');
      return null;
    }
  }

  /// Obtiene la lista resumida de todos los usuarios registrados.
  /// Retorna una lista de resúmenes con email, sesiones y última actividad.
  Future<List<UserSummary>> getAllUsers() async {
    try {
      if (!_firebaseService.isInitialized) {
        return [];
      }

      final snapshot = await _firebaseService.firestore
          .collection('users')
          .get();

      final users = <UserSummary>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final profileData = data['profile'] as Map<String, dynamic>?;

        final email = profileData?['email'] as String?;
        if (email == 'english.learning.app.4559e@gmail.com') continue;

        final nickname = profileData?['nickname'] as String?;
        final totalSessions =
            (profileData?['totalSessions'] as num?)?.toInt() ?? 0;

        DateTime? createdAt;
        if (profileData?['createdAt'] != null) {
          final createdAtStr = profileData!['createdAt'] as String?;
          if (createdAtStr != null) {
            createdAt = DateTime.tryParse(createdAtStr);
          }
        }

        DateTime? lastActive;
        if (profileData?['lastActive'] != null) {
          final ts = profileData!['lastActive'];
          if (ts is Timestamp) {
            lastActive = ts.toDate();
          }
        }

        final loginStreak =
            (profileData?['loginStreak'] as num?)?.toInt() ?? 0;

        final progressData = data['progress'] as Map<String, dynamic>?;
        int totalLessons = 0;
        int completedLessons = 0;
        if (progressData != null) {
          progressData.forEach((key, value) {
            if (value is Map<String, dynamic> &&
                value.containsKey('completed')) {
              totalLessons++;
              if (value['completed'] == true) {
                completedLessons++;
              }
            }
          });
        }

        users.add(
          UserSummary(
            uid: doc.id,
            email: email ?? 'Sin email',
            nickname: nickname,
            createdAt: createdAt,
            totalSessions: totalSessions,
            lastActive: lastActive,
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            loginStreak: loginStreak,
          ),
        );
      }

      users.sort((a, b) {
        if (a.lastActive == null && b.lastActive == null) return 0;
        if (a.lastActive == null) return 1;
        if (b.lastActive == null) return -1;
        return b.lastActive!.compareTo(a.lastActive!);
      });

      return users;
    } catch (e) {
      debugPrint('❌ Error al obtener lista de usuarios: $e');
      return [];
    }
  }

  /// Obtiene estadísticas globales de todos los usuarios.
  Future<GlobalStats> getGlobalStats() async {
    try {
      if (!_firebaseService.isInitialized) {
        return const GlobalStats();
      }

      final snapshot = await _firebaseService.firestore
          .collection('users')
          .get();

      int totalSessions = 0;
      int totalCompletedLessons = 0;
      int activeToday = 0;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final createdAts = <DateTime?>[];
      final sessionsByDayMaps = <Map<String, dynamic>?>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final profileData = data['profile'] as Map<String, dynamic>?;

        final email = profileData?['email'] as String?;
        if (email == 'english.learning.app.4559e@gmail.com') continue;

        totalSessions +=
            (profileData?['totalSessions'] as num?)?.toInt() ?? 0;

        if (profileData?['lastActive'] != null) {
          final ts = profileData!['lastActive'];
          if (ts is Timestamp) {
            final lastActive = ts.toDate();
            if (lastActive.isAfter(todayStart)) {
              activeToday++;
            }
          }
        }

        final createdAtStr = profileData?['createdAt'] as String?;
        createdAts.add(
          createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
        );

        sessionsByDayMaps.add(
          profileData?['sessionsByDay'] as Map<String, dynamic>?,
        );

        final progressData = data['progress'] as Map<String, dynamic>?;
        if (progressData != null) {
          progressData.forEach((key, value) {
            if (value is Map<String, dynamic> &&
                value['completed'] == true) {
              totalCompletedLessons++;
            }
          });
        }
      }

      return GlobalStats(
        totalUsers: snapshot.docs.where((doc) {
          final data = doc.data();
          final email = (data['profile'] as Map<String, dynamic>?)?['email'] as String?;
          return email != 'english.learning.app.4559e@gmail.com';
        }).length,
        totalSessions: totalSessions,
        totalCompletedLessons: totalCompletedLessons,
        activeToday: activeToday,
        newUsersThisWeek: countNewUsersThisWeek(createdAts),
        sessionsLast7Days: aggregateSessionsByDay(sessionsByDayMaps),
      );
    } catch (e) {
      debugPrint('❌ Error al obtener stats globales: $e');
      return const GlobalStats();
    }
  }

  /// Genera un string CSV con el resumen de todos los usuarios.
  Future<String> exportUsersCsv() async {
    final users = await getAllUsers();
    final buffer = StringBuffer();

    buffer.writeln('Email;Nickname;Fecha de Registro;Ultima Actividad;Racha de Login;Dias de Uso;Total de Sesiones;Lecciones Completadas;Total de Lecciones;Progreso (%)');

    for (final user in users) {
      final email = user.email.isNotEmpty ? user.email : 'No disponible';
      final nickname = (user.nickname != null && user.nickname!.isNotEmpty)
          ? user.nickname!
          : 'Sin nickname';

      final createdAt = user.createdAt != null
          ? '${user.createdAt!.day.toString().padLeft(2, '0')}/${user.createdAt!.month.toString().padLeft(2, '0')}/${user.createdAt!.year}'
          : 'Sin registro';

      final lastActive = user.lastActive != null
          ? '${user.lastActive!.day.toString().padLeft(2, '0')}/${user.lastActive!.month.toString().padLeft(2, '0')}/${user.lastActive!.year} ${user.lastActive!.hour.toString().padLeft(2, '0')}:${user.lastActive!.minute.toString().padLeft(2, '0')}'
          : 'Sin actividad';

      final racha = '${user.loginStreak} días';

      final diasDeUso = user.createdAt != null
          ? DateTime.now().difference(user.createdAt!).inDays.toString()
          : '0';

      final progreso = user.totalLessons > 0
          ? ((user.completedLessons / user.totalLessons) * 100).toStringAsFixed(1)
          : '0.0';

      buffer.writeln(
        '$email;$nickname;$createdAt;$lastActive;$racha;$diasDeUso;${user.totalSessions};${user.completedLessons};${user.totalLessons};$progreso%',
      );
    }

    return buffer.toString();
  }
}

/// Métricas simplificadas del usuario para visualización.
class UserMetrics {
  final int totalSessions;
  final DateTime? lastActive;
  final Map<String, LessonProgress> progress;
  final String? email;
  final String? nickname;
  final int loginStreak;
  final DateTime? lastLoginDate;

  const UserMetrics({
    required this.totalSessions,
    this.lastActive,
    required this.progress,
    this.email,
    this.nickname,
    this.loginStreak = 0,
    this.lastLoginDate,
  });
}

/// Resumen de un usuario para la lista del admin.
class UserSummary {
  final String uid;
  final String email;
  final String? nickname;
  final DateTime? createdAt;
  final int totalSessions;
  final DateTime? lastActive;
  final int totalLessons;
  final int completedLessons;
  final int loginStreak;

  const UserSummary({
    required this.uid,
    required this.email,
    this.nickname,
    this.createdAt,
    required this.totalSessions,
    this.lastActive,
    required this.totalLessons,
    required this.completedLessons,
    this.loginStreak = 0,
  });
}

/// Estadísticas globales de todos los usuarios.
class GlobalStats {
  final int totalUsers;
  final int totalSessions;
  final int totalCompletedLessons;
  final int activeToday;
  final int newUsersThisWeek;
  final List<DailyCount> sessionsLast7Days;

  const GlobalStats({
    this.totalUsers = 0,
    this.totalSessions = 0,
    this.totalCompletedLessons = 0,
    this.activeToday = 0,
    this.newUsersThisWeek = 0,
    this.sessionsLast7Days = const [],
  });
}

/// Conteo de sesiones de un día específico (para el gráfico del admin).
class DailyCount {
  final DateTime date;
  final int count;

  const DailyCount({required this.date, required this.count});
}

/// Clave de día en formato 'yyyy-MM-dd' usada en profile.sessionsByDay.
String formatDayKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

/// Agrega los mapas `sessionsByDay` ({'yyyy-MM-dd': count}) de varios
/// usuarios en una lista de los últimos [days] días (terminando hoy),
/// rellenando con 0 los días sin sesiones.
List<DailyCount> aggregateSessionsByDay(
  Iterable<Map<String, dynamic>?> perUserSessionsByDay, {
  int days = 7,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final todayStart = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );

  final totals = <String, int>{};
  for (final map in perUserSessionsByDay) {
    map?.forEach((key, value) {
      if (value is num) {
        totals[key] = (totals[key] ?? 0) + value.toInt();
      }
    });
  }

  return List.generate(days, (i) {
    final date = todayStart.subtract(Duration(days: days - 1 - i));
    return DailyCount(date: date, count: totals[formatDayKey(date)] ?? 0);
  });
}

/// Cuenta cuántas fechas de creación caen dentro de los últimos 7 días.
int countNewUsersThisWeek(Iterable<DateTime?> createdAts, {DateTime? now}) {
  final effectiveNow = now ?? DateTime.now();
  final weekAgo = effectiveNow.subtract(const Duration(days: 7));
  return createdAts.where((d) => d != null && d.isAfter(weekAgo)).length;
}
