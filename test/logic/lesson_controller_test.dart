import 'package:english_ai_app/logic/lesson_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LessonController controller;

  setUp(() {
    controller = LessonController();
  });

  group('LessonController - initialization', () {
    test('starts with zero questions and no attempt', () {
      expect(controller.totalQuestions, 0);
      expect(controller.currentQuestionIndex, 0);
      expect(controller.correctAnswers, 0);
      expect(controller.progress, 0.0);
      expect(controller.isLessonCompleted, isFalse);
    });

    test('initializes lesson with correct question count', () {
      controller.initializeLesson(5);

      expect(controller.totalQuestions, 5);
      expect(controller.currentQuestionIndex, 0);
      expect(controller.correctAnswers, 0);
      expect(controller.progress, 0.0);
    });
  });

  group('LessonController - submitAnswer', () {
    test('returns false when lesson not initialized', () {
      final shouldRestart = controller.submitAnswer(
        itemId: 'q1',
        selectedOption: 'red',
        isCorrect: true,
      );
      expect(shouldRestart, isFalse);
    });

    test('advances to next question on correct answer', () {
      controller.initializeLesson(3);

      final shouldRestart = controller.submitAnswer(
        itemId: 'q1',
        selectedOption: 'red',
        isCorrect: true,
      );

      expect(shouldRestart, isFalse);
      expect(controller.currentQuestionIndex, 1);
      expect(controller.correctAnswers, 1);
    });

    test('does not advance on incorrect answer', () {
      controller.initializeLesson(3);

      controller.submitAnswer(
        itemId: 'q1',
        selectedOption: 'blue',
        isCorrect: false,
      );

      expect(controller.currentQuestionIndex, 0);
      expect(controller.correctAnswers, 0);
    });

    test('signals restart after max incorrect attempts', () {
      controller.initializeLesson(3);

      // 3 incorrect attempts should trigger restart
      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: false);
      controller.submitAnswer(itemId: 'q1', selectedOption: 'b', isCorrect: false);
      final shouldRestart = controller.submitAnswer(
        itemId: 'q1',
        selectedOption: 'c',
        isCorrect: false,
      );

      expect(shouldRestart, isTrue);
    });

    test('progress increases with correct answers', () {
      controller.initializeLesson(4);

      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: true);
      expect(controller.progress, 0.25);

      controller.submitAnswer(itemId: 'q2', selectedOption: 'b', isCorrect: true);
      expect(controller.progress, 0.5);
    });

    test('lesson is completed when all questions answered correctly', () {
      controller.initializeLesson(2);

      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: true);
      controller.submitAnswer(itemId: 'q2', selectedOption: 'b', isCorrect: true);

      expect(controller.isLessonCompleted, isTrue);
    });
  });

  group('LessonController - restartLesson', () {
    test('resets progress and question index', () {
      controller.initializeLesson(3);
      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: true);
      controller.submitAnswer(itemId: 'q2', selectedOption: 'b', isCorrect: true);

      controller.restartLesson();

      expect(controller.currentQuestionIndex, 0);
      expect(controller.correctAnswers, 0);
      expect(controller.isLessonCompleted, isFalse);
      expect(controller.totalQuestions, 3); // totalQuestions preserved
    });

    test('does nothing if lesson not initialized', () {
      controller.restartLesson();

      expect(controller.totalQuestions, 0);
      expect(controller.currentAttempt, isNull);
    });
  });

  group('LessonController - reset', () {
    test('clears all state', () {
      controller.initializeLesson(5);
      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: true);

      controller.reset();

      expect(controller.totalQuestions, 0);
      expect(controller.currentAttempt, isNull);
      expect(controller.progress, 0.0);
    });
  });

  group('LessonController - decrementQuestionIndex', () {
    test('decrements index when greater than 0', () {
      controller.initializeLesson(3);
      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: true);
      expect(controller.currentQuestionIndex, 1);

      controller.decrementQuestionIndex();
      expect(controller.currentQuestionIndex, 0);
    });

    test('does not decrement when at 0', () {
      controller.initializeLesson(3);

      controller.decrementQuestionIndex();
      expect(controller.currentQuestionIndex, 0);
    });

    test('does nothing when lesson not initialized', () {
      controller.decrementQuestionIndex();
      expect(controller.currentQuestionIndex, 0);
    });
  });

  group('LessonController - getIncorrectAttemptsForCurrentQuestion', () {
    test('returns 0 for unanswered question', () {
      controller.initializeLesson(3);
      expect(controller.getIncorrectAttemptsForCurrentQuestion('q1'), 0);
    });

    test('returns correct count after incorrect answers', () {
      controller.initializeLesson(3);

      controller.submitAnswer(itemId: 'q1', selectedOption: 'a', isCorrect: false);
      controller.submitAnswer(itemId: 'q1', selectedOption: 'b', isCorrect: false);

      expect(controller.getIncorrectAttemptsForCurrentQuestion('q1'), 2);
    });
  });
}
