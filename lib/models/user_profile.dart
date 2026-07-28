import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Modelo que representa el perfil del usuario.
///
/// Contiene información básica del usuario como nickname,
/// avatar seleccionado, nivel de inglés y fecha de creación.
class UserProfile {
  final String nickname;
  final int avatarId;
  final String? englishLevel;
  final DateTime createdAt;
  final int totalSessions;
  final DateTime? lastActive;
  final Map<String, LessonProgress> progress;
  final DateTime? lastUpdated;

  const UserProfile({
    required this.nickname,
    required this.avatarId,
    this.englishLevel,
    required this.createdAt,
    this.totalSessions = 0,
    this.lastActive,
    this.progress = const {},
    this.lastUpdated,
  });

  factory UserProfile.defaultProfile() {
    return UserProfile(
      nickname: 'Estudiante',
      avatarId: 0,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? nickname,
    int? avatarId,
    String? englishLevel,
    DateTime? createdAt,
    int? totalSessions,
    DateTime? lastActive,
    Map<String, LessonProgress>? progress,
    DateTime? lastUpdated,
    bool clearEnglishLevel = false,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      avatarId: avatarId ?? this.avatarId,
      englishLevel: clearEnglishLevel
          ? null
          : (englishLevel ?? this.englishLevel),
      createdAt: createdAt ?? this.createdAt,
      totalSessions: totalSessions ?? this.totalSessions,
      lastActive: lastActive ?? this.lastActive,
      progress: progress ?? this.progress,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    final progressMap = <String, dynamic>{};
    progress.forEach((key, value) {
      progressMap[key] = value.toJson();
    });

    return {
      'nickname': nickname,
      'avatarId': avatarId,
      'englishLevel': englishLevel,
      'createdAt': createdAt.toIso8601String(),
      'totalSessions': totalSessions,
      if (lastActive != null) 'lastActive': lastActive!.toIso8601String(),
      if (progressMap.isNotEmpty) 'progress': progressMap,
      if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final progressData = json['progress'] as Map<String, dynamic>?;
    final parsedProgress = <String, LessonProgress>{};

    if (progressData != null) {
      progressData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          parsedProgress[key] = LessonProgress.fromJson(value);
        }
      });
    }

    return UserProfile(
      nickname: json['nickname'] as String,
      avatarId: json['avatarId'] as int,
      englishLevel: json['englishLevel'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      totalSessions: json['totalSessions'] as int? ?? 0,
      lastActive: _parseTimestamp(json['lastActive']),
      progress: parsedProgress,
      lastUpdated: _parseTimestamp(json['lastUpdated']),
    );
  }

  bool get isValidAvatarId => avatarId >= 0 && avatarId <= 10;

  bool get isShopAvatar => avatarId >= 8 && avatarId <= 10;

  String get englishLevelDisplayName {
    switch (englishLevel) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return 'No determinado';
    }
  }
}

/// Progreso detallado de una lección específica.
class LessonProgress {
  final bool completed;
  final int stars;
  final double bestAccuracy;
  final int attempts;
  final DateTime? lastPlayed;

  const LessonProgress({
    this.completed = false,
    this.stars = 0,
    this.bestAccuracy = 0.0,
    this.attempts = 0,
    this.lastPlayed,
  });

  Map<String, dynamic> toJson() {
    return {
      'completed': completed,
      'stars': stars,
      'bestAccuracy': bestAccuracy,
      'attempts': attempts,
      if (lastPlayed != null) 'lastPlayed': lastPlayed!.toIso8601String(),
    };
  }

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      completed: json['completed'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
      attempts: json['attempts'] as int? ?? 0,
      lastPlayed: _parseTimestamp(json['lastPlayed']),
    );
  }

  LessonProgress copyWith({
    bool? completed,
    int? stars,
    double? bestAccuracy,
    int? attempts,
    DateTime? lastPlayed,
  }) {
    return LessonProgress(
      completed: completed ?? this.completed,
      stars: stars ?? this.stars,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      attempts: attempts ?? this.attempts,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}
