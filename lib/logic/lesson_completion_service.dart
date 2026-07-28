import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lesson_completion.dart';
import '../services/sync_service.dart';

/// Service for managing lesson completions (mastery records).
///
/// Persists successful lesson completions to SharedPreferences.
/// This is the ONLY source of truth for determining lesson mastery.
class LessonCompletionService {
  static const String _storageKey = 'lesson_completions';

  /// Save a lesson completion record.
  ///
  /// Call this ONLY when a lesson is successfully completed.
  /// This represents transitioning a lesson to "Mastered" status.
  static Future<void> saveCompletion(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final completions = await getCompletions();

    // Check if already completed (don't duplicate)
    if (completions.any((c) => c.lessonId == lessonId)) {
      return;
    }

    // Add new completion
    completions.add(
      LessonCompletion(
        lessonId: lessonId,
        completedAt: DateTime.now(),
      ),
    );

    // Persist
    await prefs.setString(
      _storageKey,
      jsonEncode(completions.map((c) => c.toJson()).toList()),
    );

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();
  }

  /// Check if a lesson has been completed (mastered).
  static Future<bool> isLessonCompleted(String lessonId) async {
    final completions = await getCompletions();
    return completions.any((c) => c.lessonId == lessonId);
  }

  /// Get all lesson completions.
  static Future<List<LessonCompletion>> getCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final list = jsonDecode(jsonString) as List;
      return list
          .map((item) => LessonCompletion.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Error decoding lesson completions: $e
      return [];
    }
  }

  /// Get completed lesson IDs.
  static Future<Set<String>> getCompletedLessonIds() async {
    final completions = await getCompletions();
    return completions.map((c) => c.lessonId).toSet();
  }

  /// Clear all completions (for testing only).
  static Future<void> clearAllCompletions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
