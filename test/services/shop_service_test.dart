import 'package:english_ai_app/logic/star_service.dart';
import 'package:english_ai_app/models/shop_item.dart';
import 'package:english_ai_app/services/shop_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StarService.clearAllTransactions();
    await ShopService.clearAllPurchases();
    StarService.starCountNotifier.value = 0;
  });

  group('ShopService - getAvailableItems', () {
    test('returns non-empty list of items', () {
      final items = ShopService.getAvailableItems();
      expect(items.isNotEmpty, isTrue);
    });

    test('contains effects and powerups', () {
      final items = ShopService.getAvailableItems();
      final types = items.map((i) => i.type).toSet();

      expect(types.contains(ShopItemType.effect), isTrue);
      expect(types.contains(ShopItemType.powerup), isTrue);
    });

    test('all items have valid prices', () {
      final items = ShopService.getAvailableItems();
      expect(items.every((i) => i.price > 0), isTrue);
    });

    test('all items have unique IDs', () {
      final items = ShopService.getAvailableItems();
      final ids = items.map((i) => i.id).toList();
      expect(ids.length, ids.toSet().length);
    });
  });

  group('ShopService - purchase validation', () {
    test('throws StateError when insufficient stars', () async {
      final item = ShopService.getAvailableItems().first;

      expect(
        () => ShopService.purchaseItem(item),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when item already purchased', () async {
      const item = ShopItem(
        id: 'test_item',
        name: 'Test',
        description: 'Test',
        price: 10,
        type: ShopItemType.other,
        icon: '🧪',
      );

      await StarService.addStars(100, 'lesson_complete');
      await ShopService.purchaseItem(item);

      expect(
        () => ShopService.purchaseItem(item),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ShopService - purchaseItem', () {
    test('purchases item and deducts stars', () async {
      await StarService.addStars(100, 'lesson_complete');
      const item = ShopItem(
        id: 'test_item',
        name: 'Test Item',
        description: 'A test item',
        price: 30,
        type: ShopItemType.other,
        icon: '🧪',
      );

      await ShopService.purchaseItem(item);

      final purchased = await ShopService.isItemPurchased('test_item');
      expect(purchased, isTrue);

      final total = await StarService.getTotalStars();
      expect(total, 70);
    });

    test('marks item as purchased', () async {
      await StarService.addStars(55, 'lesson_complete');
      final item = ShopService.getAvailableItems()[0]; // effect_sparkles (55 stars)

      await ShopService.purchaseItem(item);

      final purchased = await ShopService.isItemPurchased(item.id);
      expect(purchased, isTrue);
    });

    test('activates powerup with expiration date', () async {
      await StarService.addStars(200, 'lesson_complete');
      final powerup = ShopService.getAvailableItems().firstWhere(
        (i) => i.type == ShopItemType.powerup,
      );

      await ShopService.purchaseItem(powerup);

      final prefs = await SharedPreferences.getInstance();
      final expiration = prefs.getString('powerup_expiration_${powerup.id}');
      expect(expiration, isNotNull);
    });
  });

  group('ShopService - getPurchasedItems', () {
    test('returns empty list when nothing purchased', () async {
      final purchased = await ShopService.getPurchasedItems();
      expect(purchased, isEmpty);
    });

    test('returns purchased items after purchase', () async {
      await StarService.addStars(200, 'lesson_complete');
      final item = ShopService.getAvailableItems()[0];

      await ShopService.purchaseItem(item);

      final purchased = await ShopService.getPurchasedItems();
      expect(purchased.length, 1);
      expect(purchased.first.id, item.id);
    });
  });

  group('ShopService - getActiveAvatarId', () {
    test('returns null when no avatars purchased', () async {
      final avatarId = await ShopService.getActiveAvatarId();
      expect(avatarId, isNull);
    });
  });

  group('ShopItem', () {
    test('toJson and fromJson should be reversible', () {
      const item = ShopItem(
        id: 'test_id',
        name: 'Test Item',
        description: 'A test item',
        price: 25,
        type: ShopItemType.effect,
        icon: '✨',
        imageAsset: 'assets/test.png',
        metadata: {'effectId': 'test'},
      );

      final json = item.toJson();
      final restored = ShopItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.description, item.description);
      expect(restored.price, item.price);
      expect(restored.type, item.type);
      expect(restored.icon, item.icon);
      expect(restored.imageAsset, item.imageAsset);
      expect(restored.metadata, item.metadata);
    });

    test('fromJson handles unknown type gracefully', () {
      final json = {
        'id': 'unknown',
        'name': 'Unknown',
        'description': 'Unknown type',
        'price': 10,
        'type': 'nonexistent_type',
        'icon': '❓',
      };

      final item = ShopItem.fromJson(json);
      expect(item.type, ShopItemType.other);
    });
  });
}
