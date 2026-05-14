import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/utils/notification_service.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:fantasyleague/modules/tournament/edit_team_screen.dart';
import 'package:fantasyleague/modules/fantasy/fantasy_team_builder_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  final String teamName;

  /// Optional test-injected delete callback. If provided, called instead of
  /// making a network request to delete the team. Signature: Future<bool>(teamId)
  final Future<bool> Function(String teamId)? deleteTeam;

  const TeamDetailScreen(
      {super.key,
      required this.teamId,
      required this.teamName,
      this.deleteTeam});

  @override
  _TeamDetailScreenState createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  /// Performs the actual delete flow after the user confirmed.
  /// Extracted to make it testable.
  Future<void> performDeleteConfirmed(BuildContext context) async {
    // debug
    // ignore: avoid_print
    if (kDebugMode)
      debugPrint(
          'performDeleteConfirmed: widget.deleteTeam == ${widget.deleteTeam == null} teamId=${widget.teamId}');
    final deleteFn =
        widget.deleteTeam ?? (String id) => ApiProvider().deleteTeam(id);
    final success = await deleteFn(widget.teamId);
    // ignore: avoid_print
    if (kDebugMode)
      debugPrint('performDeleteConfirmed: deleteFn returned $success');
    if (success) {
      // go back to previous screen and indicate deletion
      Navigator.pop(context, true);
    } else {
      if (context.mounted) {
        AppNotification.showError(
          context,
          title: 'Failed to Delete Team',
          message: 'Please try again',
        );
      }
    }
  }

  Map<String, dynamic>? details;
  bool isLoading = true;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    fetchDetails();
    fetchCurrentUser();
  }

  void fetchDetails() async {
    setState(() => isLoading = true);
    final hide =
        await showTimedLoader(context, timeout: const Duration(seconds: 12));
    try {
      details = await ApiProvider().getTeamDetails(widget.teamId);
      if (!mounted) return;
      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    } finally {
      hide();
    }
  }

  void fetchCurrentUser() async {
    try {
      final profile = await ApiProvider().getProfile();
      final u = profile.data?.userId ?? '';
      if (u.toString().isNotEmpty) setState(() => currentUserId = u.toString());
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          (details != null && (details!['players'] ?? []).isNotEmpty)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    final players = (details!['players'] ?? [])
                        .map<Map<String, dynamic>>(
                            (p) => Map<String, dynamic>.from(p))
                        .toList();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FantasyTeamBuilderScreen(
                            teamId: widget.teamId,
                            teamName: widget.teamName,
                            players: players,
                            requiredPlayers: 11)));
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text('Build Team'))
              : null,
      appBar: AppBar(
        title: Text(widget.teamName),
        actions: [
          if (details != null &&
              currentUserId != null &&
              details!['user'] != null &&
              details!['user']['id']?.toString() == currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // navigate to edit screen
                  final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              EditTeamScreen(teamDetails: details!)));
                  if (updated == true) fetchDetails();
                } else if (value == 'abandon') {
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text('Abandon Team'),
                            content: const Text(
                                'This will remove all players from your team. Proceed?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'))
                            ],
                          ));
                  if (ok == true) {
                    final success =
                        await ApiProvider().abandonTeam(widget.teamId);
                    if (success) {
                      if (context.mounted) {
                        AppNotification.showSuccess(
                          context,
                          title: 'Team Abandoned',
                          message: 'All players have been removed',
                        );
                      }
                      fetchDetails();
                    } else {
                      if (context.mounted) {
                        AppNotification.showError(
                          context,
                          title: 'Failed to Abandon Team',
                          message: 'Please try again',
                        );
                      }
                    }
                  }
                } else if (value == 'delete') {
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                            title: const Text('Delete Team'),
                            content: const Text(
                                'This will permanently delete the team. This cannot be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)))
                            ],
                          ));
                  if (ok == true) {
                    await performDeleteConfirmed(context);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Team')),
                const PopupMenuItem(
                    value: 'abandon', child: Text('Abandon Team')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Team',
                        style: TextStyle(color: Colors.red))),
              ],
            )
        ],
      ),
      body: isLoading
          ? const SizedBox.shrink()
          : details == null
              ? const Center(child: Text('Failed to load team details'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: Colors.grey.shade200,
                            child: details!['logo_url'] != null &&
                                    (details!['logo_url'] ?? '')
                                        .toString()
                                        .isNotEmpty
                                ? AvatarImage(
                                    imageUrl: details!['logo_url'],
                                    isCircle: true,
                                    sizeValue: 68,
                                    radius: 34,
                                    entityType: 'team',
                                  )
                                : const Icon(Icons.group, size: 34),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.teamName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                if (details!['user'] != null)
                                  Text(
                                      'Created by: ${details!['user']['name'] ?? details!['user']['email'] ?? ''}'),
                                const SizedBox(height: 4),
                                Text('Points: ${details!['points'] ?? '0'}'),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((details!['players'] ??
                              details!['player_ids'] ??
                              details!['player_list'] ??
                              [])
                          .isEmpty)
                        const Center(child: Text('No players available'))
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: (details!['players'] ??
                                    details!['player_ids'] ??
                                    details!['player_list'] ??
                                    [])
                                .length,
                            itemBuilder: (context, idx) {
                              final p = (details!['players'] ??
                                  details!['player_ids'] ??
                                  details!['player_list'])[idx];
                              final playerMap = p is Map
                                  ? p
                                  : {'id': p, 'name': p.toString()};
                              final name = (playerMap['name'] ??
                                      playerMap['title'] ??
                                      playerMap['player_name'] ??
                                      playerMap['full_name'] ??
                                      playerMap['playerName'] ??
                                      '')
                                  .toString();
                              final role = (playerMap['role'] ??
                                      playerMap['playing_role'] ??
                                      playerMap['position'] ??
                                      '')
                                  .toString();
                              final imageUrl = (playerMap['image_url'] ??
                                      playerMap['image'] ??
                                      playerMap['avatar'] ??
                                      '')
                                  .toString();
                              final pidVal = (playerMap['id'] ??
                                      playerMap['pid'] ??
                                      playerMap['player_id'] ??
                                      '')
                                  .toString();
                              final isCaptain = pidVal.isNotEmpty &&
                                  pidVal ==
                                      (details!['captain_id'] ??
                                              details!['captain'] ??
                                              details!['captainId'])
                                          .toString();
                              final isVice = pidVal.isNotEmpty &&
                                  pidVal ==
                                      (details!['vice_captain_id'] ??
                                              details!['vice_captain'] ??
                                              details!['viceCaptainId'])
                                          .toString();

                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCaptain
                                      ? Colors.orange
                                          .withAlpha((0.20 * 255).round())
                                      : isVice
                                          ? Colors.blueGrey
                                              .withAlpha((0.20 * 255).round())
                                          : null,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  leading: imageUrl.isNotEmpty
                                      ? Container(
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 2)),
                                          child: AvatarImage(
                                              imageUrl: imageUrl,
                                              isCircle: true,
                                              sizeValue: 44,
                                              radius: 22),
                                        )
                                      : CircleAvatar(
                                          child: Text(name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?')),
                                  title: Text(name),
                                  subtitle: Text(role),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isCaptain)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: const Text('C',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      if (isVice)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          margin:
                                              const EdgeInsets.only(right: 6),
                                          decoration: BoxDecoration(
                                              color: Colors.blueGrey,
                                              borderRadius:
                                                  BorderRadius.circular(6)),
                                          child: const Text('VC',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                    ],
                  ),
                ),
    );
  }
}
