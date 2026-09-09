import 'package:english_ai_app/screens/practice/practice_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PracticeHubScreen Sidebar', () {
    testWidgets('should render PracticeHubScreen without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PracticeHubScreen(),
        ),
      );

      expect(find.byType(PracticeHubScreen), findsOneWidget);
    });
  });
}
