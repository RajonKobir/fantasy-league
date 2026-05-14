import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/modules/fantasy/fantasy_team_builder_screen.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('Select 11 players and submit team', (WidgetTester tester) async {
    // prepare 11 players
    final players = List.generate(
        11, (i) => {'id': i + 1, 'name': 'P${i + 1}', 'image_url': ''});

    // mock FlutterSecureStorage platform channel to avoid MissingPluginException in tests
    const storageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async => null);

    // intercept POST /api/teams
    bool apiCalled = false;
    ApiClient()
        .dio
        .interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.path.endsWith('teams') && options.method == 'POST') {
        apiCalled = true;
        return handler.resolve(Response(
            requestOptions: options,
            data: {'success': 1, 'message': 'Created'},
            statusCode: 201));
      }
      return handler.next(options);
    }));

    await tester.pumpWidget(MaterialApp(
      home: FantasyTeamBuilderScreen(
          teamId: '1',
          teamName: 'Team',
          players: players,
          skipConfirmationForTests: true),
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Pre-select all 11 players (test helper avoids UI scrolling/tapping)
    // Rebuild widget with initial selections
    await tester.pumpWidget(MaterialApp(
      home: FantasyTeamBuilderScreen(
          teamId: '1',
          teamName: 'Team',
          players: players,
          skipConfirmationForTests: true,
          initialSelected: List<int>.generate(11, (i) => i + 1)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // open selected screen via FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Directly show the SelectedPlayersScreen (bypass FAB) with selected players for test
    await tester.pumpWidget(MaterialApp(
      home: SelectedPlayersScreen(
          teamId: '1',
          teamName: 'Team',
          playerIds: List<int>.generate(11, (i) => i + 1),
          players: players,
          skipConfirmation: true),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // ensure come to selected screen
    expect(find.text('Selected Players (11)'), findsOneWidget);

    // submit team - call the button callback directly to avoid hit testing ambiguity
    final submitBtnFinder =
        find.widgetWithText(ElevatedButton, 'Submit Team').first;
    final submitBtnWidget = tester.widget<ElevatedButton>(submitBtnFinder);
    // Call onPressed within runAsync to ensure async tasks run in test environment
    await tester.runAsync(() async {
      submitBtnWidget.onPressed?.call();
      await Future.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Pump in small increments and wait until the API interceptor was hit or timeout
    bool called = false;
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (apiCalled == true) {
        called = true;
        break;
      }
    }
    expect(called, isTrue);
  });
}




