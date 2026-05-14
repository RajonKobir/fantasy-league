import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  group('Tournament API Tests', () {
    setUp(() {
      // Mock the API responses
      ApiClient().dio.interceptors.clear();
    });

    test('getTournaments should handle paginated response', () async {
      // Setup paginated mock response (like the actual API returns)
      ApiClient()
          .dio
          .interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path.endsWith('tournaments')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'data': [
                  {
                    'id': 1,
                    'name': 'T20 Premier League 2026',
                    'logo_url': 'https://example.com/logo.jpg',
                    'description': 'Test tournament',
                    'start_at': '2026-02-01',
                    'end_at': '2026-02-28',
                    'entry_fee': '100.00',
                    'teams_count': 8,
                  },
                  {
                    'id': 2,
                    'name': 'Game Masters Cup',
                    'logo_url': 'https://example.com/logo2.jpg',
                    'description': 'Test tournament 2',
                    'start_at': '2026-02-10',
                    'end_at': '2026-03-10',
                    'entry_fee': '150.00',
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
        return handler.next(options);
      }));

      final apiProvider = ApiProvider();
      final tournaments = await apiProvider.getTournaments();

      expect(tournaments, isNotEmpty);
      expect(tournaments.length, equals(2));
      expect(tournaments[0]['name'], equals('T20 Premier League 2026'));
      expect(tournaments[1]['name'], equals('Game Masters Cup'));
      expect(tournaments[0]['entry_fee'], equals('100.00'));
    });

    test('getTournaments should handle non-paginated response', () async {
      // Setup non-paginated mock response
      ApiClient()
          .dio
          .interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path.endsWith('tournaments')) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'success': true,
              'data': [
                {
                  'id': 1,
                  'name': 'Test Tournament',
                  'logo_url': '',
                  'description': 'Test',
                  'start_at': '2026-02-01',
                  'end_at': '2026-02-28',
                  'entry_fee': '100',
                  'teams_count': 5,
                },
              ],
            },
          ));
        }
        return handler.next(options);
      }));

      final apiProvider = ApiProvider();
      final tournaments = await apiProvider.getTournaments();

      expect(tournaments, isNotEmpty);
      expect(tournaments.length, equals(1));
      expect(tournaments[0]['name'], equals('Test Tournament'));
    });

    test('getTournaments should return empty list on error', () async {
      ApiClient()
          .dio
          .interceptors
          .add(InterceptorsWrapper(onRequest: (options, handler) {
        if (options.path.endsWith('tournaments')) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Network error',
          ));
        }
        return handler.next(options);
      }));

      final apiProvider = ApiProvider();
      final tournaments = await apiProvider.getTournaments();

      expect(tournaments, isEmpty);
    });
  });
}
