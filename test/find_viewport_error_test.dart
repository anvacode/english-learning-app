import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:english_ai_app/logic/auth_provider.dart';
import 'package:english_ai_app/logic/lesson_controller.dart';
import 'package:english_ai_app/logic/theme_provider.dart';
import 'package:english_ai_app/services/connectivity_service.dart';
import 'package:english_ai_app/screens/lessons_screen.dart';
import 'package:english_ai_app/screens/practice/practice_hub_screen.dart';
import 'package:english_ai_app/screens/settings_screen.dart';
import 'package:english_ai_app/screens/shop_screen.dart';
import 'package:english_ai_app/screens/achievements_screen.dart';
import 'package:english_ai_app/screens/profile/profile_screen.dart';
import 'package:english_ai_app/screens/purchased_items_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget wrapWithProviders(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => LessonController()),
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(value: ConnectivityService()),
    ],
    child: MaterialApp(
      home: Material(child: child),
    ),
  );
}

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Diagnose Viewport Crash', () {
    testWidgets('Test LessonsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const LessonsScreen()));
      await tester.pumpAndSettle();
      print('LessonsScreen passed!');
    });

    testWidgets('Test PracticeHubScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const PracticeHubScreen()));
      await tester.pumpAndSettle();
      print('PracticeHubScreen passed!');
    });

    testWidgets('Test SettingsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const SettingsScreen()));
      await tester.pumpAndSettle();
      print('SettingsScreen passed!');
    });

    testWidgets('Test ShopScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const ShopScreen()));
      await tester.pumpAndSettle();
      print('ShopScreen passed!');
    });

    testWidgets('Test AchievementsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const AchievementsScreen()));
      await tester.pumpAndSettle();
      print('AchievementsScreen passed!');
    });

    testWidgets('Test ProfileScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const ProfileScreen()));
      await tester.pumpAndSettle();
      print('ProfileScreen passed!');
    });

    testWidgets('Test PurchasedItemsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithProviders(const PurchasedItemsScreen()));
      await tester.pumpAndSettle();
      print('PurchasedItemsScreen passed!');
    });
  });
}
