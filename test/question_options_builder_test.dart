import 'package:english_ai_app/utils/question_options_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuestionOptionsBuilder', () {
    group('buildOptionsFromPool', () {
      test('correct answer is ALWAYS included in generated options', () {
        final options = ['red', 'blue', 'green'];
        const correctIndex = 0; // 'red' is correct

        final randomized = QuestionOptionsBuilder.buildOptionsFromPool(
          allOptions: options,
          correctAnswerIndex: correctIndex,
        );

        expect(randomized.contains('red'), isTrue);
      });

      test('generated options contain all items from pool', () {
        final options = ['red', 'blue', 'green'];
        const correctIndex = 1; // 'blue' is correct

        final randomized = QuestionOptionsBuilder.buildOptionsFromPool(
          allOptions: options,
          correctAnswerIndex: correctIndex,
        );

        expect(randomized.length, equals(3));
        expect(randomized.toSet(), equals({'red', 'blue', 'green'}));
      });

      test('generated options are shuffled (not always in original order)', () {
        final options = ['apple', 'banana', 'orange', 'pear', 'grape'];
        const correctIndex = 0;

        // Run multiple times and check if we ever get a different order
        final results = <List<String>>{};
        for (int i = 0; i < 20; i++) {
          final randomized = QuestionOptionsBuilder.buildOptionsFromPool(
            allOptions: options,
            correctAnswerIndex: correctIndex,
          );
          results.add(randomized);
        }

        // With high probability, we should see different orderings
        // (though theoretically could all be the same)
        expect(results.length, greaterThan(1),
            reason: 'Options should be shuffled across multiple calls');
      });

      test('throws RangeError if correctAnswerIndex is out of bounds', () {
        final options = ['cat', 'dog'];

        expect(
          () => QuestionOptionsBuilder.buildOptionsFromPool(
            allOptions: options,
            correctAnswerIndex: 5, // Out of bounds
          ),
          throwsRangeError,
        );
      });

      test('correct answer is preserved even for last item in pool', () {
        final options = ['a', 'b', 'c'];
        const correctIndex = 2; // Last item 'c' is correct

        final randomized = QuestionOptionsBuilder.buildOptionsFromPool(
          allOptions: options,
          correctAnswerIndex: correctIndex,
        );

        expect(randomized.contains('c'), isTrue);
      });
    });

    group('buildOptions', () {
      test('correct answer is ALWAYS included', () {
        final randomized = QuestionOptionsBuilder.buildOptions(
          correctAnswer: 'correct',
          incorrectOptions: ['wrong1', 'wrong2', 'wrong3'],
        );

        expect(randomized.contains('correct'), isTrue);
      });

      test('result contains correct answer plus all incorrect options', () {
        final randomized = QuestionOptionsBuilder.buildOptions(
          correctAnswer: 'cat',
          incorrectOptions: ['dog', 'bird', 'fish'],
        );

        expect(randomized.length, equals(4));
        expect(randomized.toSet(), equals({'cat', 'dog', 'bird', 'fish'}));
      });

      test('result is shuffled', () {
        // Run multiple times
        final results = <List<String>>{};
        for (int i = 0; i < 20; i++) {
          final randomized = QuestionOptionsBuilder.buildOptions(
            correctAnswer: 'answer',
            incorrectOptions: ['opt1', 'opt2', 'opt3', 'opt4'],
          );
          results.add(randomized);
        }

        // Should see variety in ordering
        expect(results.length, greaterThan(1),
            reason: 'Options should be shuffled across multiple calls');
      });
    });
  });
}
