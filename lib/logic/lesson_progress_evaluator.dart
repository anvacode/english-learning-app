import 'dart:async';

import '../logic/activity_result_service.dart';
import '../models/lesson.dart';

/// Estados posibles del progreso de una lección.
enum LessonProgressStatus {
  notStarted,
  inProgress,
  mastered,
}

/// Resultado simple del progreso de una lección.
class LessonProgress {
  final int completedCount;
  final int totalCount;
  final LessonProgressStatus status;

  LessonProgress({
    required this.completedCount,
    required this.totalCount,
    required this.status,
  });
}

/// Servizio único que calcula progreso de lecciones.
///
/// Reglas estrictas (basadas en ejercicios, no en intentos):
/// - Cuenta ejercicios completados (max 1 por ejercicio)
/// - Progress = ejercicios completados / total de ejercicios
/// - El estado se determina por progress
class LessonProgressService {
  Future<LessonProgress> evaluate(Lesson lesson) async {
    // If lesson has no exercises defined, fall back to item-based progress
    // (for backward compatibility with existing lessons)
    if (lesson.exercises.isEmpty) {
      return _evaluateItemBased(lesson);
    }

    // Exercise-based progress calculation
    final completedExercises = await _getCompletedExercises(lesson);
    final completedCount = completedExercises.length;
    final totalCount = lesson.exercises.length;

    final status = completedCount == 0
        ? LessonProgressStatus.notStarted
        : (completedCount < totalCount
            ? LessonProgressStatus.inProgress
            : LessonProgressStatus.mastered);

    return LessonProgress(
      completedCount: completedCount,
      totalCount: totalCount,
      status: status,
    );
  }

  /// Item-based progress (legacy, for lessons without exercise definitions)
  Future<LessonProgress> _evaluateItemBased(Lesson lesson) async {
    final allResults = await ActivityResultService.getActivityResults();

    final correctResults = allResults.where((r) =>
      r.lessonId == lesson.id && r.isCorrect
    ).toList();

    final completedItemIds = <String>{};
    for (final r in correctResults) {
      completedItemIds.add(r.itemId);
    }

    final completedCount = completedItemIds.length;
    final totalCount = lesson.items.length;

    final status = completedCount == 0
        ? LessonProgressStatus.notStarted
        : (completedCount < totalCount
            ? LessonProgressStatus.inProgress
            : LessonProgressStatus.mastered);

    return LessonProgress(
      completedCount: completedCount,
      totalCount: totalCount,
      status: status,
    );
  }

  /// Get the list of completed exercises for a lesson
  Future<List<String>> _getCompletedExercises(Lesson lesson) async {
    final completedExercises = <String>[];

    // Check each exercise type
    for (int i = 0; i < lesson.exercises.length; i++) {
      final exercise = lesson.exercises[i];
      final isCompleted = await _isExerciseCompleted(lesson, exercise, i);
      if (isCompleted) {
        completedExercises.add('exercise_$i');
      }
    }

    return completedExercises;
  }

  /// Check if a specific exercise is completed
  Future<bool> _isExerciseCompleted(
    Lesson lesson,
    dynamic exercise,
    int exerciseIndex,
  ) async {
    final allResults = await ActivityResultService.getActivityResults();

    // For multipleChoice exercises: check if all items are completed AND accuracy >= 80%
    if (exercise.type.toString() == 'ExerciseType.multipleChoice') {
      final itemIds = lesson.items.map((item) => item.id).toSet();
      final lessonResults = allResults.where((r) => r.lessonId == lesson.id).toList();
      final completedIds = lessonResults
          .where((r) => r.isCorrect)
          .map((r) => r.itemId)
          .toSet();
      
      // First check: all items must be answered at least once correctly
      final allItemsCompleted = itemIds.every((id) => completedIds.contains(id));
      if (!allItemsCompleted) {
        return false;
      }
      
      // Second check: accuracy must be >= 80% to mark exercise as completed
      final totalAttempts = lessonResults.length;
      if (totalAttempts == 0) {
        return false; // No attempts, not completed
      }
      
      final correctAttempts = lessonResults.where((r) => r.isCorrect).length;
      final accuracyPercentage = (correctAttempts * 100) ~/ totalAttempts;
      
      return accuracyPercentage >= 80; // Exercise complete only if accuracy >= 80%
    }

    // For matching exercises: check for matching_exercise result
    if (exercise.type.toString() == 'ExerciseType.matching') {
      return allResults.any((r) =>
          r.lessonId == lesson.id &&
          r.itemId == 'matching_exercise' &&
          r.isCorrect);
    }

    return false;
  }
}
