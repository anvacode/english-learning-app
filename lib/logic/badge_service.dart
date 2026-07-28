import 'package:english_ai_app/logic/lesson_completion_service.dart';
import 'package:english_ai_app/models/badge.dart';
import 'package:english_ai_app/models/lesson.dart';
import 'package:english_ai_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Badge definitions for each lesson.
final Map<String, Map<String, String>> badgeDefinitions = {
  'colors': {'title': 'Color Master', 'icon': '🎨'},
  'fruits': {'title': 'Fruit Expert', 'icon': '🍎'},
  'animals': {'title': 'Animal Friend', 'icon': '🐾'},
  'classroom': {'title': 'Classroom Expert', 'icon': '📚'},
  'family_1': {'title': 'Family Master', 'icon': '👨‍👩‍👧‍👦'},
  'numbers': {'title': 'Number Wizard', 'icon': '🔢'},
  'body_parts': {'title': 'Body Expert', 'icon': '👤'},
  'clothes': {'title': 'Fashion Master', 'icon': '👕'},
  'food_drinks': {'title': 'Food Lover', 'icon': '🍽️'},
  'actions': {'title': 'Action Hero', 'icon': '🏃'},
};

/// Service para obtener badges basado en LessonCompletion records.
/// 
/// Una lección tiene badge desbloqueado si existe un LessonCompletion record para ella.
class BadgeService {
  static final Map<String, Badge?> _cache = {};
  static bool _cacheLoaded = false;

  /// Carga todos los badges en caché de una vez.
  static Future<void> _loadCache() async {
    if (_cacheLoaded) return;

    final completedIds = await LessonCompletionService.getCompletedLessonIds();

    for (final entry in badgeDefinitions.entries) {
      final lessonId = entry.key;
      final badgeDef = entry.value;
      final isUnlocked = completedIds.contains(lessonId);

      _cache[lessonId] = Badge(
        lessonId: lessonId,
        title: badgeDef['title']!,
        icon: badgeDef['icon']!,
        unlocked: isUnlocked,
      );
    }

    _cacheLoaded = true;
  }

  /// Invalida la caché (llamar cuando cambie el estado de una lección).
  static void invalidateCache() {
    _cache.clear();
    _cacheLoaded = false;
  }

  /// Get all badges for a set of lessons.
  /// Badge is unlocked if a LessonCompletion record exists for the lesson.
  static Future<List<Badge>> getBadges(List<Lesson> lessons) async {
    await _loadCache();

    final badges = <Badge>[];
    for (final lesson in lessons) {
      final badge = _cache[lesson.id];
      if (badge != null) {
        badges.add(badge);
      }
    }

    return badges;
  }

  /// Get a badge for a specific lesson.
  static Future<Badge?> getBadge(Lesson lesson) async {
    await _loadCache();
    return _cache[lesson.id];
  }

  /// Check if a lesson just achieved mastery and award the badge.
  /// 
  /// This method:
  /// 1. Checks if the lesson is now completed (mastered)
  /// 2. If completed AND not previously awarded, marks as awarded in SharedPreferences
  /// 3. Returns true only if badge was just awarded (not previously awarded)
  /// 
  /// Use this when a lesson completes to give feedback to the user.
  static Future<bool> checkAndAwardBadge(Lesson lesson) async {
    final isCompleted = await LessonCompletionService.isLessonCompleted(lesson.id);
    
    // Only award if completed
    if (!isCompleted) {
      return false;
    }

    // Check if already awarded
    final prefs = await SharedPreferences.getInstance();
    final awardedKey = 'badge_awarded_${lesson.id}';
    final alreadyAwarded = prefs.getBool(awardedKey) ?? false;
    
    if (alreadyAwarded) {
      return false; // Badge already awarded before
    }

    // Award the badge (first time mastery achieved)
    await prefs.setBool(awardedKey, true);
    invalidateCache();

    // Disparar sincronización con la nube
    SyncService().syncUserDataDebounced();

    return true; // Just awarded
  }

  /// Check if a badge has already been awarded for a lesson.
  static Future<bool> isBadgeAwarded(String lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    final awardedKey = 'badge_awarded_$lessonId';
    return prefs.getBool(awardedKey) ?? false;
  }
}
