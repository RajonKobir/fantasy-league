import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/modules/tournament/tournament_players_screen.dart';

void main() {
  testWidgets('shows entry fee confirmation when creating a paid team',
      (WidgetTester tester) async {
    // Prepare the widget with two pre-selected players
    await tester.pumpWidget(MaterialApp(
      home: TournamentPlayersScreen(
        tournamentId: '1',
        tournamentName: 'Test Cup',
        teamId: '10',
        teamName: 'Team A',
        requiredPlayers: 2,
        entryFee: 25,
        initialSelectedPlayerIds: {'1', '2'},
        initialCaptainId: '1',
        initialViceCaptainId: '2',
        teamPlayers: [
          {'id': 1, 'name': 'Player 1', 'team': 'Team A', 'role': 'batsman'},
          {'id': 2, 'name': 'Player 2', 'team': 'Team A', 'role': 'bowler'},
        ],
      ),
    ));

    await tester.pump();

    // The button should be enabled and say Create Fantasy Team
    final createButton = find.text('Create Fantasy Team');
    expect(createButton, findsOneWidget);

    // Tap the create button
    await tester.tap(createButton);
    await tester.pump();

    // Name dialog should appear; enter a team name and continue
    expect(find.text('Create Team'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'My Test Team');
    await tester.tap(find.text('Continue'));
    // Allow dialog transitions and potential async fetches to settle
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Preview dialog should appear
    expect(find.text('Preview Team'), findsOneWidget);

    // Confirm preview
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now entry fee confirmation should be shown
    expect(find.text('Confirm Entry Fee'), findsOneWidget);
    expect(find.textContaining('৳25'), findsOneWidget);

    // Cancel the fee confirmation to abort
    await tester.tap(find.text('Cancel'));
    await tester.pump();

    // No progress indicator should be visible (creation should be aborted)
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
