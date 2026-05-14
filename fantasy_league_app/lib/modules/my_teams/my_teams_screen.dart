import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
import 'package:fantasyleague/modules/tournament/team_preview_screen.dart';
import 'package:fantasyleague/utils/notification_service.dart';

class MyTeamsScreen extends StatefulWidget {
  final void Function()? menuCallBack;

  const MyTeamsScreen({super.key, this.menuCallBack});

  @override
  State<MyTeamsScreen> createState() => _MyTeamsScreenState();
}

class _MyTeamsScreenState extends State<MyTeamsScreen>
    with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _myTeamsFuture;
  final ApiProvider _apiProvider = ApiProvider();
  Timer? _teamsLoadTimeout;
  bool _isRefreshing = false;

  /// Helper method to load teams with timeout protection
  Future<List<Map<String, dynamic>>> _loadTeamsWithTimeout() {
    return _apiProvider.getMyTeams().timeout(const Duration(seconds: 12),
        onTimeout: () {
      if (kDebugMode)
        debugPrint('[MyTeams] Teams load timed out after 12 seconds');
      // Return empty list to trigger error state in FutureBuilder
      throw TimeoutException('Loading teams took too long. Please try again.');
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Load teams
    _myTeamsFuture = _loadTeamsWithTimeout();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _teamsLoadTimeout?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshTeams();
    }
  }

  // Removed unused _loadTeams method to resolve analyzer warning.

  Future<void> _refreshTeams() async {
    if (_isRefreshing) return; // Prevent multiple simultaneous refreshes
    _isRefreshing = true;

    try {
      // Clear cache and ETag for /fantasy-teams to force a fresh fetch
      await _apiProvider.clearCacheFor('/fantasy-teams');
      await _apiProvider.clearETagFor('/fantasy-teams');

      // Reload teams with fresh data
      await _reloadTeamsForRefresh();
    } catch (e) {
      debugPrint('[MyTeams] Error during refresh: $e');
    } finally {
      _isRefreshing = false;
      if (mounted) setState(() {});
    }
  }

  /// Reload teams for manual refresh - bypasses _isLoadingMore check
  Future<void> _reloadTeamsForRefresh() async {
    try {
      _myTeamsFuture = _loadTeamsWithTimeout();
      await _myTeamsFuture;

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
      debugPrint('[MyTeams] Error reloading teams for refresh: $e');
    }
  }

  Future<void> _handleCancelAndRefund(Map<String, dynamic> team) async {
    final teamId =
        (team['id'] ?? team['team_id'] ?? team['teamId'] ?? '').toString();
    if (teamId.isEmpty) {
      AppNotification.showError(context,
          title: 'Error', message: 'Invalid team ID');
      return;
    }

    final rp =
        team['tournament']?['refund_percentage_at_cancel_request'] ?? 100.0;
    final double refundPercentage;
    if (rp is num) {
      refundPercentage = rp.toDouble();
    } else if (rp is String) {
      refundPercentage = double.tryParse(rp) ?? 100.0;
    } else {
      refundPercentage = 100.0;
    }

    final double entryFee;
    if (team['tournament'] is Map<String, dynamic>) {
      final tournament = team['tournament'] as Map<String, dynamic>;
      final ef = tournament['entry_fee'] ?? 0.0;
      if (ef is num) {
        entryFee = ef.toDouble();
      } else if (ef is String) {
        entryFee = double.tryParse(ef) ?? 0.0;
      } else {
        entryFee = 0.0;
      }
    } else {
      entryFee = 0.0;
    }

    final refundAmount = entryFee * (refundPercentage / 100);

    final refundPercentageInt = refundPercentage.toInt();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are you sure you want to cancel\nand refund by $refundPercentageInt%?',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team: ${team['name'] ?? 'Unnamed Team'}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            const Text(
                'This will submit a cancel request for approval by the admin.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refund Breakdown:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Entry Fee:',
                          style: TextStyle(color: Colors.grey[700])),
                      Text('৳${entryFee.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Refund Rate:',
                          style: TextStyle(color: Colors.grey[700])),
                      Text('$refundPercentageInt%',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700])),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('You will receive:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800])),
                      Text('৳${refundAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green[700])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit Cancel Request',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final loader =
        await showTimedLoader(context, timeout: const Duration(seconds: 12));
    try {
      final result = await _apiProvider.submitCancelRequest(teamId);
      if (!mounted) return;
      loader.dismiss();

      if (result['success'] == true) {
        AppNotification.showSuccess(context,
            title: 'Cancel Request Submitted',
            message:
                'Your cancel request has been submitted for admin approval.');
        _refreshTeams();
      } else {
        AppNotification.showError(context,
            title: 'Failed',
            message: result['message'] ?? 'Failed to submit cancel request');
      }
    } catch (e) {
      if (!mounted) return;
      loader.dismiss();
      AppNotification.showError(context,
          title: 'Error', message: 'An error occurred: $e');
    }
  }

  Future<void> _openTeamPreview(Map<String, dynamic> team) async {
    final teamId =
        (team['id'] ?? team['team_id'] ?? team['teamId'] ?? '').toString();
    if (teamId.isEmpty) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TeamPreviewScreen(team: team)));
      return;
    }

    late var loader;
    late Timer loadTimer;

    try {
      loader =
          await showTimedLoader(context, timeout: const Duration(seconds: 12));

      // Add a fallback timeout for the preview load
      loadTimer = Timer(const Duration(seconds: 15), () {
        try {
          loader.dismiss();
        } catch (_) {}
      });

      // Fetch full fantasy team details which includes player names
      debugPrint('[TeamPreview] Fetching full team details for: $teamId');
      final fullTeam = await _apiProvider
          .getFantasyTeam(teamId)
          .timeout(const Duration(seconds: 12));
      debugPrint('[TeamPreview] Full team response: $fullTeam');

      // Check if we got valid team data
      if (fullTeam.isEmpty) {
        throw Exception('Failed to load team details - empty response');
      }

      if (!mounted) {
        try {
          loader.dismiss();
        } catch (_) {}
        return;
      }

      // Cancel the fallback timer and dismiss the loader
      try {
        loadTimer.cancel();
      } catch (_) {}

      try {
        loader.dismiss();
      } catch (_) {}

      debugPrint('[TeamPreview] Loader dismissed, navigating to preview');

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TeamPreviewScreen(team: fullTeam)));
      }
    } on TimeoutException {
      try {
        loadTimer.cancel();
      } catch (_) {}
      try {
        loader.dismiss();
      } catch (_) {}
      if (!mounted) return;
      AppNotification.showError(context,
          title: 'Timeout',
          message: 'Loading team details took too long. Please try again.');
    } catch (e) {
      try {
        loadTimer.cancel();
      } catch (_) {}
      try {
        loader.dismiss();
      } catch (_) {}
      if (!mounted) return;
      debugPrint('[TeamPreview] Error: $e');
      AppNotification.showError(context,
          title: 'Failed to load team',
          message: 'Could not load team players. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: AppDrawer(mySettingClick: () {}, referralClick: () {}),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
          title: const Text('My Teams',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
          leading: widget.menuCallBack != null
              ? null
              : Builder(
                  builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer())),
          bottom: TabBar(
            labelColor: AllCoustomTheme.getBlackAndWhiteThemeColors(),
            unselectedLabelColor: AllCoustomTheme.getTextThemeColors(),
            indicatorColor: AllCoustomTheme.getBlackAndWhiteThemeColors(),
            tabs: const [
              Tab(text: 'Running'),
              Tab(text: 'Completed'),
              Tab(text: 'Canceled'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _myTeamsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${snapshot.error}',
                              style: TextStyle(color: Colors.grey[600]),
                              textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          Text('Pull down to refresh',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final teams = snapshot.data ?? [];

            if (teams.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No teams created yet',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Create your first fantasy team',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[500])),
                          const SizedBox(height: 12),
                          Text('Pull down to refresh',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Use TabBarView with RefreshIndicator in each tab
            return TabBarView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                RefreshIndicator(
                  onRefresh: _refreshTeams,
                  child: _build_teams_list_for(teams, 'running'),
                ),
                RefreshIndicator(
                  onRefresh: _refreshTeams,
                  child: _build_teams_list_for(teams, 'completed'),
                ),
                RefreshIndicator(
                  onRefresh: _refreshTeams,
                  child: _build_teams_list_for(teams, 'canceled'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _build_teams_list_for(
      List<Map<String, dynamic>> teams, String filter) {
    final filtered = teams.where((team) {
      final tStatus = (team['status'] ?? '').toString();
      final tourStatus = (team['tournament']?['status'] ?? '').toString();

      switch (filter) {
        case 'running':
          return tStatus == 'approved' &&
              (tourStatus == 'running' || tourStatus == 'active');
        case 'completed':
          return tourStatus == 'completed' || tStatus == 'completed';
        case 'canceled':
          return tStatus == 'canceled';
        default:
          return true;
      }
    }).toList();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No teams found',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pull down to reload',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final team = filtered[index];
        final teamName = team['name'] ?? 'Unnamed Team';
        final tournamentName = team['tournament'] is Map<String, dynamic>
            ? (team['tournament'] as Map<String, dynamic>)['name'] ??
                'Unknown Tournament'
            : 'Unknown Tournament';
        final totalPoints = team['total_points'] ?? 0;
        final playerCount = (team['player_ids'] as List?)?.length ?? 0;
        final captainName = team['captain'] is Map<String, dynamic>
            ? (team['captain'] as Map<String, dynamic>)['name'] ?? 'Unknown'
            : 'Unknown';
        final viceCaptainName = team['viceCaptain'] is Map<String, dynamic>
            ? (team['viceCaptain'] as Map<String, dynamic>)['name'] ?? 'Unknown'
            : 'Unknown';

        final teamStatus = (team['status'] ?? '').toString();
        final tournamentStatus =
            (team['tournament']?['status'] ?? '').toString();
        final canCancel =
            teamStatus == 'approved' && tournamentStatus == 'running';

        // Extract cancel request info if team is canceled
        final isCanceled = teamStatus == 'canceled';
        final cancelRequest =
            isCanceled && team['cancel_request'] is Map<String, dynamic>
                ? (team['cancel_request'] as Map<String, dynamic>)
                : null;

        // Parse refund percentage safely (API may return as string or number)
        final double refundPercentage;
        if (cancelRequest != null) {
          final rp = cancelRequest['refund_percentage_at_request'] ?? 0.0;
          if (rp is num) {
            refundPercentage = rp.toDouble();
          } else if (rp is String) {
            refundPercentage = double.tryParse(rp) ?? 0.0;
          } else {
            refundPercentage = 0.0;
          }
        } else {
          refundPercentage = 0.0;
        }

        // Parse refund amount safely (API may return as string or number)
        final double refundAmount;
        if (cancelRequest != null) {
          final ra = cancelRequest['refund_amount'] ?? 0.0;
          if (ra is num) {
            refundAmount = ra.toDouble();
          } else if (ra is String) {
            refundAmount = double.tryParse(ra) ?? 0.0;
          } else {
            refundAmount = 0.0;
          }
        } else {
          refundAmount = 0.0;
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(teamName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text('Tournament: $tournamentName',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 4),
                Text('Captain: $captainName | VC: $viceCaptainName',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                // Show refund info for canceled teams
                if (isCanceled) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Refund Rate:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700])),
                      Text('${refundPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700])),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Refund Amount:',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700])),
                      Text('৳${refundAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700])),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                if (team['players'] is List<dynamic> &&
                    (team['players'] as List<dynamic>).isNotEmpty) ...[
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: (team['players'] as List<dynamic>)
                          .take(6)
                          .map<Widget>((p) {
                        final pname = p is Map<String, dynamic>
                            ? (p['name'] ??
                                    p['full_name'] ??
                                    p['player_name'] ??
                                    p['title'] ??
                                    p['playerName'] ??
                                    '')
                                .toString()
                            : p.toString();
                        return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(pname,
                                style: const TextStyle(fontSize: 12)));
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                ] else
                  const SizedBox.shrink(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('$playerCount Players',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: AllCoustomTheme.getThemeData().primaryColor,
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('Points: $totalPoints',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
            trailing: canCancel
                ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    tooltip: 'Cancel team',
                    onPressed: () => _handleCancelAndRefund(team))
                : null,
            onTap: () => _openTeamPreview(team),
          ),
        );
      },
    );
  }
}
