import 'package:english_ai_app/logic/star_service.dart';
import 'package:english_ai_app/models/star_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StarService.clearAllTransactions();
    StarService.starCountNotifier.value = 0;
  });

  group('StarTransaction', () {
    test('toJson and fromJson should be reversible', () {
      final transaction = StarTransaction(
        id: 'test-id',
        type: 'lesson_complete',
        amount: 10,
        description: 'Completaste una lección (+10 ⭐)',
        timestamp: DateTime(2024, 1, 15, 10, 30),
        lessonId: 'colors',
      );

      final json = transaction.toJson();
      final restored = StarTransaction.fromJson(json);

      expect(restored.id, transaction.id);
      expect(restored.type, transaction.type);
      expect(restored.amount, transaction.amount);
      expect(restored.description, transaction.description);
      expect(restored.timestamp, transaction.timestamp);
      expect(restored.lessonId, transaction.lessonId);
    });

    test('isEarning returns true for positive amount', () {
      final transaction = StarTransaction(
        id: '1',
        type: 'lesson_complete',
        amount: 10,
        description: 'Test',
        timestamp: DateTime.now(),
      );
      expect(transaction.isEarning, isTrue);
      expect(transaction.isSpending, isFalse);
    });

    test('isSpending returns true for negative amount', () {
      final transaction = StarTransaction(
        id: '2',
        type: 'shop_purchase',
        amount: -50,
        description: 'Compra: Avatar',
        timestamp: DateTime.now(),
      );
      expect(transaction.isSpending, isTrue);
      expect(transaction.isEarning, isFalse);
    });
  });

  group('StarService - getTotalStars', () {
    test('returns 0 when no transactions exist', () async {
      final total = await StarService.getTotalStars();
      expect(total, 0);
    });

    test('returns correct total after adding stars', () async {
      await StarService.addStars(10, 'lesson_complete');
      await StarService.addStars(5, 'daily_login');

      final total = await StarService.getTotalStars();
      expect(total, 15);
    });

    test('returns correct total after spending stars', () async {
      await StarService.addStars(100, 'lesson_complete');
      await StarService.spendStars(30, 'Avatar Estrella');

      final total = await StarService.getTotalStars();
      expect(total, 70);
    });
  });

  group('StarService - addStars', () {
    test('throws ArgumentError for zero amount', () async {
      expect(
        () => StarService.addStars(0, 'lesson_complete'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for negative amount', () async {
      expect(
        () => StarService.addStars(-5, 'lesson_complete'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('adds stars with correct amount', () async {
      await StarService.addStars(20, 'lesson_complete', lessonId: 'colors');

      final total = await StarService.getTotalStars();
      expect(total, 20);
    });

    test('creates transaction with correct type', () async {
      await StarService.addStars(10, 'daily_login');

      final history = await StarService.getTransactionHistory();
      expect(history.length, 1);
      expect(history.first.type, 'daily_login');
      expect(history.first.amount, 10);
    });

    test('updates starCountNotifier', () async {
      final before = StarService.starCountNotifier.value;
      await StarService.addStars(25, 'lesson_complete');

      expect(StarService.starCountNotifier.value, greaterThan(before));
      expect(await StarService.getTotalStars(), 25);
    });
  });

  group('StarService - spendStars', () {
    test('throws StateError when insufficient stars', () async {
      await StarService.addStars(10, 'lesson_complete');

      expect(
        () => StarService.spendStars(50, 'Expensive Item'),
        throwsA(isA<StateError>()),
      );
    });

    test('throws ArgumentError for zero amount', () async {
      expect(
        () => StarService.spendStars(0, 'Item'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for negative amount', () async {
      expect(
        () => StarService.spendStars(-10, 'Item'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('deducts correct amount', () async {
      await StarService.addStars(100, 'lesson_complete');
      await StarService.spendStars(40, 'Avatar Estrella');

      final total = await StarService.getTotalStars();
      expect(total, 60);
    });

    test('creates negative transaction', () async {
      await StarService.addStars(100, 'lesson_complete');
      await StarService.spendStars(30, 'Theme Rainbow');

      final history = await StarService.getTransactionHistory();
      final spendingTx = history.firstWhere((t) => t.isSpending);
      expect(spendingTx.amount, -30);
      expect(spendingTx.itemName, 'Theme Rainbow');
    });
  });

  group('StarService - getTransactionHistory', () {
    test('returns empty list when no transactions', () async {
      final history = await StarService.getTransactionHistory();
      expect(history, isEmpty);
    });

    test('returns transactions sorted by date (newest first)', () async {
      await StarService.addStars(10, 'lesson_complete');
      await StarService.addStars(20, 'daily_login');

      final history = await StarService.getTransactionHistory();
      expect(history.length, 2);
      expect(history.first.amount, 20);
      expect(history.last.amount, 10);
    });
  });

  group('StarService - getStarsEarnedToday', () {
    test('returns 0 when no transactions today', () async {
      final earned = await StarService.getStarsEarnedToday();
      expect(earned, 0);
    });

    test('returns sum of today earnings', () async {
      await StarService.addStars(10, 'lesson_complete');
      await StarService.addStars(5, 'daily_login');

      final earned = await StarService.getStarsEarnedToday();
      expect(earned, 15);
    });

    test('excludes spending transactions', () async {
      await StarService.addStars(100, 'lesson_complete');
      await StarService.spendStars(30, 'Item');

      final earned = await StarService.getStarsEarnedToday();
      expect(earned, 100);
    });
  });

  group('StarService - login streak', () {
    test('returns 0 when no login recorded', () async {
      final streak = await StarService.getLoginStreak();
      expect(streak, 0);
    });

    test('returns 1 on first login', () async {
      final streak = await StarService.updateLoginStreak();
      expect(streak, 1);
    });

    test('increments streak on consecutive day', () async {
      await StarService.updateLoginStreak();

      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await prefs.setString('last_login_date', yesterday.toIso8601String());

      final streak = await StarService.updateLoginStreak();
      expect(streak, 2);
    });

    test('resets streak after gap of 2+ days', () async {
      await StarService.updateLoginStreak();

      final prefs = await SharedPreferences.getInstance();
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await prefs.setString('last_login_date', twoDaysAgo.toIso8601String());

      final streak = await StarService.updateLoginStreak();
      expect(streak, 1);
    });

    test('same day login does not increment streak', () async {
      final first = await StarService.updateLoginStreak();
      final second = await StarService.updateLoginStreak();

      expect(first, 1);
      expect(second, 1);
    });
  });

  group('StarService - processDailyLogin', () {
    test('awards 10 stars on first login', () async {
      final earned = await StarService.processDailyLogin();
      expect(earned, 10);

      final total = await StarService.getTotalStars();
      expect(total, 10);
    });

    test('returns 0 if already logged in today', () async {
      await StarService.processDailyLogin();
      final secondEarned = await StarService.processDailyLogin();
      expect(secondEarned, 0);
    });

    test('awards streak bonus on consecutive days', () async {
      await StarService.processDailyLogin();

      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await prefs.setString('last_login_date', yesterday.toIso8601String());

      final earned = await StarService.processDailyLogin();
      expect(earned, 15); // 10 base + 5 streak bonus
    });
  });

  group('StarService - clearAllTransactions', () {
    test('removes all transactions and resets total', () async {
      await StarService.addStars(50, 'lesson_complete');
      await StarService.clearAllTransactions();

      final total = await StarService.getTotalStars();
      final history = await StarService.getTransactionHistory();

      expect(total, 0);
      expect(history, isEmpty);
    });
  });
}
