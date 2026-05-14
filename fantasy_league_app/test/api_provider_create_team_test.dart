import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestWidgetsFlutterBinding.ensureInitialized()
      .defaultBinaryMessenger
      .setMockMethodCallHandler(storageChannel, (call) async => null);

  test(
      'createTeam uses /teams for teamId-only flows and /fantasy-teams for tournament flows',
      () async {
    bool calledTeams = false;
    bool calledFantasyTeams = false;

    ApiClient()
        .dio
        .interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) {
      final p = options.path;
      final method = options.method.toUpperCase();
      if (p.endsWith('/teams') && method == 'POST') {
        calledTeams = true;
        return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {'success': 1, 'message': 'ok'}));
      }
      if (p.endsWith('/fantasy-teams') && method == 'POST') {
        calledFantasyTeams = true;
        return handler.resolve(Response(
            requestOptions: options,
            statusCode: 201,
            data: {'success': 1, 'message': 'ok'}));
      }
      return handler.next(options);
    }));

    // Call createTeam with a teamId -> should hit /teams
    final resp1 = await ApiProvider().createTeam(
      name: 'Team A',
      playerIds: List.generate(11, (i) => (i + 1).toString()),
      captainId: '1',
      viceCaptainId: '2',
      teamId: '1',
    );

    expect(resp1['success'], 1);
    expect(calledTeams, isTrue);

    // Call createTeam with a tournamentId -> should hit /fantasy-teams
    final resp2 = await ApiProvider().createTeam(
      name: 'Team B',
      playerIds: List.generate(11, (i) => (i + 1).toString()),
      captainId: '1',
      viceCaptainId: '2',
      tournamentId: '5',
    );

    expect(resp2['success'], 1);
    expect(calledFantasyTeams, isTrue);
  });
}
