import 'package:english_ai_app/models/lesson_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LessonAttempt attempt;

  setUp(() {
    attempt = LessonAttempt(totalQuestions: 5);
  });

  group('LessonAttempt - initialization', () {
    test('starts with zero correct answers', () {
      expect(attempt.correctAnswersCount, 0);
    });

    test('starts at question index 0', () {
      expect(attempt.currentQuestionIndex, 0);
    });

    test('has empty correct item IDs', () {
      expect(attempt.correctItemIds, isEmpty);
    });

    test('has empty selected answers', () {
      expect(attempt.selectedAnswers, isEmpty);
    });

    test('has empty incorrect attempts', () {
      expect(attempt.incorrectAttemptsPerQuestion, isEmpty);
    });

    test('progress is 0', () {
      expect(attempt.progress, 0.0);
    });

    test('is not complete', () {
      expect(attempt.isComplete, isFalse);
    });
  });

  group('LessonAttempt - recordCorrectAnswer', () {
    test('adds item to correct item IDs', () {
      attempt.recordCorrectAnswer('q1');
      expect(attempt.correctItemIds.contains('q1'), isTrue);
    });

    test('increments correct answers count', () {
      attempt.recordCorrectAnswer('q1');
      expect(attempt.correctAnswersCount, 1);

      attempt.recordCorrectAnswer('q2');
      expect(attempt.correctAnswersCount, 2);
    });
  });

  group('LessonAttempt - recordSelectedAnswer', () {
    test('stores answer for item', () {
      attempt.recordSelectedAnswer('q1', 'red');
      expect(attempt.selectedAnswers['q1'], 'red');
    });

    test('overwrites previous answer for same item', () {
      attempt.recordSelectedAnswer('q1', 'red');
      attempt.recordSelectedAnswer('q1', 'blue');
      expect(attempt.selectedAnswers['q1'], 'blue');
    });
  });

  group('LessonAttempt - recordIncorrectAnswer', () {
    test('increments incorrect attempts count', () {
      attempt.recordIncorrectAnswer('q1');
      expect(attempt.getIncorrectAttempts('q1'), 1);

      attempt.recordIncorrectAnswer('q1');
      expect(attempt.getIncorrectAttempts('q1'), 2);
    });

    test('tracks different items separately', () {
      attempt.recordIncorrectAnswer('q1');
      attempt.recordIncorrectAnswer('q2');

      expect(attempt.getIncorrectAttempts('q1'), 1);
      expect(attempt.getIncorrectAttempts('q2'), 1);
    });
  });

  group('LessonAttempt - hasExceededMaxAttempts', () {
    test('returns false below max attempts', () {
      attempt.recordIncorrectAnswer('q1');
      attempt.recordIncorrectAnswer('q1');
      expect(attempt.hasExceededMaxAttempts('q1'), isFalse);
    });

    test('returns true at max attempts', () {
      attempt.recordIncorrectAnswer('q1');
      attempt.recordIncorrectAnswer('q1');
      attempt.recordIncorrectAnswer('q1');
      expect(attempt.hasExceededMaxAttempts('q1'), isTrue);
    });

    test('returns false for unanswered item', () {
      expect(attempt.hasExceededMaxAttempts('q1'), isFalse);
    });
  });

  group('LessonAttempt - nextQuestion', () {
    test('increments question index', () {
      attempt.nextQuestion();
      expect(attempt.currentQuestionIndex, 1);
    });

    test('does not exceed total questions', () {
      for (int i = 0; i < 10; i++) {
        attempt.nextQuestion();
      }
      expect(attempt.currentQuestionIndex, 4); // capped at totalQuestions - 1
    });
  });

  group('LessonAttempt - previousQuestion', () {
    test('decrements question index', () {
      attempt.nextQuestion();
      attempt.previousQuestion();
      expect(attempt.currentQuestionIndex, 0);
    });

    test('does not go below 0', () {
      attempt.previousQuestion();
      expect(attempt.currentQuestionIndex, 0);
    });
  });

  group('LessonAttempt - progress', () {
    test('calculates correct percentage', () {
      attempt.recordCorrectAnswer('q1');
      expect(attempt.progress, 0.2); // 1/5

      attempt.recordCorrectAnswer('q2');
      attempt.recordCorrectAnswer('q3');
      expect(attempt.progress, 0.6); // 3/5
    });

    test('returns 0 when totalQuestions is 0', () {
      final zeroAttempt = LessonAttempt(totalQuestions: 0);
      expect(zeroAttempt.progress, 0.0);
    });
  });

  group('LessonAttempt - isComplete', () {
    test('returns true when all questions answered correctly', () {
      for (int i = 0; i < 5; i++) {
        attempt.recordCorrectAnswer('q$i');
      }
      expect(attempt.isComplete, isTrue);
    });

    test('returns false when not all questions answered', () {
      attempt.recordCorrectAnswer('q1');
      attempt.recordCorrectAnswer('q2');
      expect(attempt.isComplete, isFalse);
    });
  });

  group('LessonAttempt - reset', () {
    test('clears all state', () {
      attempt.recordCorrectAnswer('q1');
      attempt.recordSelectedAnswer('q1', 'red');
      attempt.recordIncorrectAnswer('q2');
      attempt.nextQuestion();

      attempt.reset();

      expect(attempt.correctAnswersCount, 0);
      expect(attempt.currentQuestionIndex, 0);
      expect(attempt.correctItemIds, isEmpty);
      expect(attempt.selectedAnswers, isEmpty);
      expect(attempt.incorrectAttemptsPerQuestion, isEmpty);
    });
  });
}
