import 'package:english_ai_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('English AI App', () {
    setUp(() {
      ErrorWidget.builder = (FlutterErrorDetails details) => ErrorWidget(details.exception);
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}
