import 'package:english_ai_app/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    test('toJson and fromJson should be reversible', () {
      final profile = UserProfile(
        nickname: 'TestUser',
        avatarId: 5,
        englishLevel: 'beginner',
        createdAt: DateTime(2024, 6, 15),
      );

      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);

      expect(restored.nickname, profile.nickname);
      expect(restored.avatarId, profile.avatarId);
      expect(restored.englishLevel, profile.englishLevel);
      expect(restored.createdAt, profile.createdAt);
    });

    test('fromJson handles null englishLevel', () {
      final json = {
        'nickname': 'User',
        'avatarId': 0,
        'englishLevel': null,
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.englishLevel, isNull);
    });

    test('defaultProfile creates valid profile', () {
      final profile = UserProfile.defaultProfile();

      expect(profile.nickname, 'Estudiante');
      expect(profile.avatarId, 0);
      expect(profile.englishLevel, isNull);
    });

    test('copyWith updates specified fields', () {
      final original = UserProfile(
        nickname: 'OldName',
        avatarId: 1,
        englishLevel: 'beginner',
        createdAt: DateTime(2024),
      );

      final updated = original.copyWith(
        nickname: 'NewName',
        avatarId: 5,
      );

      expect(updated.nickname, 'NewName');
      expect(updated.avatarId, 5);
      expect(updated.englishLevel, 'beginner'); // unchanged
      expect(updated.createdAt, original.createdAt); // unchanged
    });

    test('copyWith clearEnglishLevel sets to null', () {
      final original = UserProfile(
        nickname: 'User',
        avatarId: 1,
        englishLevel: 'intermediate',
        createdAt: DateTime(2024),
      );

      final updated = original.copyWith(clearEnglishLevel: true);
      expect(updated.englishLevel, isNull);
    });

    test('isValidAvatarId returns true for valid range', () {
      for (int i = 0; i <= 10; i++) {
        final profile = UserProfile(
          nickname: 'User',
          avatarId: i,
          createdAt: DateTime.now(),
        );
        expect(profile.isValidAvatarId, isTrue, reason: 'avatarId=$i should be valid');
      }
    });

    test('isValidAvatarId returns false for invalid range', () {
      final profile1 = UserProfile(
        nickname: 'User',
        avatarId: -1,
        createdAt: DateTime.now(),
      );
      final profile2 = UserProfile(
        nickname: 'User',
        avatarId: 11,
        createdAt: DateTime.now(),
      );
      expect(profile1.isValidAvatarId, isFalse);
      expect(profile2.isValidAvatarId, isFalse);
    });

    test('isShopAvatar returns true for shop avatar IDs', () {
      for (int i = 8; i <= 10; i++) {
        final profile = UserProfile(
          nickname: 'User',
          avatarId: i,
          createdAt: DateTime.now(),
        );
        expect(profile.isShopAvatar, isTrue, reason: 'avatarId=$i should be shop avatar');
      }
    });

    test('isShopAvatar returns false for non-shop avatar IDs', () {
      final profile = UserProfile(
        nickname: 'User',
        avatarId: 3,
        createdAt: DateTime.now(),
      );
      expect(profile.isShopAvatar, isFalse);
    });

    test('englishLevelDisplayName returns correct Spanish labels', () {
      final beginner = UserProfile(
        nickname: 'User',
        avatarId: 0,
        englishLevel: 'beginner',
        createdAt: DateTime.now(),
      );
      final intermediate = beginner.copyWith(englishLevel: 'intermediate');
      final advanced = beginner.copyWith(englishLevel: 'advanced');
      final none = beginner.copyWith(clearEnglishLevel: true);

      expect(beginner.englishLevelDisplayName, 'Principiante');
      expect(intermediate.englishLevelDisplayName, 'Intermedio');
      expect(advanced.englishLevelDisplayName, 'Avanzado');
      expect(none.englishLevelDisplayName, 'No determinado');
    });
  });
}
