import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:fantasyleague/models/team_response_data.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/modules/tournament/team_detail_screen.dart';
import 'package:fantasyleague/modules/tournament/team_preview_screen.dart';

class CreatedTeamsScreen extends StatefulWidget {
  final String matchId;
  const CreatedTeamsScreen({super.key, required this.matchId});

  @override
  _CreatedTeamsScreenState createState() => _CreatedTeamsScreenState();
}

class _CreatedTeamsScreenState extends State<CreatedTeamsScreen> {
  GetTeamResponseData? teams;
  bool isLoading = true;
  bool showMine = true;
  List<Map<String, dynamic>> myTeams = [];

  @override
  void initState() {
    super.initState();
    fetchTeams();
    fetchMyTeams();
  }

  void fetchTeams() async {
    setState(() => isLoading = true);
    final hide =
        await showTimedLoader(context, timeout: const Duration(seconds: 12));
    try {
      teams = await ApiProvider().getCreatedTeamList(widget.matchId);
      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading created teams: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    } finally {
      hide();
    }
  }

  void fetchMyTeams() async {
    try {
      final list = await ApiProvider().getMyTeams();
      if (!mounted) return;
      setState(() => myTeams = list);
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching my teams: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Created Teams')),
      body: isLoading
          ? const SizedBox.shrink()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => showMine = true),
                          style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  showMine ? Colors.blue.shade50 : null),
                          child: const Text('My Teams'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => showMine = false),
                          style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  !showMine ? Colors.blue.shade50 : null),
                          child: const Text('All Teams'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(builder: (context) {
                    final list = showMine
                        ? myTeams
                            .where((t) =>
                                (t['match_key'] ?? t['game_match_id'] ?? '')
                                    .toString() ==
                                widget.matchId)
                            .toList()
                        : (teams?.teamData?.map((t) => t.toJson()).toList() ??
                            []);

                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(showMine
                                ? 'You have no teams for this match'
                                : 'No teams found'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate back to players screen to create a team
                                Navigator.pop(context);
                              },
                              child: const Text('Create Team'),
                            )
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final t = list[index];
                        final logo = t['logo_url'] ?? t['logo'] ?? '';
                        final title = t['name'] ??
                            t['team_name'] ??
                            'Team ${t['id'] ?? ''}';
                        final caption = t['captain_name'] ?? t['captun'] ?? '';
                        final points = (t['points'] is num)
                            ? (t['points'] is num
                                ? (t['points'] as num).toDouble()
                                : (t['points'] is String
                                    ? double.tryParse(t['points']) ?? 0.0
                                    : 0.0))
                            : 0.0;

                        return ListTile(
                          leading: logo != null && logo.toString().isNotEmpty
                              ? AvatarImage(
                                  imageUrl: logo.toString(),
                                  sizeValue: 40,
                                  radius: 20,
                                  isCircle: true,
                                  entityType: 'team',
                                )
                              : const Icon(Icons.group),
                          title: Text(title.toString()),
                          subtitle: Text('Captain: ${caption ?? ' - '}'),
                          trailing: Text('${points.toStringAsFixed(1)} pts'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamDetailScreen(
                                    teamId:
                                        (t['id'] ?? t['team_id']).toString(),
                                    teamName: title.toString()),
                              ),
                            );
                          },
                          onLongPress: () {
                            final teamMap = t;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamPreviewScreen(
                                    team: Map<String, dynamic>.from(teamMap)),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                )
              ],
            ),
    );
  }
}
