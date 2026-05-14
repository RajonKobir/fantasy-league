import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/notification_service.dart';

class FantasyTeamBuilderScreen extends StatefulWidget {
  final String teamId; // source team id (from which players are listed)
  final String teamName;
  final List<Map<String, dynamic>>
      players; // list of player maps {id,name,image_url}
  final int
      requiredPlayers; // number of players required for the team (from tournament)

  // For tests: when true the SelectedPlayersScreen will skip confirmation dialog
  final bool skipConfirmationForTests;
  // For tests: optionally pre-select player IDs (avoids needing to tap each item)
  final List<int>? initialSelected;

  const FantasyTeamBuilderScreen(
      {Key? key,
      required this.teamId,
      required this.teamName,
      required this.players,
      this.requiredPlayers = 11,
      this.skipConfirmationForTests = false,
      this.initialSelected})
      : super(key: key);

  @override
  _FantasyTeamBuilderScreenState createState() =>
      _FantasyTeamBuilderScreenState();
}

class _FantasyTeamBuilderScreenState extends State<FantasyTeamBuilderScreen> {
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    // Apply any initial selections provided for tests
    if (widget.initialSelected != null) {
      _selected.addAll(widget.initialSelected!);
    }
  }

  void _toggle(int playerId) {
    setState(() {
      if (_selected.contains(playerId))
        _selected.remove(playerId);
      else {
        if (_selected.length < widget.requiredPlayers)
          _selected.add(playerId);
        else
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'You can only select ${widget.requiredPlayers} players')));
      }
    });
  }

  void _openSelected() async {
    final res = await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SelectedPlayersScreen(
            teamId: widget.teamId,
            teamName: widget.teamName,
            playerIds: _selected.toList(),
            players: widget.players,
            requiredPlayers: widget.requiredPlayers,
            skipConfirmation: widget.skipConfirmationForTests)));
    if (res == true) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submitted – waiting for admin approval')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Build: ${widget.teamName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
                'Select players (tap to toggle). ${_selected.length}/${widget.requiredPlayers}'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.players.length,
              itemBuilder: (context, idx) {
                final p = widget.players[idx];
                final id = (p['id'] ?? p['pid'] ?? 0) as int;
                final name = p['name'] ?? p['title'] ?? p['first_name'] ?? '';
                return CheckboxListTile(
                  value: _selected.contains(id),
                  title: Text(name.toString()),
                  secondary: (p['image_url'] != null && p['image_url'] != '')
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(p['image_url']))
                      : null,
                  onChanged: (_) => _toggle(id),
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSelected,
        label: Text('Selected (${_selected.length})'),
        icon: Icon(Icons.check),
      ),
    );
  }
}

class SelectedPlayersScreen extends StatefulWidget {
  final String teamId;
  final String teamName;
  final List<int> playerIds;
  final List<Map<String, dynamic>> players;
  final int requiredPlayers;

  const SelectedPlayersScreen(
      {Key? key,
      required this.teamId,
      required this.teamName,
      required this.playerIds,
      required this.players,
      this.requiredPlayers = 11,
      this.skipConfirmation = false})
      : super(key: key);

  // For tests: when true skip the confirmation dialog and submit immediately
  final bool skipConfirmation;

  @override
  _SelectedPlayersScreenState createState() => _SelectedPlayersScreenState();
}

class _SelectedPlayersScreenState extends State<SelectedPlayersScreen> {
  int? _captainId;
  int? _viceId;
  bool _submitting = false;

  List<Map<String, dynamic>> get selectedPlayers {
    final selectedMap = <int, Map<String, dynamic>>{};
    for (final player in widget.players) {
      final playerId = (player['id'] ?? player['pid']) as int?;
      if (playerId != null && widget.playerIds.contains(playerId)) {
        selectedMap[playerId] = player;
      }
    }
    // Return players in the order they were selected
    return widget.playerIds
        .map((id) => selectedMap[id])
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> _submitTeam() async {
    if (widget.playerIds.length != widget.requiredPlayers) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Select exactly ${widget.requiredPlayers} players')));
      return;
    }
    if (_captainId == null || _viceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a Captain and Vice-Captain')));
      return;
    }

    final nameController = TextEditingController(text: '${widget.teamName}');
    bool confirmed = true;
    if (!widget.skipConfirmation) {
      final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Submit Fantasy Team'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Enter a name for your fantasy team'),
                    TextField(controller: nameController)
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Submit'))
                ],
              ));
      confirmed = (result == true);
    }
    if (confirmed != true) return;

    setState(() => _submitting = true);
    Timer? submitTimeoutTimer;
    try {
      // Set a 15-second timeout to prevent button spinner from hanging
      submitTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() => _submitting = false);
          if (context.mounted) {
            AppNotification.showError(context,
                title: 'Request Timeout',
                message: 'Team submission timed out. Please try again.');
          }
        }
      });

      if (kDebugMode)
        debugPrint(
            'Submitting team: playerIds=${widget.playerIds}, captain=$_captainId, vice=$_viceId');
      final resp = await ApiProvider().createTeam(
          name: nameController.text,
          matchId: widget.teamId,
          playerIds: widget.playerIds.map((id) => id.toString()).toList(),
          captainId: _captainId!.toString(),
          viceCaptainId: _viceId!.toString());

      // Cancel timeout since we got a response
      submitTimeoutTimer.cancel();

      if (kDebugMode) debugPrint('Submit response: $resp');
      if (resp['success'] == 1 || resp['success'] == true) {
        if (context.mounted) {
          AppNotification.showSuccess(context,
              title: 'Submitted',
              message: 'Submitted ✓ waiting for admin approval');
        }
        // return to the root so user can see their teams
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      } else {
        final message =
            resp['message'] ?? resp['error'] ?? 'Failed to submit team';
        if (context.mounted) {
          AppNotification.showError(context,
              title: 'Submission Failed', message: message);
        }
        return;
      }
    } catch (e) {
      submitTimeoutTimer?.cancel();
      if (kDebugMode) debugPrint('Error in _submitTeam: $e');
      String errorMsg = e.toString();
      if (e is TimeoutException) {
        errorMsg = 'Team submission timed out. Please try again.';
      }
      if (context.mounted) {
        AppNotification.showError(context,
            title: 'Submission Failed', message: errorMsg);
      }
      // fall through
    } finally {
      submitTimeoutTimer?.cancel();
      if (mounted) setState(() => _submitting = false);
    }

    if (context.mounted) {
      AppNotification.showError(context,
          title: 'Submission Failed', message: 'Failed to submit team');
    }
  }

  @override
  void initState() {
    super.initState();
    // set default captain/vice if available
    if (widget.playerIds.isNotEmpty) {
      _captainId = widget.playerIds[0];
      _viceId = widget.playerIds.length > 1
          ? widget.playerIds[1]
          : widget.playerIds[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('Selected Players (${widget.playerIds.length})')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: selectedPlayers.length,
                itemBuilder: (context, idx) {
                  final p = selectedPlayers[idx];
                  final id = ((p['id'] ?? p['pid']) as int?) ?? 0;
                  if (id == 0) {
                    return SizedBox.shrink(); // Skip if no valid ID
                  }
                  return ListTile(
                    leading: (p['image_url'] != null && p['image_url'] != '')
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(p['image_url']))
                        : null,
                    title: Text(p['name'] ??
                        p['title'] ??
                        p['first_name'] ??
                        'Unknown Player'),
                    subtitle: Row(
                      children: [
                        // Using legacy Radio API; RadioGroup API introduced in newer Flutter versions.
                        // Suppress deprecation lint until a full migration to RadioGroup is implemented.
                        // ignore: deprecated_member_use
                        Radio<int?>(
                            value: id,
                            // ignore: deprecated_member_use
                            groupValue: _captainId,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _captainId = v)),
                        Text('Captain'),
                        SizedBox(width: 12),
                        // ignore: deprecated_member_use
                        Radio<int?>(
                            value: id,
                            // ignore: deprecated_member_use
                            groupValue: _viceId,
                            // ignore: deprecated_member_use
                            onChanged: (v) => setState(() => _viceId = v)),
                        Text('Vice')
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                  onPressed: _submitting ? null : _submitTeam,
                  child: _submitting
                      ? CircularProgressIndicator()
                      : Text('Submit Team'),
                ))
              ],
            )
          ],
        ),
      ),
    );
  }
}
