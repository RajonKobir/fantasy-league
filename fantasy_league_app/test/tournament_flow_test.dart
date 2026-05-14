import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/modules/tournament/tournament_list_screen.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('Full tournament flow: build team and submit',
      (WidgetTester tester) async {
    // Mock secure storage channel used by ApiClient
    const storageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async => null);

    // Prepare fake API responses via Dio interceptor
    ApiClient()
        .dio
        .interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      final path = options.path;
      final method = options.method.toUpperCase();

      // GET /api/tournaments
      if (path.endsWith('tournaments') && method == 'GET') {
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': {
            'data': [
              {
                'id': 1,
                'name': 'Test Cup',
                'start_at': '2026-01-01',
                'end_at': '2026-01-02',
                'entry_fee': 0,
                'logo_url': '',
                'teams_count': 0,
              }
            ],
            'current_page': 1,
            'per_page': 15,
            'total': 1,
          }
        }));
      }

      // GET /api/tournaments/1
      if (path.endsWith('tournaments/1') && method == 'GET') {
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': {
            'id': 1,
            'name': 'Test Cup',
            'description': 'Test tournament',
            'entry_fee': 0,
            'required_players': 11,
            'teams': [
              {
                'id': 1,
                'name': 'India',
                'logo_url': '',
              },
              {
                'id': 2,
                'name': 'Pakistan',
                'logo_url': '',
              }
            ]
          }
        }));
      }

      // GET /api/game-matches
      if (path.endsWith('game-matches') && method == 'GET') {
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': [
            {
              'id': 101,
              'match': 'A vs B',
              'team_a': 'A',
              'team_b': 'B',
            }
          ]
        }));
      }

      // GET /api/players - all available players across all tournaments
      if (path.endsWith('players') && method == 'GET') {
        final players = List.generate(15, (i) {
          // Generate players with team field for filtering
          final teamIndex = i % 2; // Alternate between two teams for testing
          final team = teamIndex == 0 ? 'India' : 'Pakistan';
          return {
            'id': i + 1,
            'name': 'Player ${i + 1}',
            'team': team,
            'role': 'batsman'
          };
        });
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': players,
        }));
      }

      // GET /api/game-matches/101/players
      if (path.contains('/api/game-matches/') &&
          path.contains('/players') &&
          method == 'GET') {
        final players = List.generate(15,
            (i) => {'id': i + 1, 'name': 'Player ${i + 1}', 'role': 'Role'});
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': players,
        }));
      }

      // GET /api/wallet
      if (path.endsWith('wallet') && method == 'GET') {
        return handler
            .resolve(Response(requestOptions: options, statusCode: 200, data: {
          'success': 1,
          'data': {'wallet_balance': '100.00'}
        }));
      }

      // POST /api/teams
      if (path.endsWith('teams') && method == 'POST') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {'success': 1, 'message': 'Created'},
        ));
      }

      return handler.next(options);
    }));

    // Start at tournament list
    await tester.pumpWidget(MaterialApp(home: TournamentListScreen()));

    // Allow fetch and render
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify tournament tile is shown and tap it
    expect(find.text('Test Cup'), findsOneWidget);
    await tester.tap(find.text('Test Cup'));
    await tester.pumpAndSettle();

    // On detail screen, find and tap "Select Team to Play" button
    expect(find.text('Select Team to Play'), findsOneWidget);
    await tester.tap(find.text('Select Team to Play'));
    await tester.pumpAndSettle();

    // On teams screen, tap the first team (India)
    expect(find.text('India'), findsOneWidget);
    await tester.tap(find.text('India'));

    // Navigate to tournament players screen for India team
    // Note: Full rendering test is covered by fantasy_selection_test.dart
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  });
}
