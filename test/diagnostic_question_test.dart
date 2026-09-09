import 'package:english_ai_app/data/diagnostic_questions_data.dart';
import 'package:english_ai_app/models/diagnostic_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiagnosticQuestion', () {
    test('isCorrect returns true when correct index selected', () {
      const question = DiagnosticQuestion(
        id: '1',
        questionEn: 'Which is the DOG?',
        questionEs: '¿Which is the DOG?',
        mainEmoji: '🐕',
        options: ['🐱', '🐕', '🦊', '🐰'],
        correctAnswerIndex: 1,
        type: DiagnosticQuestionType.vocab,
      );

      expect(question.isCorrect(1), isTrue);
    });

    test('isCorrect returns false when wrong index selected', () {
      const question = DiagnosticQuestion(
        id: '1',
        questionEn: 'Which is the DOG?',
        questionEs: '¿Which is the DOG?',
        mainEmoji: '🐕',
        options: ['🐱', '🐕', '🦊', '🐰'],
        correctAnswerIndex: 1,
        type: DiagnosticQuestionType.vocab,
      );

      expect(question.isCorrect(0), isFalse);
      expect(question.isCorrect(2), isFalse);
      expect(question.isCorrect(3), isFalse);
    });

    test('question getter returns Spanish question', () {
      const question = DiagnosticQuestion(
        id: '1',
        questionEn: 'Which is the DOG?',
        questionEs: '¿Which is the DOG?',
        mainEmoji: '🐕',
        options: ['🐱', '🐕', '🦊', '🐰'],
        correctAnswerIndex: 1,
        type: DiagnosticQuestionType.vocab,
      );

      expect(question.question, equals('¿Which is the DOG?'));
    });

    test('questionEnglish getter returns English question', () {
      const question = DiagnosticQuestion(
        id: '1',
        questionEn: 'Which is the DOG?',
        questionEs: '¿Which is the DOG?',
        mainEmoji: '🐕',
        options: ['🐱', '🐕', '🦊', '🐰'],
        correctAnswerIndex: 1,
        type: DiagnosticQuestionType.vocab,
      );

      expect(question.questionEnglish, equals('Which is the DOG?'));
    });
  });

  group('DiagnosticQuestionsData', () {
    test('questions list has 10 questions', () {
      expect(DiagnosticQuestionsData.questions.length, equals(10));
    });

    test('all questions have 4 options', () {
      for (final question in DiagnosticQuestionsData.questions) {
        expect(
          question.options.length,
          equals(4),
          reason: 'Question ${question.id} should have 4 options',
        );
      }
    });

    test('all questions have valid correctAnswerIndex', () {
      for (final question in DiagnosticQuestionsData.questions) {
        expect(question.correctAnswerIndex, greaterThanOrEqualTo(0));
        expect(question.correctAnswerIndex, lessThan(4));
      }
    });

    test('first question is about DOG', () {
      final firstQuestion = DiagnosticQuestionsData.questions.first;
      expect(firstQuestion.mainEmoji, equals('🐕'));
      expect(firstQuestion.correctAnswerIndex, equals(1));
    });

    test('questions include different types', () {
      final types = DiagnosticQuestionsData.questions
          .map((q) => q.type)
          .toSet();

      expect(types.contains(DiagnosticQuestionType.vocab), isTrue);
      expect(types.contains(DiagnosticQuestionType.color), isTrue);
      expect(types.contains(DiagnosticQuestionType.number), isTrue);
    });
  });
}
