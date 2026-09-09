import '../logic/activity_result_service.dart';
import '../logic/lesson_completion_service.dart';

/// Estados posibles del dominio de una lección.
enum LessonMasteryStatus {
  /// La lección no ha sido iniciada (sin resultados).
  notStarted,

  /// La lección ha sido iniciada pero no fue dominada (attempted but not perfect).
  inProgress,

  /// La lección ha sido dominada (100% correct in a single attempt).
  mastered,
}

/// Evaluador de dominio de lecciones basado en LessonCompletion records.
/// 
/// IMPORTANT: Lesson mastery is determined by the presence of a LessonCompletion record,
/// NOT by analyzing ActivityResult data.
/// 
/// State logic:
/// - mastered: LessonCompletion exists for this lesson
/// - inProgress: No LessonCompletion, but at least one ActivityResult exists
/// - notStarted: No LessonCompletion and no ActivityResult
class MasteryEvaluator {
  static final Map<String, LessonMasteryStatus> _cache = {};
  static bool _cacheLoaded = false;

  static Future<void> _loadCache() async {
    if (_cacheLoaded) return;

    final completedIds = await LessonCompletionService.getCompletedLessonIds();
    final allResults = await ActivityResultService.getActivityResults();

    final lessonIds = allResults.map((r) => r.lessonId).toSet();
    lessonIds.addAll(completedIds);

    for (final lessonId in lessonIds) {
      if (completedIds.contains(lessonId)) {
        _cache[lessonId] = LessonMasteryStatus.mastered;
      } else {
        final hasResults = allResults.any((r) => r.lessonId == lessonId);
        _cache[lessonId] = hasResults
            ? LessonMasteryStatus.inProgress
            : LessonMasteryStatus.notStarted;
      }
    }

    _cacheLoaded = true;
  }

  static void invalidateCache() {
    _cache.clear();
    _cacheLoaded = false;
  }

  Future<LessonMasteryStatus> evaluateLesson(String lessonId) async {
    await _loadCache();

    if (_cache.containsKey(lessonId)) {
      return _cache[lessonId]!;
    }

    return LessonMasteryStatus.notStarted;
  }

  /// Devuelve el estado de una lección de forma síncrona si el cache está cargado.
  /// Si el cache no está cargado, devuelve notStarted.
  LessonMasteryStatus evaluateLessonSync(String lessonId) {
    if (!_cacheLoaded) return LessonMasteryStatus.notStarted;
    return _cache[lessonId] ?? LessonMasteryStatus.notStarted;
  }

  /// Carga el cache si no está cargado. Útil para asegurar que los datos están disponibles.
  Future<void> ensureCacheLoaded() async {
    await _loadCache();
  }

  /// Evalúa si todas las lecciones en una lista están dominadas.
  Future<bool> areAllLessonsMastered(List<String> lessonIds) async {
    if (lessonIds.isEmpty) return true;

    for (final lessonId in lessonIds) {
      final status = await evaluateLesson(lessonId);
      if (status != LessonMasteryStatus.mastered) {
        return false;
      }
    }
    return true;
  }
}
