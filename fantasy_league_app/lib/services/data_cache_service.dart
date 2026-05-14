import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';

/// Global singleton for caching frequently accessed data
class DataCacheService {
  static final DataCacheService _instance = DataCacheService._internal();

  factory DataCacheService() {
    return _instance;
  }

  DataCacheService._internal();

  // Cache storage
  List<Map<String, dynamic>> _tournaments = [];
  bool _tournamentsLoaded = false;

  // Getters
  List<Map<String, dynamic>> get tournaments => _tournaments;
  bool get tournamentsLoaded => _tournamentsLoaded;

  /// Pre-fetch tournaments and cache them for immediate access
  Future<List<Map<String, dynamic>>> preloadTournaments() async {
    if (_tournamentsLoaded && _tournaments.isNotEmpty) {
      // Return cached data immediately
      return _tournaments;
    }

    try {
      final fetched = await ApiProvider().getTournaments();
      _tournaments = fetched;
      _tournamentsLoaded = true;
      if (kDebugMode) {
        debugPrint(
            '[DataCache] Tournaments pre-loaded: ${_tournaments.length} items');
      }
      return _tournaments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataCache] Error pre-loading tournaments: $e');
      }
      return [];
    }
  }

  /// Force refresh tournaments from API
  Future<List<Map<String, dynamic>>> refreshTournaments() async {
    try {
      final fetched = await ApiProvider().getTournaments();
      _tournaments = fetched;
      _tournamentsLoaded = true;
      if (kDebugMode) {
        debugPrint(
            '[DataCache] Tournaments refreshed: ${_tournaments.length} items');
      }
      return _tournaments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DataCache] Error refreshing tournaments: $e');
      }
      return _tournaments;
    }
  }

  /// Clear cache (e.g., on logout)
  void clearCache() {
    _tournaments = [];
    _tournamentsLoaded = false;
    if (kDebugMode) {
      debugPrint('[DataCache] Cache cleared');
    }
  }
}
