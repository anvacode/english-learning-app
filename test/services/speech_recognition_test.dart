
import 'package:english_ai_app/services/speech_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper class that exposes the pronunciation evaluation logic for testing.
/// Mirrors the private methods in SpeechRecognitionService.
class PronunciationTestHelper {
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static double calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  static int levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List<int>.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  static int calculateStarRating(double similarity) {
    if (similarity >= 0.95) return 5;
    if (similarity >= 0.8) return 4;
    if (similarity >= 0.6) return 3;
    if (similarity >= 0.4) return 2;
    return 1;
  }
}

void main() {
  group('PronunciationResult', () {
    test('creates with valid values', () {
      final result = PronunciationResult(
        recognizedText: 'hello',
        confidence: 0.9,
        starRating: 4,
        isCorrect: true,
        message: 'Great job!',
      );

      expect(result.recognizedText, 'hello');
      expect(result.confidence, 0.9);
      expect(result.starRating, 4);
      expect(result.isCorrect, isTrue);
      expect(result.message, 'Great job!');
    });
  });

  group('normalizeText', () {
    test('converts to lowercase', () {
      expect(PronunciationTestHelper.normalizeText('HELLO'), 'hello');
    });

    test('trims whitespace', () {
      expect(PronunciationTestHelper.normalizeText('  hello  '), 'hello');
    });

    test('removes punctuation', () {
      expect(PronunciationTestHelper.normalizeText('hello!'), 'hello');
      expect(PronunciationTestHelper.normalizeText("what's"), 'whats');
    });

    test('normalizes multiple spaces', () {
      expect(PronunciationTestHelper.normalizeText('hello   world'), 'hello world');
    });

    test('handles complex input', () {
      expect(
        PronunciationTestHelper.normalizeText('  Hello, World!  '),
        'hello world',
      );
    });
  });

  group('levenshteinDistance', () {
    test('returns 0 for identical strings', () {
      expect(PronunciationTestHelper.levenshteinDistance('hello', 'hello'), 0);
    });

    test('returns length for empty string', () {
      expect(PronunciationTestHelper.levenshteinDistance('', 'hello'), 5);
      expect(PronunciationTestHelper.levenshteinDistance('hello', ''), 5);
    });

    test('returns correct distance for single substitution', () {
      expect(PronunciationTestHelper.levenshteinDistance('cat', 'bat'), 1);
    });

    test('returns correct distance for single insertion', () {
      expect(PronunciationTestHelper.levenshteinDistance('cat', 'cart'), 1);
    });

    test('returns correct distance for single deletion', () {
      expect(PronunciationTestHelper.levenshteinDistance('cart', 'cat'), 1);
    });

    test('returns correct distance for multiple edits', () {
      expect(PronunciationTestHelper.levenshteinDistance('kitten', 'sitting'), 3);
    });

    test('handles completely different strings', () {
      expect(PronunciationTestHelper.levenshteinDistance('abc', 'xyz'), 3);
    });
  });

  group('calculateSimilarity', () {
    test('returns 1.0 for identical strings', () {
      expect(PronunciationTestHelper.calculateSimilarity('hello', 'hello'), 1.0);
    });

    test('returns 0.0 for empty strings', () {
      expect(PronunciationTestHelper.calculateSimilarity('', 'hello'), 0.0);
      expect(PronunciationTestHelper.calculateSimilarity('hello', ''), 0.0);
    });

    test('returns high similarity for small differences', () {
      final similarity = PronunciationTestHelper.calculateSimilarity('hello', 'helo');
      expect(similarity, greaterThan(0.7));
    });

    test('returns low similarity for completely different strings', () {
      final similarity = PronunciationTestHelper.calculateSimilarity('abc', 'xyz');
      expect(similarity, lessThan(0.5));
    });

    test('is symmetric', () {
      final sim1 = PronunciationTestHelper.calculateSimilarity('hello', 'world');
      final sim2 = PronunciationTestHelper.calculateSimilarity('world', 'hello');
      expect(sim1, sim2);
    });

    test('returns value between 0 and 1', () {
      final similarity = PronunciationTestHelper.calculateSimilarity('apple', 'apply');
      expect(similarity, inInclusiveRange(0.0, 1.0));
    });
  });

  group('calculateStarRating', () {
    test('returns 5 for perfect similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(1.0), 5);
    });

    test('returns 5 for 0.95+ similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(0.95), 5);
      expect(PronunciationTestHelper.calculateStarRating(0.99), 5);
    });

    test('returns 4 for 0.8+ similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(0.8), 4);
      expect(PronunciationTestHelper.calculateStarRating(0.9), 4);
    });

    test('returns 3 for 0.6+ similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(0.6), 3);
      expect(PronunciationTestHelper.calculateStarRating(0.7), 3);
    });

    test('returns 2 for 0.4+ similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(0.4), 2);
      expect(PronunciationTestHelper.calculateStarRating(0.5), 2);
    });

    test('returns 1 for low similarity', () {
      expect(PronunciationTestHelper.calculateStarRating(0.0), 1);
      expect(PronunciationTestHelper.calculateStarRating(0.3), 1);
    });

    test('star rating is always between 1 and 5', () {
      for (double sim = 0.0; sim <= 1.0; sim += 0.05) {
        final rating = PronunciationTestHelper.calculateStarRating(sim);
        expect(rating, inInclusiveRange(1, 5));
      }
    });
  });

  group('Integration - similarity with normalized text', () {
    test('case differences do not affect similarity', () {
      final sim1 = PronunciationTestHelper.calculateSimilarity(
        PronunciationTestHelper.normalizeText('Hello'),
        PronunciationTestHelper.normalizeText('HELLO'),
      );
      expect(sim1, 1.0);
    });

    test('punctuation differences do not affect similarity', () {
      final sim = PronunciationTestHelper.calculateSimilarity(
        PronunciationTestHelper.normalizeText('Hello!'),
        PronunciationTestHelper.normalizeText('hello'),
      );
      expect(sim, 1.0);
    });

    test('minor pronunciation errors still score well', () {
      final sim = PronunciationTestHelper.calculateSimilarity(
        PronunciationTestHelper.normalizeText('apple'),
        PronunciationTestHelper.normalizeText('aple'),
      );
      expect(sim, greaterThan(0.7));
    });
  });
}
