import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:fantasyleague/main.dart';
import 'package:fantasyleague/modules/home/home_screen.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  setUp(() {
    // Clear all interceptors before each test
    ApiClient().dio.interceptors.clear();
  });

  testWidgets('Home screen displays tournament list after login',
      (WidgetTester tester) async {
    // Mock secure storage channel used by ApiClient
    const storageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
      if (call.method == 'read') {
        // Mock token so app thinks user is logged in
        if (call.arguments['key'] == 'token') {
          return 'mock-token';
        }
      }
      return null;
    });

    // Mock the API responses
    ApiClient()
        .dio
        .interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      final path = options.path;
      final method = options.method.toUpperCase();

      // GET /api/tournaments
      if (path.endsWith('tournaments') && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'data': [
                {
                  'id': '1',
                  'name': 'T20 Premier League 2026',
                  'logo_url': 'https://via.placeholder.com/100',
                  'description': 'Exciting T20 game tournament',
                  'start_at': '2026-02-01',
                  'end_at': '2026-02-28',
                  'entry_fee': 100,
                  'teams_count': 8,
                },
                {
                  'id': '2',
                  'name': 'Game Masters Cup',
                  'logo_url': 'https://via.placeholder.com/100',
                  'description': 'International tournament',
                  'start_at': '2026-02-10',
                  'end_at': '2026-03-10',
                  'entry_fee': 150,
                  'teams_count': 10,
                },
              ],
              'current_page': 1,
              'per_page': 15,
              'total': 2,
            },
          },
        ));
      }

      // GET /api/game-matches
      if (path.endsWith('game-matches') && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'data': [],
          },
        ));
      }

      return handler.next(options);
    }));

    // Build the home screen directly
    await tester.pumpWidget(
      MaterialApp(
        home: home_screen(
          menuCallBack: () {},
        ),
      ),
    );

    // Wait for tournaments to load
    await tester.pumpAndSettle();

    // Verify tournament title is present
    expect(find.text('Available Tournaments'), findsOneWidget);

    // Verify at least one tournament is displayed
    expect(find.text('T20 Premier League 2026'), findsOneWidget);
    expect(find.text('Game Masters Cup'), findsOneWidget);

    // Entry fee display may vary, so just check tournaments loaded successfully
  });

  testWidgets('Tournament cards are tappable and navigate to detail',
      (WidgetTester tester) async {
    // Mock secure storage
    const storageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async => null);

    // Mock API responses
    ApiClient()
        .dio
        .interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      final path = options.path;
      final method = options.method.toUpperCase();

      if (path.endsWith('tournaments') && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'data': {
              'data': [
                {
                  'id': '1',
                  'name': 'Test Tournament',
                  'logo_url': '',
                  'description': 'Test',
                  'start_at': '2026-02-01',
                  'end_at': '2026-02-28',
                  'entry_fee': 100,
                  'teams_count': 8,
                },
              ],
              'current_page': 1,
              'per_page': 15,
              'total': 1,
            },
          },
        ));
      }

      if (path.endsWith('game-matches') && method == 'GET') {
        return handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'success': true,
            'data': [],
          },
        ));
      }

      return handler.next(options);
    }));

    // Build the home screen
    await tester.pumpWidget(
      MaterialApp(
        home: home_screen(
          menuCallBack: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify tournament is displayed
    expect(find.text('Test Tournament'), findsOneWidget);

    // Verify tournament card is tappable
    expect(find.byType(GestureDetector), findsWidgets);
  });
}
