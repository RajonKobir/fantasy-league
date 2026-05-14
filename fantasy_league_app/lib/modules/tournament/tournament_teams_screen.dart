import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/modules/tournament/tournament_players_screen.dart';

class TournamentTeamsScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentTeamsScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  _TournamentTeamsScreenState createState() => _TournamentTeamsScreenState();
}

class _TournamentTeamsScreenState extends State<TournamentTeamsScreen> {
  List<Map<String, dynamic>> teams = [];
  Map<String, dynamic>? tournamentDetails;
  bool isLoading = true;
  String? error;
  Set<String> selectedPlayerIds = {};
  String? captainId;
  String? viceCaptainId;

  @override
  void initState() {
    super.initState();
    fetchTeams();
  }

  Future<void> fetchTeams() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    late Timer timeoutTimer;
    try {
      if (kDebugMode)
        debugPrint(
            '[TournamentTeams] fetchTeams called for tournament: ${widget.tournamentId}');

      // Set a 12-second timeout
      timeoutTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && isLoading) {
          if (kDebugMode) debugPrint('[TournamentTeams] API timeout after 12s');
          setState(() {
            isLoading = false;
            error = 'Loading took too long. Please try again.';
          });
        }
      });

      // Fetch tournament details which includes teams - with explicit timeout
      final details = await ApiProvider()
          .getTournamentDetails(widget.tournamentId)
          .timeout(const Duration(seconds: 12), onTimeout: () {
        if (kDebugMode)
          debugPrint(
              '[TournamentTeams] getTournamentDetails timeout after 12s');
        throw TimeoutException('API call timed out');
      });

      // Cancel the timeout since we got a response
      timeoutTimer.cancel();

      if (details != null && details['teams'] != null) {
        if (!mounted) return;
        if (kDebugMode)
          debugPrint(
              '[TournamentTeams] Got teams: ${(details["teams"] as List?)?.length ?? 0} teams');
        setState(() {
          tournamentDetails = details;
          teams = List<Map<String, dynamic>>.from(details['teams'] ?? []);
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        if (kDebugMode) debugPrint('[TournamentTeams] No teams in response');
        setState(() {
          error = 'No teams found for this tournament';
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[TournamentTeams] Error in fetchTeams: $e');
      if (!mounted) return;
      setState(() {
        error = 'Error loading teams: $e';
        isLoading = false;
      });
    } finally {
      // Cancel timeout if still pending
      timeoutTimer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} - Teams'),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? RefreshIndicator(
                  onRefresh: fetchTeams,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(error!,
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            Text('Slide down to refresh',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : teams.isEmpty
                  ? RefreshIndicator(
                      onRefresh: fetchTeams,
                      child: const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 300,
                          child: Center(
                            child: Text('No teams available'),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchTeams,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final team = teams[index];
                          final teamName = team['name'] ?? 'Team';
                          final teamLogo = (team['logo_url'] ?? '').toString();
                          final playersCount =
                              (team['selections'] as List?)?.length ?? 0;

                          return GestureDetector(
                            onTap: () async {
                              // Robustly parse entry_fee as it may come as String or num
                              final entryFeeRaw =
                                  tournamentDetails?['entry_fee'] ?? 0;
                              final entryFeeNum = entryFeeRaw is num
                                  ? entryFeeRaw
                                  : (double.tryParse(entryFeeRaw.toString()) ??
                                      0.0);

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TournamentPlayersScreen(
                                    tournamentId: widget.tournamentId,
                                    tournamentName: widget.tournamentName,
                                    teamId: team['id'].toString(),
                                    teamName: teamName,
                                    requiredPlayers: (tournamentDetails?[
                                            'required_players'] ??
                                        0) as int,
                                    entryFee: entryFeeNum,
                                    initialSelectedPlayerIds: selectedPlayerIds,
                                    initialCaptainId: captainId,
                                    initialViceCaptainId: viceCaptainId,
                                    teamPlayers: team['players'] != null
                                        ? List<Map<String, dynamic>>.from(
                                            team['players'] as List? ?? [])
                                        : null,
                                  ),
                                ),
                              );

                              // Auto-refresh teams after returning from team creation
                              if (result != null && result is Map) {
                                setState(() {
                                  selectedPlayerIds =
                                      result['selectedPlayerIds'] ?? {};
                                  captainId = result['captainId'];
                                  viceCaptainId = result['viceCaptainId'];
                                });
                                // Refresh teams list to show newly created fantasy team
                                await fetchTeams();
                              }
                            },
                            child: Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Team Logo
                                    if (teamLogo.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          teamLogo,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                  Icons.sports_cricket),
                                            );
                                          },
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.sports_cricket),
                                      ),
                                    const SizedBox(width: 16),
                                    // Team Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            teamName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$playersCount players selected',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow
                                    const Icon(Icons.arrow_forward_ios,
                                        size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
