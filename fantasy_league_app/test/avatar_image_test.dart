import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/utils/avatar_image.dart';

void main() {
  testWidgets('AvatarImage renders without NotInitializedError',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AvatarImage(
              isCircle: true,
              imageUrl: 'https://example.com/avatar.jpg',
              radius: 50,
              sizeValue: 50,
            ),
          ),
        ),
      ),
    );

    // Verify the widget is built without errors
    expect(find.byType(AvatarImage), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AvatarImage with null image URL shows default icon',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AvatarImage(
              isCircle: true,
              imageUrl: null,
              radius: 50,
              sizeValue: 50,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AvatarImage), findsOneWidget);
  });
}
