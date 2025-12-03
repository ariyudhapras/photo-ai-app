import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photo_ai_app/main.dart';

void main() {
  testWidgets('Firebase initialization screen test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhotoAIApp());

    // Verify that the app title is displayed.
    expect(find.text('Photo AI'), findsOneWidget);

    // Verify that Firebase success message is displayed.
    expect(find.text('Firebase Initialized Successfully'), findsOneWidget);
    expect(find.text('Ready to build Photo AI features'), findsOneWidget);

    // Verify that the success icon is displayed.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
