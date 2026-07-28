import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/lessons_data.dart';
import '../models/lesson.dart';
import '../models/practice_activity.dart';
import '../services/sync_service.dart';

/// Servicio para gestionar actividades de práctica y su progreso
class PracticeService {
  static const String _progressPrefix = 'practice_progress_';
  
  // ==================== GESTIÓN DE ACTIVIDADES ====================

  /// Obtiene todas las actividades de práctica disponibles
  static Future<List<PracticeActivity>> getAllActivities() async {
    final lessons = lessonLevels.expand((level) => level.lessons).toList();
    final allActivities = <PracticeActivity>[];

    for (final lesson in lessons) {
      allActivities.addAll(_getActivitiesForLesson(lesson));
    }

    return allActivities;
  }

  /// Obtiene actividades específicas para una lección
  static List<PracticeActivity> _getActivitiesForLesson(Lesson lesson) {
    final activities = <PracticeActivity>[];
    final lessonId = lesson.id;
    final lessonTitle = lesson.title;
    final itemCount = lesson.items.length;

    // Spelling Challenge - Todos los niveles
    activities.add(PracticeActivity(
      id: '${lessonId}_spelling',
      lessonId: lessonId,
      type: PracticeActivityType.spelling,
      title: 'Spelling: $lessonTitle',
      description: 'Forma palabras arrastrando letras',
      iconEmoji: '🔤',
      totalExercises: itemCount,
      requiredLessons: [lessonId],
    ));

    // Listening Quiz - Todos los niveles
    activities.add(PracticeActivity(
      id: '${lessonId}_listening',
      lessonId: lessonId,
      type: PracticeActivityType.listening,
      title: 'Listening: $lessonTitle',
      description: 'Escucha y selecciona la imagen correcta',
      iconEmoji: '🎧',
      totalExercises: itemCount,
      requiredLessons: [lessonId],
    ));

    // Speed Match - Todos los niveles (requiere 2 estrellas en la lección)
    activities.add(PracticeActivity(
      id: '${lessonId}_speedmatch',
      lessonId: lessonId,
      type: PracticeActivityType.speedMatch,
      title: 'Speed Match: $lessonTitle',
      description: 'Empareja palabras con imágenes contra reloj',
      iconEmoji: '⚡',
      totalExercises: itemCount,
      requiredStars: 2,
      requiredLessons: [lessonId],
    ));

    // Picture Memory - Todos los niveles
    activities.add(PracticeActivity(
      id: '${lessonId}_memory',
      lessonId: lessonId,
      type: PracticeActivityType.pictureMemory,
      title: 'Memory: $lessonTitle',
      description: 'Encuentra los pares en el juego de memoria',
      iconEmoji: '🖼️',
      totalExercises: itemCount ~/ 2, // La mitad porque son pares
      requiredLessons: [], // Se verifica aparte (3 lecciones completadas)
    ));

    // Actividades avanzadas solo para Intermedio y Avanzado
    if (_isIntermediateOrAdvanced(lesson)) {
      // Word Scramble
      activities.add(PracticeActivity(
        id: '${lessonId}_scramble',
        lessonId: lessonId,
        type: PracticeActivityType.wordScramble,
        title: 'Scramble: $lessonTitle',
        description: 'Ordena las palabras para formar oraciones',
        iconEmoji: '🔀',
        totalExercises: itemCount,
        requiredLessons: [lessonId],
      ));

      // Fill the Blanks
      activities.add(PracticeActivity(
        id: '${lessonId}_fillblanks',
        lessonId: lessonId,
        type: PracticeActivityType.fillBlanks,
        title: 'Fill Blanks: $lessonTitle',
        description: 'Completa los espacios en las oraciones',
        iconEmoji: '📝',
        totalExercises: itemCount,
        requiredLessons: [lessonId],
      ));

      // True or False
      activities.add(PracticeActivity(
        id: '${lessonId}_truefalse',
        lessonId: lessonId,
        type: PracticeActivityType.trueFalse,
        title: 'True/False: $lessonTitle',
        description: 'Evalúa si las afirmaciones son verdaderas',
        iconEmoji: '✓✗',
        totalExercises: itemCount,
        requiredLessons: [lessonId],
      ));
    }

    return activities;
  }

  /// Verifica si una lección es de nivel Intermedio o Avanzado
  static bool _isIntermediateOrAdvanced(Lesson lesson) {
    // Las primeras 10 lecciones son Principiante (índices 0-9)
    // Intermedio: índices 10-19
    // Avanzado: índices 20+
    final allLessons = lessonLevels.expand((level) => level.lessons).toList();
    final lessonIndex = allLessons.indexWhere((l) => l.id == lesson.id);
    return lessonIndex >= 10;
  }

  /// Obtiene actividades filtradas por lección
  static Future<List<PracticeActivity>> getActivitiesByLesson(
    String lessonId,
  ) async {
    final allActivities = await getAllActivities();
    return allActivities.where((a) => a.lessonId == lessonId).toList();
  }

  /// Obtiene actividades filtradas por tipo
  static Future<List<PracticeActivity>> getActivitiesByType(
    PracticeActivityType type,
  ) async {
    final allActivities = await getAllActivities();
    return allActivities.where((a) => a.type == type).toList();
  }

  // ==================== SISTEMA DE DESBLOQUEO ====================

  /// Verifica si una actividad está desbloqueada
  static Future<bool> isActivityUnlocked(PracticeActivity activity) async {
    // TEMPORAL: Todas las actividades desbloqueadas para testing
    return true;
    
    // PRODUCCIÓN: Descomentar el código siguiente y comentar la línea anterior
    // // Verificar si la lección requerida está completada
    // for (final requiredLessonId in activity.requiredLessons) {
    //   final isCompleted = await LessonCompletionService.isLessonCompleted(
    //     requiredLessonId,
    //   );
    //   if (!isCompleted) return false;
    // }
    //
    // // Caso especial: Picture Memory requiere 3 lecciones completadas
    // if (activity.type == PracticeActivityType.pictureMemory) {
    //   final completedLessonIds = await LessonCompletionService.getCompletedLessonIds();
    //   return completedLessonIds.length >= 3;
    // }
    //
    // return true;
  }

  /// Obtiene todas las actividades con su estado de desbloqueo
  static Future<List<PracticeActivity>> getAllActivitiesWithUnlockStatus() async {
    final activities = await getAllActivities();
    final unlockedActivities = <PracticeActivity>[];

    for (final activity in activities) {
      final isUnlocked = await isActivityUnlocked(activity);
      unlockedActivities.add(activity.copyWith(isUnlocked: isUnlocked));
    }

    return unlockedActivities;
  }

  // ==================== GESTIÓN DE PROGRESO ====================

  /// Obtiene el progreso de una actividad específica
  static Future<PracticeProgress?> getProgress(String activityId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_progressPrefix$activityId';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return null;
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PracticeProgress.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Guarda el progreso de una actividad
  static Future<void> saveProgress(PracticeProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_progressPrefix${progress.activityId}';
    final jsonString = jsonEncode(progress.toJson());
    await prefs.setString(key, jsonString);

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();
  }

  /// Actualiza el progreso cuando se completa un ejercicio
  static Future<void> updateProgress({
    required String activityId,
    required int totalExercises,
    int exercisesCompleted = 1,
    int starsEarned = 0,
    int? newScore,
  }) async {
    var progress = await getProgress(activityId);
    
    progress ??= PracticeProgress(
        activityId: activityId,
        totalExercises: totalExercises,
      );

    final newCompletedCount = progress.completedExercises + exercisesCompleted;
    final newStarsCount = progress.starsEarned + starsEarned;
    final newBestScore = newScore != null && newScore > progress.bestScore
        ? newScore
        : progress.bestScore;
    final newTimesPlayed = progress.timesPlayed + 1;

    final updatedProgress = progress.copyWith(
      completedExercises: newCompletedCount.clamp(0, totalExercises),
      starsEarned: newStarsCount,
      bestScore: newBestScore,
      lastPlayed: DateTime.now(),
      timesPlayed: newTimesPlayed,
    );

    await saveProgress(updatedProgress);
  }

  /// Reinicia el progreso de una actividad
  static Future<void> resetProgress(String activityId, int totalExercises) async {
    final progress = PracticeProgress(
      activityId: activityId,
      totalExercises: totalExercises,
    );
    await saveProgress(progress);
  }

  /// Obtiene el progreso de todas las actividades
  static Future<Map<String, PracticeProgress>> getAllProgress() async {
    final activities = await getAllActivities();
    final progressMap = <String, PracticeProgress>{};

    for (final activity in activities) {
      final progress = await getProgress(activity.id);
      if (progress != null) {
        progressMap[activity.id] = progress;
      }
    }

    return progressMap;
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtiene el total de estrellas ganadas en actividades de práctica
  static Future<int> getTotalPracticeStars() async {
    final progressMap = await getAllProgress();
    return progressMap.values.fold<int>(
      0,
      (sum, progress) => sum + progress.starsEarned,
    );
  }

  /// Obtiene el total de actividades completadas
  static Future<int> getCompletedActivitiesCount() async {
    final progressMap = await getAllProgress();
    return progressMap.values.where((p) => p.isCompleted).length;
  }

  /// Obtiene el total de actividades disponibles
  static Future<int> getTotalActivitiesCount() async {
    final activities = await getAllActivities();
    return activities.length;
  }

  /// Obtiene el porcentaje de completitud global
  static Future<double> getGlobalCompletionPercentage() async {
    final total = await getTotalActivitiesCount();
    if (total == 0) return 0;
    
    final completed = await getCompletedActivitiesCount();
    return (completed / total * 100).clamp(0, 100);
  }

  // ==================== UTILIDADES ====================

  /// Limpia todos los datos de práctica
  static Future<void> clearAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_progressPrefix)) {
        await prefs.remove(key);
      }
    }
  }
}
