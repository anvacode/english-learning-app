import 'student.dart';
import 'sync_metadata.dart';
import 'user_profile.dart';

class UserSyncData {
  final String userId;
  final UserProfile profile;
  final Student student;
  final SyncMetadata metadata;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> gameProgress;
  final Map<String, dynamic> achievements;
  final Map<String, dynamic> inventory;

  const UserSyncData({
    required this.userId,
    required this.profile,
    required this.student,
    required this.metadata,
    required this.preferences,
    required this.gameProgress,
    required this.achievements,
    required this.inventory,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'profile': profile.toJson(),
    'student': student.toJson(),
    'metadata': metadata.toJson(),
    'preferences': preferences,
    'gameProgress': gameProgress,
    'achievements': achievements,
    'inventory': inventory,
  };

  factory UserSyncData.fromJson(Map<String, dynamic> json) => UserSyncData(
    userId: json['userId'] as String,
    profile: UserProfile.fromJson(json['profile'] as Map<String, dynamic>),
    student: Student.fromJson(json['student'] as Map<String, dynamic>),
    metadata: SyncMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    gameProgress: Map<String, dynamic>.from(json['gameProgress'] ?? {}),
    achievements: Map<String, dynamic>.from(json['achievements'] ?? {}),
    inventory: Map<String, dynamic>.from(json['inventory'] ?? {}),
  );

  UserSyncData copyWith({
    String? userId,
    UserProfile? profile,
    Student? student,
    SyncMetadata? metadata,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? gameProgress,
    Map<String, dynamic>? achievements,
    Map<String, dynamic>? inventory,
  }) {
    return UserSyncData(
      userId: userId ?? this.userId,
      profile: profile ?? this.profile,
      student: student ?? this.student,
      metadata: metadata ?? this.metadata,
      preferences: preferences ?? this.preferences,
      gameProgress: gameProgress ?? this.gameProgress,
      achievements: achievements ?? this.achievements,
      inventory: inventory ?? this.inventory,
    );
  }

  // Helper methods for data manipulation
  UserSyncData updateGameProgress(String gameId, Map<String, dynamic> progress) {
    final updatedProgress = Map<String, dynamic>.from(gameProgress);
    updatedProgress[gameId] = progress;
    return copyWith(gameProgress: updatedProgress);
  }

  UserSyncData addAchievement(String achievementId, Map<String, dynamic> achievement) {
    final updatedAchievements = Map<String, dynamic>.from(achievements);
    updatedAchievements[achievementId] = achievement;
    return copyWith(achievements: updatedAchievements);
  }

  UserSyncData updateInventory(String itemId, Map<String, dynamic> item) {
    final updatedInventory = Map<String, dynamic>.from(inventory);
    updatedInventory[itemId] = item;
    return copyWith(inventory: updatedInventory);
  }

  UserSyncData updatePreferences(Map<String, dynamic> newPreferences) {
    final updatedPreferences = Map<String, dynamic>.from(preferences);
    updatedPreferences.addAll(newPreferences);
    return copyWith(preferences: updatedPreferences);
  }

  // Validation
  bool get isValid {
    return userId.isNotEmpty &&
           profile.nickname.isNotEmpty &&
           metadata.deviceId.isNotEmpty;
  }

  // Size estimation for sync optimization
  int get estimatedSizeBytes {
    return toJson().toString().length * 2; // Rough estimation
  }
}