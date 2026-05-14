import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/widgets/player_tile.dart';

void main() {
  testWidgets('PlayerTile calls callbacks and shows labels',
      (WidgetTester tester) async {
    bool tapped = false;
    bool captainSet = false;
    bool viceSet = false;

    final player = {
      'id': 1,
      'name': 'Test Player',
      'playing_role': 'batsman',
      'image_url': ''
    };

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayerTile(
          player: player,
          selected: false,
          onTap: () => tapped = true,
          onSelectCaptain: () => captainSet = true,
          onSelectViceCaptain: () => viceSet = true,
        ),
      ),
    ));

    // Tap to select (checkbox triggers onTap)
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);

    // Open popup menu and select 'Set as Captain'
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set as Captain').last);
    await tester.pumpAndSettle();
    expect(captainSet, isTrue);

    // Open popup menu and select 'Set as Vice Captain'
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Set as Vice Captain').last);
    await tester.pumpAndSettle();
    expect(viceSet, isTrue);
  });
}




