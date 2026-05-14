import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class Winners extends StatefulWidget {
  const Winners({super.key});

  @override
  _WinnerState createState() => _WinnerState();
}

class _WinnerState extends State<Winners> {
  late ApiProvider _apiProvider;
  List<Map<String, dynamic>> tournaments = [];
  Map<String, List<Map<String, dynamic>>> winnersMap = {};
  bool isLoading = true;
  String? selectedTournamentId;
  // Pagination state per tournament
  Map<String, int> _winnersPage = {};
  Map<String, int> _winnersLastPage = {};
  bool _isLoadingMoreWinners = false;

  @override
  void initState() {
    super.initState();
    _apiProvider = ApiProvider();
    _loadTournaments();
  }

  Future<void> _loadWinnersForTournament(String tournamentId,
      {int page = 1, int perPage = 20}) async {
    setState(() {
      if (page == 1) {
        winnersMap[tournamentId] = [];
      }
      _isLoadingMoreWinners = page > 1;
    });

    try {
      final resp = await _apiProvider.getTournamentWinners(tournamentId,
          page: page, perPage: perPage);
      final List<dynamic> data = resp['data'] ?? [];
      final normalized = List<Map<String, dynamic>>.from(
          data.map((d) => Map<String, dynamic>.from(d)));

      setState(() {
        if (page == 1)
          winnersMap[tournamentId] = normalized;
        else
          winnersMap[tournamentId] = [
            ...(winnersMap[tournamentId] ?? []),
            ...normalized
          ];
        _winnersPage[tournamentId] = resp['current_page'] ?? page;
        _winnersLastPage[tournamentId] = resp['last_page'] ?? page;
        _isLoadingMoreWinners = false;
      });
    } catch (e) {
      if (mounted) debugPrint('[Winners] Error loading winners page: $e');
      setState(() {
        _isLoadingMoreWinners = false;
      });
    }
  }

  Future<void> _loadTournaments() async {
    setState(() {
      isLoading = true;
    });

    Timer? timeoutTimer;
    try {
      // Set a 12-second timeout to prevent spinner from hanging
      timeoutTimer = Timer(const Duration(seconds: 12), () {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request timed out. Please try again.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      });

      final tournamentsList = await _apiProvider.getTournaments();

      // Filter for active tournaments
      final now = DateTime.now();
      final activeTournaments = tournamentsList.where((t) {
        final endDate = DateTime.tryParse(t['end_at']?.toString() ?? '');
        return endDate == null || endDate.isAfter(now);
      }).toList();

      setState(() {
        tournaments = activeTournaments;
        if (tournaments.isNotEmpty) {
          selectedTournamentId = tournaments.first['id'];
        }
      });
      // Load winners for selected tournament only (paged)
      if (selectedTournamentId != null) {
        try {
          await _loadWinnersForTournament(selectedTournamentId!, page: 1);
        } catch (e) {
          if (mounted)
            debugPrint('[Winners] Error loading winners for tournament: $e');
        }
      }

      // Cancel timeout since we got a successful response
      timeoutTimer.cancel();
    } catch (e) {
      timeoutTimer?.cancel();
      if (mounted) {
        String errorMsg = 'Error loading tournaments';
        if (e is TimeoutException) {
          errorMsg = 'Request timed out. Please try again.';
        } else {
          errorMsg = 'Error loading tournaments: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      timeoutTimer?.cancel();
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globals.themeNotifier,
      builder: (context, child) {
        return Scaffold(
          drawer: AppDrawer(
            mySettingClick: () {},
            referralClick: () {},
          ),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu,
                    color: AllCoustomTheme.getReBlackAndWhiteThemeColors()),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tournament Winners",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE16,
                        color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
                      ),
                    ),
                    Text(
                      "Active Tournaments",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE12,
                        color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
                      ),
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
                Icon(FontAwesomeIcons.trophy,
                    color: AllCoustomTheme.getReBlackAndWhiteThemeColors()),
              ],
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tournaments.isEmpty
                  ? const Center(
                      child: Text(
                        'No active tournaments available',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE14,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Tournament selector
                        if (tournaments.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: tournaments.map((tournament) {
                                  final isSelected =
                                      selectedTournamentId == tournament['id'];
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(tournament['name'] ?? ''),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          selectedTournamentId =
                                              tournament['id'];
                                        });
                                      },
                                      backgroundColor: Colors.grey[200],
                                      selectedColor:
                                          Theme.of(context).primaryColor,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        // Winners list
                        Expanded(
                          child: _buildWinnersList(),
                        ),
                      ],
                    ),
        );
      },
    );
  }

  Widget _buildWinnersList() {
    final currentWinners = winnersMap[selectedTournamentId] ?? [];

    if (currentWinners.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTournaments,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    FontAwesomeIcons.trophy,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No winners yet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final page = _winnersPage[selectedTournamentId] ?? 1;
    final last = _winnersLastPage[selectedTournamentId] ?? 1;

    return RefreshIndicator(
      onRefresh: () async {
        await _loadTournaments();
        if (selectedTournamentId != null)
          await _loadWinnersForTournament(selectedTournamentId!, page: 1);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(right: 4, left: 4, top: 8, bottom: 70),
        itemCount: currentWinners.length + (page < last ? 2 : 1),
        itemBuilder: (context, index) {
          if (index < currentWinners.length) {
            final winner = currentWinners[index];
            final rank = winner['rank'] ?? (index + 1);
            final teamName = winner['fantasy_team_name'] ?? 'Unknown Team';
            final userName = winner['user_name'] ?? 'Unknown User';
            final points = winner['total_points'] ?? 0;

            return _buildWinnerCard(
              rank: rank,
              teamName: teamName,
              userName: userName,
              points: points,
            );
          }

          if (index == currentWinners.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: Text(
                  'Showing ${currentWinners.length} (Page $page of $last)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          }

          return _isLoadingMoreWinners
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AllCoustomTheme.getThemeData().primaryColor,
                        ),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: page < last && selectedTournamentId != null
                          ? () => _loadWinnersForTournament(
                              selectedTournamentId!,
                              page: page + 1)
                          : null,
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Load More'),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildWinnerCard({
    required int rank,
    required String teamName,
    required String userName,
    required int points,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getRankColor(rank),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '#$rank',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Winner Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    teamName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE12,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Points Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    points.toString(),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'Points',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE10,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700] ?? Colors.amber;
      case 2:
        return Colors.grey[400] ?? Colors.grey;
      case 3:
        return Colors.orange[700] ?? Colors.orange;
      default:
        return Theme.of(context).primaryColor;
    }
  }
}
