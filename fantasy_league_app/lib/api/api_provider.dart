import 'dart:async';
import 'dart:convert';
import 'package:fantasyleague/api/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fantasyleague/models/drawer_info_responce_data.dart';
import 'package:fantasyleague/models/notification.dart';
import 'package:fantasyleague/models/schedule_response_data.dart';
import 'package:fantasyleague/models/team_response_data.dart';
import 'package:fantasyleague/models/transaction_response.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiProvider {
  // Simple in-memory caches to reduce repeated backend calls from many clients.
  // These caches are process-local and reset when the app restarts.
  static List<Map<String, dynamic>>? _tournamentsCache;
  static DateTime? _tournamentsCacheAt;
  static const Duration _tournamentsCacheTTL = Duration(minutes: 5);

  static List<Map<String, dynamic>>? _playersCache;
  static DateTime? _playersCacheAt;
  static const Duration _playersCacheTTL = Duration(seconds: 60);

  Future<ScheduleResponseData> postScheduleList() async {
    try {
      // Request paginated matches and use conditional GET via ETag
      final resp = await ApiClient().getWithEtag('/game-matches',
          queryParameters: {'per_page': 50, 'page': 1});
      List<dynamic> matches = [];
      if (resp.statusCode == 200) {
        matches = resp.data['data'] ?? [];
        // Persist cached payload for fallback if server returns 304 later
        try {
          final prefs = await SharedPreferences.getInstance();
          final uri = Uri(
              path: '/game-matches',
              queryParameters: {'per_page': '50', 'page': '1'}).toString();
          await prefs.setString('cache:$uri', jsonEncode(resp.data));
        } catch (_) {}
      } else if (resp.statusCode == 304) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final uri = Uri(
              path: '/game-matches',
              queryParameters: {'per_page': '50', 'page': '1'}).toString();
          final cached = prefs.getString('cache:$uri');
          if (cached != null) {
            final decoded = jsonDecode(cached);
            matches = decoded['data'] ?? [];
          }
        } catch (_) {}
      }
      if (matches.isNotEmpty) {
        final shedual = matches.map((m) {
          final id = m['id'];
          final teamA = m['team_a'] ?? '';
          final teamB = m['team_b'] ?? '';
          final start = m['start_time'] ?? '';
          String dateStart = '';
          String timeStart = '';
          if (start != null && start is String && start.isNotEmpty) {
            final parts = start.split(' ');
            if (parts.length >= 2) {
              dateStart = parts[0];
              timeStart = parts[1];
            } else {
              dateStart = start;
            }
          }
          return {
            'match_id': id,
            'match': '$teamA vs $teamB',
            'date_start': dateStart,
            'time_start': timeStart,
            'lineups_out': '',
            'pre_squad': '',
          };
        }).toList();

        return ScheduleResponseData.fromJson({
          'success': 1,
          'message': 'Data fetched successfully',
          'shedual_data': shedual
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching schedule from backend: $e');
    }

    // fallback: return empty schedule
    return ScheduleResponseData.fromJson(
        {'success': 0, 'message': 'Failed to fetch', 'shedual_data': []});
  }

  Future<List<Map<String, dynamic>>> getMatches() async {
    try {
      // Delegate to getMatchesPage for consistency
      final result = await getMatchesPage(page: 1, perPage: 50);
      final data = result['data'] as List? ?? [];

      if (kDebugMode) {
        debugPrint('[getMatches] Got ${data.length} matches');
      }

      return data.map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[getMatches] Error: $e');
      return [];
    }
  }

  /// Fetch paginated matches (schedule)
  Future<Map<String, dynamic>> getMatchesPage(
      {int page = 1, int perPage = 50}) async {
    try {
      final cacheKey = 'matches_page_${page}_${perPage}';
      final prefs = await SharedPreferences.getInstance();

      final resp = await ApiClient().getWithEtag('/game-matches',
          queryParameters: {
            'page': page.toString(),
            'per_page': perPage.toString()
          });

      List<dynamic> data = [];
      Map<String, dynamic> meta = {};

      if (resp.statusCode == 200) {
        // Fresh data - extract and cache
        final payload = resp.data?['data'] ?? resp.data;

        if (payload is Map && payload.containsKey('data')) {
          data = payload['data'] ?? [];
          meta = Map<String, dynamic>.from(payload);
        } else if (payload is List) {
          data = payload;
          meta = {
            'data': data,
            'current_page': page,
            'last_page': page,
            'total': data.length
          };
        }

        try {
          await prefs.setString(cacheKey, jsonEncode(meta));
        } catch (_) {}

        if (kDebugMode)
          debugPrint(
              '[getMatchesPage] Fetched page $page: ${data.length} matches (200)');
      } else if (resp.statusCode == 304) {
        // Retrieve from cache
        try {
          final cached = prefs.getString(cacheKey);
          if (cached != null) {
            meta = jsonDecode(cached);
            data = meta['data'] ?? [];
            if (kDebugMode)
              debugPrint(
                  '[getMatchesPage] Retrieved page $page: ${data.length} matches from cache (304)');
          }
        } catch (e) {
          if (kDebugMode)
            debugPrint('[getMatchesPage] Cache error page $page: $e');
        }
      }

      meta['data'] = data;
      return meta;
    } catch (e) {
      if (kDebugMode)
        debugPrint('[getMatchesPage] Error fetching matches page $page: $e');
      return {};
    }
  }

  /// Submit a payment request to admin (user endpoint)
  Future<Map<String, dynamic>?> submitPaymentRequest({
    required String paymentMethod,
    required String toNumber,
    required String fromNumber,
    required double amount,
    required String transactionNumber,
  }) async {
    try {
      final resp = await ApiClient().post('/payment-requests', data: {
        'payment_method': paymentMethod,
        'to_number': toNumber,
        'from_number': fromNumber,
        'amount': amount,
        'transaction_number': transactionNumber,
      });
      if (kDebugMode)
        debugPrint(
            'submitPaymentRequest response: ${resp.statusCode} ${resp.data}');
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return resp.data as Map<String, dynamic>?;
      }
      return resp.data as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) debugPrint('Error submitting payment request: $e');
      rethrow;
    }
  }

  /// Fetch public tournaments list
  Future<List<Map<String, dynamic>>> getTournaments() async {
    // Return cached value if still fresh
    try {
      if (_tournamentsCache != null && _tournamentsCacheAt != null) {
        final age = DateTime.now().difference(_tournamentsCacheAt!);
        if (age <= _tournamentsCacheTTL) {
          if (kDebugMode)
            debugPrint('Using cached tournaments (${age.inSeconds}s old)');
          return _tournamentsCache!;
        }
      }
    } catch (_) {}
    try {
      final resp = await ApiClient().get('/tournaments');
      if (kDebugMode) {
        debugPrint('Tournaments API Response - Status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200 && resp.data != null) {
        // Handle paginated response from Laravel: { success: true, data: { data: [...], ... } }
        dynamic responseData = resp.data['data'];
        final List<dynamic> data;

        if (responseData is List) {
          // Direct array response
          data = responseData;
        } else if (responseData is Map && responseData['data'] != null) {
          // Paginated response (Laravel pagination object) - extract the inner 'data' array
          data = responseData['data'] as List<dynamic>? ?? [];
        } else if (responseData == null) {
          if (kDebugMode) debugPrint('Warning: resp.data["data"] is null');
          data = [];
        } else {
          if (kDebugMode)
            debugPrint(
                'Warning: Unexpected response data type: ${responseData.runtimeType}');
          data = [];
        }

        // persist cache
        final result = data.map((t) {
          final Map<String, dynamic> tt = Map<String, dynamic>.from(t ?? {});
          return {
            'id': tt['id']?.toString() ?? '',
            'name': tt['name'] ?? '',
            'logo_url': tt['logo_url'] ?? tt['logo'] ?? '',
            'description': tt['description'] ?? '',
            'start_at': tt['start_at'] ?? '',
            'end_at': tt['end_at'] ?? '',
            'teams_count': tt['teams_count'] ?? 0,
            'entry_fee': tt['entry_fee'] ?? tt['entryFee'] ?? 0
          };
        }).toList();
        _tournamentsCache = result;
        _tournamentsCacheAt = DateTime.now();
        return result;
      } else {
        if (kDebugMode)
          debugPrint('Tournaments API failed - Status: ${resp.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching tournaments from backend: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    return [];
  }

  // Admin operations (create/update/delete tournaments) are handled by the Laravel admin panel.
  // The mobile app only reads tournaments (getTournaments/getTournamentDetails).

  /// Fetch payment methods available for payment requests
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final resp = await ApiClient().get('/payment-methods');
      if (kDebugMode) {
        debugPrint('Payment Methods API Response - Status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final List<dynamic> data = resp.data['data'] as List<dynamic>? ?? [];
        return data.map((m) {
          final Map<String, dynamic> mm = Map<String, dynamic>.from(m ?? {});
          return {
            'id': mm['id']?.toString() ?? '',
            'name': mm['name'] ?? '',
            'code': mm['code'] ?? '',
            'description': mm['description'] ?? '',
          };
        }).toList();
      } else {
        if (kDebugMode)
          debugPrint('Payment Methods API failed - Status: ${resp.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching payment methods from backend: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    return [];
  }

  /// Fetch countries list from backend
  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final resp = await ApiClient().get('/countries');
      if (kDebugMode) {
        debugPrint('Countries API Response - Status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final List<dynamic> data = resp.data['data'] as List<dynamic>? ?? [];
        return data.map((c) {
          final Map<String, dynamic> cc = Map<String, dynamic>.from(c ?? {});
          return {
            'id': cc['id']?.toString() ?? '',
            'name': cc['name'] ?? '',
            'code': cc['code'] ?? '',
          };
        }).toList();
      } else {
        if (kDebugMode)
          debugPrint('Countries API failed - Status: ${resp.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching countries from backend: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    return [];
  }

  /// Fetch cities list from backend; optional filter by country_id
  Future<List<Map<String, dynamic>>> getCities({int? countryId}) async {
    try {
      final query = (countryId != null) ? '?country_id=$countryId' : '';
      final resp = await ApiClient().get('/cities$query');
      if (kDebugMode) {
        debugPrint('Cities API Response - Status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final List<dynamic> data = resp.data['data'] as List<dynamic>? ?? [];
        return data.map((c) {
          final Map<String, dynamic> cc = Map<String, dynamic>.from(c ?? {});
          return {
            'id': cc['id']?.toString() ?? '',
            'name': cc['name'] ?? '',
            'country_id': cc['country_id']?.toString() ?? '',
          };
        }).toList();
      } else {
        if (kDebugMode)
          debugPrint('Cities API failed - Status: ${resp.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error fetching cities from backend: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
    return [];
  }

  /// Fetch a tournament details with teams and players
  Future<Map<String, dynamic>?> getTournamentDetails(
      String tournamentId) async {
    if (kDebugMode)
      debugPrint('[API] getTournamentDetails START - ID: $tournamentId');
    try {
      final resp = await ApiClient().get('/tournaments/$tournamentId');
      if (kDebugMode) {
        debugPrint(
            '[API] Tournament Details API Response - Status: ${resp.statusCode}');
      }

      if (resp.statusCode == 200 && resp.data != null) {
        final Map<String, dynamic> raw =
            Map<String, dynamic>.from(resp.data['data'] ?? resp.data ?? {});
        // Normalize tournament
        final normalized = Map<String, dynamic>.from(raw);
        // Ensure teams array is present and normalized
        final teams = <Map<String, dynamic>>[];
        if (raw['teams'] != null && raw['teams'] is List) {
          for (var t in raw['teams']) {
            final team = Map<String, dynamic>.from(t ?? {});
            // selections -> players mapping
            final players = <Map<String, dynamic>>[];
            if (team['selections'] != null && team['selections'] is List) {
              for (var s in team['selections']) {
                final sel = Map<String, dynamic>.from(s ?? {});
                final player = Map<String, dynamic>.from(sel['player'] ?? {});
                players.add({
                  'id':
                      (player['id'] ?? player['pid'] ?? sel['player_id'] ?? '')
                          .toString(),
                  'name': player['name'] ?? player['full_name'] ?? '',
                  'role': player['role'] ?? player['playing_role'] ?? '',
                  'captain': (sel['captain'] == true || sel['captain'] == 1),
                  'vice_captain':
                      (sel['vice_captain'] == true || sel['vice_captain'] == 1),
                  'image_url': player['image_url'] ?? player['image'] ?? ''
                });
              }
            }
            teams.add({
              'id': (team['id'] ?? team['team_id'] ?? '').toString(),
              'name': team['name'] ?? team['team_name'] ?? '',
              'logo_url': team['logo_url'] ?? team['logo'] ?? '',
              'players': players
            });
          }
        }
        normalized['teams'] = teams;
        // include entry_fee if provided by backend
        normalized['entry_fee'] = raw['entry_fee'] ?? raw['entryFee'] ?? 0;
        // include required_players (number of players needed for fantasy team)
        // DO NOT default to 11: use admin-configured tournament value only
        normalized['required_players'] = raw['required_players'] ??
            raw['requiredPlayers'] ??
            raw['variable_players'];
        if (kDebugMode)
          debugPrint(
              '[API] getTournamentDetails returning normalized with ${normalized.keys.length} keys');
        return normalized;
      } else {
        if (kDebugMode)
          debugPrint(
              '[API] Tournament Details API failed - Status: ${resp.statusCode}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[API] Error fetching tournament details from backend: $e');
        debugPrint('[API] Stack trace: $stackTrace');
      }
    }

    if (kDebugMode) debugPrint('[API] getTournamentDetails returning null');
    return null;
  }

  Future<List<Map<String, dynamic>>> getPlayers([
    String cid = '',
    String matchId = '',
  ]) async {
    // Fetch players from the Laravel backend.
    // If cid and matchId are provided, fetch by match (legacy)
    // Otherwise, fetch all available players
    final List<Map<String, dynamic>> players = [];
    try {
      // Only use cached players when no filter params are provided.
      if (cid.isEmpty && matchId.isEmpty) {
        if (_playersCache != null && _playersCacheAt != null) {
          final age = DateTime.now().difference(_playersCacheAt!);
          if (age <= _playersCacheTTL) {
            if (kDebugMode)
              debugPrint('Using cached players (${age.inSeconds}s old)');
            return _playersCache!;
          }
        }
      }
      if (matchId.isNotEmpty && cid.isNotEmpty) {
        // Legacy: Fetch players by match (explicit, not cached globally)
        final resp = await ApiClient().getWithEtag(
            '/game-matches/$matchId/players',
            queryParameters: {'per_page': 50, 'page': 1});
        List<dynamic> data = [];
        if (resp.statusCode == 200) {
          data = resp.data['data'] ?? [];
        } else if (resp.statusCode == 304) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final uri = Uri(
                path: '/game-matches/$matchId/players',
                queryParameters: {'per_page': '50', 'page': '1'}).toString();
            final cached = prefs.getString('cache:$uri');
            if (cached != null) {
              final decoded = jsonDecode(cached);
              data = decoded['data'] ?? [];
            }
          } catch (_) {}
        }
        for (var p in data) {
          players.add(Map<String, dynamic>.from(p));
        }
      } else {
        // New: Fetch all available players in paginated form. Clients should page through
        // results rather than requesting unbounded lists. We request page 1 by default.
        final resp = await ApiClient().getWithEtag('/players',
            queryParameters: {'per_page': 100, 'page': 1});
        List<dynamic> data = [];
        final prefs = await SharedPreferences.getInstance();
        final uri = Uri(
            path: '/players',
            queryParameters: {'per_page': '100', 'page': '1'}).toString();
        if (resp.statusCode == 200) {
          dynamic responseData = resp.data['data'];
          if (responseData is Map) {
            data = responseData['data'] ?? [];
          } else if (responseData is List) {
            data = responseData;
          }
          try {
            await prefs.setString('cache:$uri', jsonEncode(resp.data));
          } catch (_) {}
        } else if (resp.statusCode == 304) {
          try {
            final cached = prefs.getString('cache:$uri');
            if (cached != null) {
              final decoded = jsonDecode(cached);
              final responseData = decoded['data'];
              if (responseData is List)
                data = responseData;
              else if (responseData is Map) data = responseData['data'] ?? [];
            }
          } catch (_) {}
        }

        for (var p in data) {
          players.add(Map<String, dynamic>.from(p));
        }
        if (cid.isEmpty && matchId.isEmpty) {
          _playersCache = players;
          _playersCacheAt = DateTime.now();
        }
        if (kDebugMode) {
          debugPrint('API getPlayers: Fetched ${players.length} players');
        }
        if (kDebugMode && players.isNotEmpty) {
          debugPrint(
              'API getPlayers: Sample: ${players.take(3).map((p) => '${p['name']}(team=${p['team']})').join(', ')}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching players from backend: $e');
    }
    return players;
  }

// Team data helper removed to avoid embedding third-party API tokens in the repo.

  Future<GetTeamResponseData> getCreatedTeamList(String matchId) async {
    try {
      final resp = await ApiClient().getWithEtag('/teams',
          queryParameters: {'match_id': matchId, 'per_page': 50, 'page': 1});
      List<dynamic> raw = [];
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri(path: '/teams', queryParameters: {
        'match_id': matchId,
        'per_page': '50',
        'page': '1'
      }).toString();
      if (resp.statusCode == 200) {
        raw = resp.data['data'] ?? [];
        try {
          await prefs.setString('cache:$uri', jsonEncode(resp.data));
        } catch (_) {}
      } else if (resp.statusCode == 304) {
        try {
          final cached = prefs.getString('cache:$uri');
          if (cached != null) {
            final decoded = jsonDecode(cached);
            raw = decoded['data'] ?? [];
          }
        } catch (_) {}
      }
      if (raw.isNotEmpty) {
        // Normalize backend team objects into the legacy shape expected by TeamData
        final mapped = raw.map((m) {
          final Map<String, dynamic> t = Map<String, dynamic>.from(m ?? {});
          return {
            'team_id': (t['id'] ?? t['team_id'] ?? '').toString(),
            'team_name': t['name'] ?? t['team_name'] ?? '',
            'logo_url': t['logo_url'] ?? t['logo'] ?? '',
            'captun': t['captain_name'] ?? '',
            'wise_captun': t['vice_captain_name'] ?? '',
            'wicket_keeper': '',
            'bowler': '',
            'bastman': '',
            'all_rounder': '',
            'user_id': (t['user_id'] ?? '').toString(),
            'created_time': t['created_at'] ?? t['created_time'] ?? '',
            'updated_time': t['updated_at'] ?? t['updated_time'] ?? '',
            'is_delete': t['is_delete'] ?? '0',
            'match_key': (t['game_match_id'] ??
                    (t['game_match'] != null
                        ? (t['game_match']['id'] ?? '')
                        : ''))
                .toString(),
            'competition_id': t['competition_id'] ?? '',
            'points': t['points'] ?? 0
          };
        }).toList();

        return GetTeamResponseData.fromJson(
            {'team_data': mapped, 'success': 1, 'message': ''});
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching created teams: $e');
    }

    // fallback to empty
    return GetTeamResponseData.fromJson(
        {'team_data': [], 'success': 0, 'message': 'Failed to fetch'});
  }

  /// Create a fantasy team for a match.
  /// POST /api/teams expected payload: { name, game_match_id, player_ids, captain_id, vice_captain_id }
  Future<Map<String, dynamic>> createTeam({
    required String name,
    required List<String> playerIds,
    required String captainId,
    required String viceCaptainId,
    String? tournamentId,
    String? teamId,
    String? matchId,
  }) async {
    try {
      // Convert string IDs to integers
      final intCaptainId = int.tryParse(captainId) ?? 0;
      final intViceCaptainId = int.tryParse(viceCaptainId) ?? 0;
      final intPlayerIds = playerIds
          .map((id) => int.tryParse(id) ?? 0)
          .where((id) => id > 0)
          .toList();

      final data = {
        'name': name,
        'player_ids': intPlayerIds,
        'captain_id': intCaptainId,
        'vice_captain_id': intViceCaptainId,
      };

      // Support both new (tournament/team) and legacy (match) flows
      if (tournamentId != null && tournamentId.isNotEmpty) {
        data['tournament_id'] = int.tryParse(tournamentId) ?? 0;
      }
      if (teamId != null && teamId.isNotEmpty) {
        data['team_id'] = int.tryParse(teamId) ?? 0;
      }
      // If matchId is provided, send it as game_match_id (legacy match flow).
      if (matchId != null && matchId.isNotEmpty) {
        final parsedMatchId = int.tryParse(matchId) ?? 0;
        if (parsedMatchId > 0) {
          data['game_match_id'] = parsedMatchId;
        }
      }

      // Choose endpoint: use legacy '/teams' when creating from a Team context (no tournament),
      // otherwise call '/fantasy-teams' for tournament-based create flow.
      String endpoint = '/fantasy-teams';
      if ((teamId != null && teamId.isNotEmpty) &&
          (tournamentId == null || tournamentId.isEmpty)) {
        endpoint = '/teams';
      }

      if (kDebugMode) {
        debugPrint('[createTeam] POST $endpoint');
        debugPrint('[createTeam] Payload: ${jsonEncode(data)}');
      }
      final response = await ApiClient().post(endpoint, data: data);
      if (kDebugMode) {
        debugPrint('[createTeam] Response: ${response.data}');
      }
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'success': false, 'message': 'Unexpected server response'};
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('DioException creating team: $e');
      // Extract error message and details from response if available
      if (e.response != null && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        final message = responseData['message'] ?? 'Failed to create team';
        final errors = responseData['errors'];
        final trace = responseData['trace'];
        final error = responseData['error'];
        final result = {
          'success': false,
          'message': message,
        };
        if (errors != null) result['errors'] = errors;
        if (error != null) result['error'] = error;
        if (trace != null) result['trace'] = trace;
        return result;
      }
      // Fallback to status code-based messages
      if (e.response?.statusCode == 402) {
        return {'success': false, 'message': 'Insufficient wallet balance'};
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to create team'
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error creating team: $e');
      return {'success': false, 'message': 'Failed to create team'};
    }
  }

  /// Get teams created by the current authenticated user
  Future<List<Map<String, dynamic>>> getMyTeams() async {
    // Default helper: fetch first page and return items only
    final pageResp = await getMyTeamsPage(page: 1);
    if (pageResp.isNotEmpty && pageResp['data'] is List) {
      return List<Map<String, dynamic>>.from(
          pageResp['data'].map((m) => Map<String, dynamic>.from(m)));
    }
    return [];
  }

  /// Fetch paginated my teams. Returns a map containing pagination metadata
  /// matching Laravel's paginator: { data: [...], current_page, last_page, total }
  Future<Map<String, dynamic>> getMyTeamsPage(
      {int page = 1, int perPage = 20}) async {
    try {
      final resp = await ApiClient().getWithEtag('/fantasy-teams',
          queryParameters: {'page': page, 'per_page': perPage});
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri(path: '/fantasy-teams', queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString()
      }).toString();
      List<dynamic> data = [];
      Map<String, dynamic> pagination = {};
      if (resp.statusCode == 200) {
        final payload = resp.data['data'] ?? resp.data;
        if (payload is Map && payload.containsKey('data')) {
          data = payload['data'] ?? [];
          pagination = Map<String, dynamic>.from(payload);
        } else if (payload is List) {
          data = payload;
          pagination = {
            'data': data,
            'current_page': page,
            'last_page': page,
            'total': data.length
          };
        }
        try {
          await prefs.setString('cache:$uri', jsonEncode(resp.data));
        } catch (_) {}
      } else if (resp.statusCode == 304) {
        try {
          final cached = prefs.getString('cache:$uri');
          if (cached != null) {
            final decoded = jsonDecode(cached);
            final payload = decoded['data'] ?? decoded;
            if (payload is Map && payload.containsKey('data')) {
              data = payload['data'] ?? [];
              pagination = Map<String, dynamic>.from(payload);
            } else if (payload is List) {
              data = payload;
              pagination = {
                'data': data,
                'current_page': page,
                'last_page': page,
                'total': data.length
              };
            }
          }
        } catch (_) {}
      }
      final result = Map<String, dynamic>.from(pagination);
      result['data'] = data;
      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching my teams page: $e');
    }
    return {};
  }

  /// Fetch a single fantasy team with full details including players
  Future<Map<String, dynamic>> getFantasyTeam(String teamId) async {
    try {
      debugPrint('[getFantasyTeam] Fetching team: $teamId');
      final resp = await ApiClient().get('/fantasy-teams/$teamId');
      debugPrint(
          '[getFantasyTeam] Status: ${resp.statusCode}, Response: ${resp.data}');
      if (resp.statusCode == 200) {
        final data = resp.data['data'] ?? resp.data;
        if (data is Map<String, dynamic>) {
          debugPrint(
              '[getFantasyTeam] Got team with ${(data['players'] as List?)?.length ?? 0} players');
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('[getFantasyTeam] Error fetching team: $e');
    }
    return {};
  }

  /// Fetch player selections for a given team
  Future<List<Map<String, dynamic>>> getTeamSelections(String teamId) async {
    try {
      debugPrint('[getTeamSelections] Fetching selections for team: $teamId');
      final resp = await ApiClient().get('/teams/$teamId/selections');
      debugPrint(
          '[getTeamSelections] Status: ${resp.statusCode}, Response: ${resp.data}');
      if (resp.statusCode == 200) {
        final List<dynamic> data = resp.data['selections'] ?? resp.data ?? [];
        debugPrint('[getTeamSelections] Got ${data.length} selections');
        return data.map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (e) {
      debugPrint('[getTeamSelections] Error fetching team selections: $e');
    }
    return [];
  }

  /// Add a player selection to a team
  Future<Map<String, dynamic>?> addTeamSelection(String teamId, int playerId,
      {bool captain = false, bool vice = false}) async {
    try {
      final resp = await ApiClient().post('/teams/$teamId/selections', data: {
        'player_id': playerId,
        'captain': captain ? 1 : 0,
        'vice_captain': vice ? 1 : 0
      });
      if (resp.statusCode == 201) {
        return Map<String, dynamic>.from(resp.data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error adding team selection: $e');
      rethrow;
    }
    return null;
  }

  /// Update a team's metadata (name, logo)
  Future<Map<String, dynamic>?> updateTeam(String teamId,
      {String? name,
      File? logoFile,
      void Function(int, int)? onSendProgress}) async {
    try {
      final formData = FormData();
      if (name != null) formData.fields.add(MapEntry('name', name));
      if (logoFile != null) {
        final multipartFile = await MultipartFile.fromFile(logoFile.path,
            filename: logoFile.path.split(Platform.pathSeparator).last);
        formData.files.add(MapEntry('logo', multipartFile));
      }

      final resp = await ApiClient().dio.put('/teams/$teamId',
          data: formData, onSendProgress: onSendProgress);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final d = resp.data['data'] ?? resp.data ?? {};
        return Map<String, dynamic>.from(d);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating team: $e');
      rethrow;
    }
    return null;
  }

  /// Delete a team (owner or admin)
  Future<bool> deleteTeam(String teamId) async {
    try {
      final resp = await ApiClient().delete('/teams/$teamId');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting team: $e');
    }
    return false;
  }

  /// Update a player selection (captain/vice)
  Future<Map<String, dynamic>?> updateTeamSelection(
      String teamId, String selectionId,
      {bool? captain, bool? vice}) async {
    try {
      final data = <String, dynamic>{};
      if (captain != null) data['captain'] = captain ? 1 : 0;
      if (vice != null) data['vice_captain'] = vice ? 1 : 0;
      final resp = await ApiClient()
          .put('/teams/$teamId/selections/$selectionId', data: data);
      if (resp.statusCode == 200) {
        return Map<String, dynamic>.from(resp.data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating team selection: $e');
      rethrow;
    }
    return null;
  }

  /// Remove a player from a team (selection)
  Future<bool> removeTeamSelection(String teamId, String selectionId) async {
    try {
      final resp =
          await ApiClient().delete('/teams/$teamId/selections/$selectionId');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      if (kDebugMode) debugPrint('Error removing team selection: $e');
    }
    return false;
  }

  /// Abandon a team by removing all selections
  Future<bool> abandonTeam(String teamId) async {
    try {
      final selections = await getTeamSelections(teamId);
      for (var s in selections) {
        final id = s['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          await removeTeamSelection(teamId, id);
        }
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('Error abandoning team: $e');
    }
    return false;
  }

  /// Fetch current user's wallet (balance + transactions)
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final resp = await ApiClient().get('/wallet');
      if (resp.statusCode == 200) {
        final data = resp.data['data'] ?? resp.data ?? {};
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching wallet: $e');
    }
    return {'wallet_balance': 0.0, 'transactions': []};
  }

  /// Fetch current user's payment requests with pagination
  /// Returns the full paginated response including metadata
  Future<Map<String, dynamic>> getPaymentRequests({int page = 1}) async {
    try {
      final resp = await ApiClient().get('/payment-requests?page=$page');
      if (resp.statusCode == 200) {
        final data = resp.data['data'];
        // The API returns { success: true, data: {...paginated response...} }
        // Extract and return the full paginated response with all metadata
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching payment requests: $e');
    }
    return {};
  }

  /// Update current user's profile (supports avatar upload)
  /// Returns a map with the server response on success, or throws DioException on network errors.
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? dob,
    String? gender,
    String? state,
    String? city,
    String? referral,
    String? email,
    File? avatarFile,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
            '[API] updateProfile START - name=$name, email=$email, hasAvatar=${avatarFile != null}');
      }

      final formData = FormData();

      if (name != null) {
        formData.fields.add(MapEntry('name', name));
        // Also send first_name / last_name split to support backends expecting them
        try {
          final parts = name.trim().split(RegExp(r'\s+'));
          if (parts.length > 1) {
            formData.fields.add(MapEntry('first_name', parts.first));
            formData.fields
                .add(MapEntry('last_name', parts.sublist(1).join(' ')));
          } else {
            formData.fields.add(MapEntry('first_name', name.trim()));
          }
        } catch (_) {}
        if (kDebugMode) debugPrint('[API] Added field: name=$name');
      }
      if (dob != null) {
        formData.fields.add(MapEntry('dob', dob));
      }
      if (gender != null) {
        formData.fields.add(MapEntry('gender', gender));
      }
      if (state != null) {
        formData.fields.add(MapEntry('state', state));
      }
      if (city != null) {
        formData.fields.add(MapEntry('city', city));
      }
      if (referral != null) {
        formData.fields.add(MapEntry('referral', referral));
      }
      if (email != null) {
        formData.fields.add(MapEntry('email', email));
        if (kDebugMode) debugPrint('[API] Added field: email=$email');
      }

      if (avatarFile != null) {
        final multipartFile = await MultipartFile.fromFile(avatarFile.path,
            filename: avatarFile.path.split(Platform.pathSeparator).last);
        formData.files.add(MapEntry('avatar', multipartFile));
        if (kDebugMode)
          debugPrint('[API] Added file: avatar=${avatarFile.path}');
      }

      if (kDebugMode) {
        debugPrint(
            '[API] FormData fields: ${formData.fields.length}, files: ${formData.files.length}');
        // Print field keys and values for diagnosis (masking nothing as these are non-sensitive)
        try {
          for (final f in formData.fields) {
            debugPrint('[API] Form field: ${f.key}=${f.value}');
          }
        } catch (_) {}
      }

      if (kDebugMode)
        debugPrint(
            '[API] Calling POST /users/me (multipart with _method=PUT)...');

      if (kDebugMode) {
        final headers = ApiClient().dio.options.headers;
        debugPrint('[API] Headers being sent:');
        headers.forEach((key, value) {
          if (key.toLowerCase() == 'authorization') {
            final authValue = value.toString();
            debugPrint('[API]   $key: ${authValue.substring(0, 30)}...');
          } else {
            debugPrint('[API]   $key: $value');
          }
        });
      }

      // Add method override for Laravel to treat POST as PUT
      formData.fields.add(MapEntry('_method', 'PUT'));

      final resp = await ApiClient()
          .dio
          .post('/users/me', data: formData, onSendProgress: onSendProgress);

      if (kDebugMode) {
        debugPrint('[API] PUT /users/me response status: ${resp.statusCode}');
        debugPrint('[API] Response data: ${resp.data}');
      }

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = resp.data['data'] ?? resp.data ?? {};
        final fullData = Map<String, dynamic>.from(data);

        // Preserve email_changed flag from backend response
        if (resp.data['email_changed'] == true) {
          fullData['email_changed'] = true;
        }

        if (kDebugMode) {
          debugPrint('[API] Extracted user data: $fullData');
        }
        return fullData;
      }

      // Unexpected status code: return raw body
      if (kDebugMode) {
        debugPrint(
            '[API] Unexpected status code ${resp.statusCode}: ${resp.data}');
      }
      return {'success': false, 'message': resp.data};
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[API] DioException in updateProfile: ${e.message}');
        debugPrint('[API] Status code: ${e.response?.statusCode}');
        debugPrint('[API] Response data: ${e.response?.data}');
      }
      // Re-throw so UI can inspect error.response?.statusCode and error.response?.data
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('[API] Error updating profile: $e');
      return {'success': false, 'message': 'Failed to update profile'};
    }
  }

  /// Fetch match details from backend (/api/game-matches/{matchId}).
  Future<Map<String, dynamic>?> getMatchDetails(String matchId) async {
    try {
      final resp = await ApiClient().get('/game-matches/$matchId');
      if (resp.statusCode == 200) {
        return Map<String, dynamic>.from(resp.data['data'] ?? {});
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching match details from backend: $e');
      }
    }
    return null;
  }

  /// Fetch squads / playing information from backend (/api/game-matches/{matchId}/squads).
  /// Returns a flat list of maps with keys { player_id: "", playing11: "true|false" }
  Future<List<Map<String, dynamic>>?> getPlaying11(String matchId) async {
    try {
      final resp = await ApiClient().get('/game-matches/$matchId/squads');
      if (resp.statusCode == 200) {
        final squads = resp.data['data']?['squad'];
        if (squads != null && squads is List) {
          final playing = <Map<String, dynamic>>[];
          for (var team in squads) {
            final List<dynamic> pls = team['players'] ?? [];
            for (var p in pls) {
              playing.add({
                'player_id': (p['id'] ?? p['pid'] ?? '').toString(),
                'playing11': (p['is_playing'] ?? false) ? 'true' : 'false'
              });
            }
          }
          return playing;
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching playing11 from backend: $e');
    }
    return null;
  }

  Future<UserDetail> drawerInfoList() async {
    try {
      final resp = await ApiClient().get('/user');
      if (resp.statusCode == 200) {
        final raw = resp.data;
        // Case A: Standard API envelope { success, message, data: { ... } }
        if (raw is Map && raw.containsKey('data')) {
          final data = raw['data'] ?? {};
          return UserDetail.fromJson(Map<String, dynamic>.from({
            'success': raw['success'] ?? '1',
            'message': raw['message'] ?? '',
            'data': data
          }));
        }

        // Case B: Some backends return the user object directly (id, name, ...)
        if (raw is Map && (raw.containsKey('id') || raw.containsKey('name'))) {
          return UserDetail.fromJson({
            'success': '1',
            'message': '',
            'data': raw,
          });
        }

        // Fallback: try to coerce whatever we have into the expected shape
        final data = (raw is Map) ? (raw['data'] ?? raw) : {};
        return UserDetail.fromJson(Map<String, dynamic>.from(
            {'success': '0', 'message': '', 'data': data}));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching drawer info: $e');
    }

    // fallback to empty/default
    return UserDetail.fromJson(
        jsonDecode('{"success":"0","message":"error","data":{}}'));
  }

  /// Fetch a single team's details from backend (/api/teams/{teamId}).
  Future<Map<String, dynamic>?> getTeamDetails(String teamId) async {
    try {
      // Try /teams/{id} first, then fallback to /teams/{id}/selections
      Map<String, dynamic> raw = {};
      var resp = await ApiClient().get('/teams/$teamId');
      if (resp.statusCode == 200) {
        raw = Map<String, dynamic>.from(resp.data['data'] ?? resp.data ?? {});
      } else {
        // Fallback to selections endpoint if the direct team endpoint is not available
        final respSel = await ApiClient().get('/teams/$teamId/selections');
        if (respSel.statusCode == 200) {
          raw = {
            'team': respSel.data['team'] ?? {},
            'selections': respSel.data['selections'] ?? respSel.data ?? []
          };
        }
      }

      if (raw.isNotEmpty) {
        // Normalize the structure for the UI.
        // First merge raw into normalized, but we'll explicitly set canonical
        // fields afterward so they are not accidentally overwritten by raw.
        final Map<String, dynamic> normalized = {};
        normalized.addAll(raw);

        // Set canonical fields (these should take precedence)
        normalized['id'] = raw['id'] ?? raw['team_id'] ?? raw['team']?['id'];
        normalized['name'] = raw['name'] ??
            raw['team_name'] ??
            raw['team']?['name'] ??
            normalized['name'] ??
            '';
        normalized['logo_url'] = raw['logo_url'] ??
            raw['logo'] ??
            raw['team']?['logo_url'] ??
            normalized['logo_url'] ??
            '';
        normalized['points'] = raw['points'] ?? normalized['points'] ?? 0;
        normalized['user'] = raw['user'] ??
            (raw['user_id'] != null
                ? {'id': raw['user_id']}
                : raw['team']?['user'] ?? normalized['user']);

        // Build players list from selections if present
        final List<dynamic> players = [];
        final List<dynamic> playerIds = [];
        String? captainId;
        String? viceId;
        if (raw['selections'] != null && raw['selections'] is List) {
          for (var s in raw['selections']) {
            final sel = Map<String, dynamic>.from(s ?? {});
            final player = Map<String, dynamic>.from(sel['player'] ?? {});

            final pid =
                (player['id'] ?? player['pid'] ?? sel['player_id'] ?? '')
                    .toString();
            if (pid.isNotEmpty) {
              playerIds.add(pid);
            }

            if (sel['captain'] == true || sel['captain'] == 1) captainId = pid;
            if (sel['vice_captain'] == true || sel['vice_captain'] == 1) {
              viceId = pid;
            }

            players.add({
              'id': pid,
              'name': player['name'] ??
                  player['full_name'] ??
                  player['player_name'] ??
                  '',
              'role': player['role'] ?? player['playing_role'] ?? '',
              'image_url': player['image_url'] ??
                  player['image'] ??
                  player['avatar'] ??
                  ''
            });
          }
        }

        // Fallbacks if backend uses different keys
        if (players.isEmpty) {
          if (raw['players'] != null && raw['players'] is List) {
            for (var p in raw['players']) {
              final player = Map<String, dynamic>.from(p ?? {});
              final pid =
                  (player['id'] ?? player['pid'] ?? player['player_id'] ?? '')
                      .toString();
              if (pid.isNotEmpty) playerIds.add(pid);
              players.add({
                'id': pid,
                'name': player['name'] ?? player['full_name'] ?? '',
                'role': player['role'] ?? player['playing_role'] ?? '',
                'image_url': player['image_url'] ?? player['image'] ?? ''
              });
            }
          }
        }

        // Attach computed selections and ensure they take precedence
        normalized['players'] = players;
        normalized['player_ids'] = playerIds;
        normalized['captain_id'] = captainId ??
            raw['captain_id'] ??
            raw['captain']?.toString() ??
            normalized['captain_id'];
        normalized['vice_captain_id'] = viceId ??
            raw['vice_captain_id'] ??
            raw['vice_captain']?.toString() ??
            normalized['vice_captain_id'];

        return normalized;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching team details: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> getEmailResponce() async {
    try {
      final resp = await ApiClient().get('/user');
      if (resp.statusCode == 200) {
        final data = resp.data['data'] ?? {};
        // Return simple map with verification status
        return {
          'success': 1,
          'message': (data['email_verified'] == 1 || data['is_veryfy'] == '1')
              ? 'Your E-mail and Mobile Number are Verified.'
              : 'Your E-mail or Mobile Number is not verified',
        };
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching email verify status: $e');
    }

    // fallback
    return {
      'success': '1',
      'message': 'Your E-mail and Mobile Number are Verified.'
    };
  }

  Future<UserDetail> getProfile() async {
    // Only use real backend API via drawerInfoList
    return await drawerInfoList();
  }

  Future<TransactionResponseData> getTransaction() async {
    try {
      final resp = await ApiClient().get('/transactions');
      if (resp.statusCode == 200) {
        final data = resp.data['data'] ?? resp.data['transaction'] ?? resp.data;
        // Ensure we pass a Map to the fromJson constructor
        if (data is List) {
          return TransactionResponseData.fromJson(
              {'transaction': data, 'success': 1, 'message': ''});
        } else if (data is Map) {
          return TransactionResponseData.fromJson(
              Map<String, dynamic>.from(data));
        }
      }
    } catch (e) {
      debugPrint('Error fetching transactions from backend: $e');
    }
    return TransactionResponseData.fromJson(
        {'transaction': [], 'success': 0, 'message': 'Failed to fetch'});
  }

  Future<NotificationRespo> notificationApiDataList() async {
    // Backwards-compatible: fetch first page using paginated API
    try {
      final page = await getNotificationsPage(page: 1);
      final list = page['data'] ?? [];
      if (list is List) {
        return NotificationRespo.fromJson(
            {'notification_data': list, 'success': 1, 'message': ''});
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
    return NotificationRespo.fromJson(
        {'notification_data': [], 'success': 0, 'message': 'Failed to fetch'});
  }

  /// Paginated notifications
  Future<Map<String, dynamic>> getNotificationsPage(
      {int page = 1, int perPage = 30}) async {
    try {
      final resp = await ApiClient().getWithEtag('/notifications',
          queryParameters: {'page': page, 'per_page': perPage});
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri(path: '/notifications', queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString()
      }).toString();
      List<dynamic> data = [];
      Map<String, dynamic> meta = {};
      if (resp.statusCode == 200) {
        final payload = resp.data['data'] ?? resp.data;
        if (payload is Map && payload.containsKey('data')) {
          data = payload['data'] ?? [];
          meta = Map<String, dynamic>.from(payload);
        } else if (payload is List) {
          data = payload;
          meta = {
            'data': data,
            'current_page': page,
            'last_page': page,
            'total': data.length
          };
        }
        try {
          await prefs.setString('cache:$uri', jsonEncode(resp.data));
        } catch (_) {}
      } else if (resp.statusCode == 304) {
        try {
          final cached = prefs.getString('cache:$uri');
          if (cached != null) {
            final decoded = jsonDecode(cached);
            final payload = decoded['data'] ?? decoded;
            if (payload is Map && payload.containsKey('data')) {
              data = payload['data'] ?? [];
              meta = Map<String, dynamic>.from(payload);
            } else if (payload is List) {
              data = payload;
              meta = {
                'data': data,
                'current_page': page,
                'last_page': page,
                'total': data.length
              };
            }
          }
        } catch (_) {}
      }
      meta['data'] = data;
      return meta;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching notifications page: $e');
    }
    return {};
  }

  // -----------------------
  // Auth related API calls
  // -----------------------
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiClient().post('/login', data: {
        'email': email,
        'password': password,
      });
      // Handle both 200 OK and error status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = response.data['token'];
        if (token != null) {
          await const FlutterSecureStorage().write(key: 'token', value: token);
        }
      } else if (response.statusCode! >= 400) {
        // Backend returned an error status code with a message
        final message = response.data['message'] ?? 'Login failed';
        throw Exception(message);
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      // Dio network error or timeout
      if (e.response != null && e.response!.data is Map) {
        final message =
            e.response!.data['message'] ?? e.message ?? 'Login failed';
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(String name, String email,
      String password, String passwordConfirmation) async {
    try {
      final response = await ApiClient().post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await const FlutterSecureStorage().write(key: 'token', value: token);
        }
      } else if (response.statusCode! >= 400) {
        // Backend returned an error status code with a message
        final message = response.data['message'] ?? 'Registration failed';
        throw Exception(message);
      }
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      // Dio network error or timeout
      if (e.response != null && e.response!.data is Map) {
        final message =
            e.response!.data['message'] ?? e.message ?? 'Registration failed';
        throw Exception(message);
      }
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await ApiClient().post('/logout');
      await const FlutterSecureStorage().delete(key: 'token');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Social login helper: provider = 'facebook'|'google', token = provider token
  Future<Map<String, dynamic>> socialLogin(
      String provider, String token) async {
    try {
      final response = await ApiClient().post('/social-login', data: {
        'provider': provider,
        'token': token,
      });
      if (response.statusCode == 200 && response.data != null) {
        final serverToken = response.data['token'];
        if (serverToken != null) {
          await const FlutterSecureStorage()
              .write(key: 'token', value: serverToken);
        }
      }
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Verify email with verification code
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final response = await ApiClient().post('/verify-email', data: {
        'email': email,
        'token': verificationCode,
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception(response.data['message'] ?? 'Email verification failed');
    } catch (e) {
      rethrow;
    }
  }

  /// Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail({
    required String email,
  }) async {
    try {
      final response =
          await ApiClient().post('/resend-verification-email', data: {
        'email': email,
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception(
          response.data['message'] ?? 'Failed to resend verification email');
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch winners for a tournament
  Future<Map<String, dynamic>> getTournamentWinners(String tournamentId,
      {int page = 1, int perPage = 50}) async {
    try {
      final resp = await ApiClient().getWithEtag(
          '/tournaments/$tournamentId/winners',
          queryParameters: {'page': page, 'per_page': perPage});
      final prefs = await SharedPreferences.getInstance();
      final uri = Uri(
          path: '/tournaments/$tournamentId/winners',
          queryParameters: {
            'page': page.toString(),
            'per_page': perPage.toString()
          }).toString();
      List<dynamic> data = [];
      Map<String, dynamic> meta = {};
      if (resp.statusCode == 200) {
        final payload = resp.data['data'] ?? resp.data;
        if (payload is Map && payload.containsKey('data')) {
          data = payload['data'] ?? [];
          meta = Map<String, dynamic>.from(payload);
        } else if (payload is List) {
          data = payload;
          meta = {
            'data': data,
            'current_page': page,
            'last_page': page,
            'total': data.length
          };
        }
        try {
          await prefs.setString('cache:$uri', jsonEncode(resp.data));
        } catch (_) {}
      } else if (resp.statusCode == 304) {
        try {
          final cached = prefs.getString('cache:$uri');
          if (cached != null) {
            final decoded = jsonDecode(cached);
            final payload = decoded['data'] ?? decoded;
            if (payload is Map && payload.containsKey('data')) {
              data = payload['data'] ?? [];
              meta = Map<String, dynamic>.from(payload);
            } else if (payload is List) {
              data = payload;
              meta = {
                'data': data,
                'current_page': page,
                'last_page': page,
                'total': data.length
              };
            }
          }
        } catch (_) {}
      }
      // Normalize winners
      final winners = data.map((w) {
        final Map<String, dynamic> winner = Map<String, dynamic>.from(w ?? {});
        return {
          'rank': winner['rank'] ?? 0,
          'fantasy_team_name': winner['fantasy_team_name'] ?? '',
          'user_name': winner['user_name'] ?? '',
          'user_email': winner['user_email'] ?? '',
          'total_points': winner['total_points'] ?? 0,
        };
      }).toList();
      meta['data'] = winners;
      return meta;
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching tournament winners: $e');
    }
    return {'data': []};
  }

  // -----------------------
  // Cancel Request API calls
  // -----------------------

  /// Submit a cancel request for a fantasy team
  /// POST /api/cancel-requests with fantasy_team_id
  Future<Map<String, dynamic>> submitCancelRequest(String teamId) async {
    try {
      final response = await ApiClient().post('/cancel-requests', data: {
        'fantasy_team_id': int.tryParse(teamId) ?? 0,
      });
      if (kDebugMode) {
        debugPrint('[submitCancelRequest] POST /cancel-requests');
        debugPrint('[submitCancelRequest] Response: ${response.data}');
      }
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'success': false, 'message': 'Unexpected server response'};
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('DioException submitting cancel request: $e');
      if (e.response != null && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        final message =
            responseData['message'] ?? 'Failed to submit cancel request';
        final errors = responseData['errors'];
        return {
          'success': false,
          'message': message,
          if (errors != null) 'errors': errors,
        };
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to submit cancel request'
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error submitting cancel request: $e');
      return {'success': false, 'message': 'Failed to submit cancel request'};
    }
  }

  /// Fetch current user's cancel requests
  /// GET /api/cancel-requests (with optional pagination)
  Future<List<Map<String, dynamic>>> getCancelRequests({int page = 1}) async {
    try {
      final resp = await ApiClient().get('/cancel-requests?page=$page');
      if (resp.statusCode == 200) {
        final data = resp.data['data'];
        // Handle paginated response
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> requests = data['data'] ?? [];
          return requests.map((r) => Map<String, dynamic>.from(r)).toList();
        }
        if (data is List) {
          return data.map((r) => Map<String, dynamic>.from(r)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching cancel requests: $e');
    }
    return [];
  }

  /// Admin: Fetch all cancel requests (paginated with optional filtering)
  /// GET /api/admin/cancel-requests?status=pending|approved|rejected
  Future<List<Map<String, dynamic>>> getAdminCancelRequests({
    int page = 1,
    String? status,
  }) async {
    try {
      String endpoint = '/admin/cancel-requests?page=$page';
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }
      final resp = await ApiClient().get(endpoint);
      if (resp.statusCode == 200) {
        final data = resp.data['data'];
        // Handle paginated response
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> requests = data['data'] ?? [];
          return requests.map((r) => Map<String, dynamic>.from(r)).toList();
        }
        if (data is List) {
          return data.map((r) => Map<String, dynamic>.from(r)).toList();
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching admin cancel requests: $e');
    }
    return [];
  }

  /// Admin: Approve a cancel request (refunds the user)
  /// POST /api/admin/cancel-requests/{id}/approve
  Future<Map<String, dynamic>> approveCancelRequest(String requestId) async {
    try {
      final response =
          await ApiClient().post('/admin/cancel-requests/$requestId/approve');
      if (kDebugMode) {
        debugPrint(
            '[approveCancelRequest] POST /admin/cancel-requests/$requestId/approve');
        debugPrint('[approveCancelRequest] Response: ${response.data}');
      }
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'success': false, 'message': 'Unexpected server response'};
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('DioException approving cancel request: $e');
      if (e.response != null && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        final message =
            responseData['message'] ?? 'Failed to approve cancel request';
        return {
          'success': false,
          'message': message,
        };
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to approve cancel request'
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error approving cancel request: $e');
      return {'success': false, 'message': 'Failed to approve cancel request'};
    }
  }

  /// Admin: Reject a cancel request
  /// POST /api/admin/cancel-requests/{id}/reject with optional admin_notes
  Future<Map<String, dynamic>> rejectCancelRequest(
    String requestId, {
    String? adminNotes,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (adminNotes != null && adminNotes.isNotEmpty) {
        payload['admin_notes'] = adminNotes;
      }
      final response = await ApiClient()
          .post('/admin/cancel-requests/$requestId/reject', data: payload);
      if (kDebugMode) {
        debugPrint(
            '[rejectCancelRequest] POST /admin/cancel-requests/$requestId/reject');
        debugPrint('[rejectCancelRequest] Response: ${response.data}');
      }
      if (response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
      return {'success': false, 'message': 'Unexpected server response'};
    } on DioException catch (e) {
      if (kDebugMode) debugPrint('DioException rejecting cancel request: $e');
      if (e.response != null && e.response?.data is Map) {
        final responseData = e.response!.data as Map<String, dynamic>;
        final message =
            responseData['message'] ?? 'Failed to reject cancel request';
        return {
          'success': false,
          'message': message,
        };
      }
      return {
        'success': false,
        'message': e.message ?? 'Failed to reject cancel request'
      };
    } catch (e) {
      if (kDebugMode) debugPrint('Error rejecting cancel request: $e');
      return {'success': false, 'message': 'Failed to reject cancel request'};
    }
  }

  /// Clear cache for a specific endpoint
  /// This forces a fresh fetch on the next call
  Future<void> clearCacheFor(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('cache:') && key.contains(path)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing cache for $path: $e');
    }
  }

  /// Clear cached ETag for a specific path
  Future<void> clearETagFor(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('etag:') && key.contains(path)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error clearing ETag for $path: $e');
    }
  }
}
