import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/notification_service.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';

class TournamentPlayersScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final String teamId;
  final String teamName;
  final int requiredPlayers;
  final num entryFee;
  final Set<String>? initialSelectedPlayerIds;
  final String? initialCaptainId;
  final String? initialViceCaptainId;
  final List<Map<String, dynamic>>?
      teamPlayers; // Pre-fetched players for this team

  const TournamentPlayersScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    required this.teamId,
    required this.teamName,
    required this.requiredPlayers,
    this.entryFee = 0,
    this.initialSelectedPlayerIds,
    this.initialCaptainId,
    this.initialViceCaptainId,
    this.teamPlayers, // Optional pre-fetched players
  });

  @override
  _TournamentPlayersScreenState createState() =>
      _TournamentPlayersScreenState();
}

class _TournamentPlayersScreenState extends State<TournamentPlayersScreen> {
  List<Map<String, dynamic>> players = [];
  List<Map<String, dynamic>> allPlayers =
      []; // cache of all players to resolve names across teams
  late Set<String> selectedPlayerIds;
  String? captainId;
  String? viceCaptainId;
  bool isLoading = true;
  bool isCreating = false;
  bool _loaderShown = false;
  Function()? _hideLoadingDialog;

  @override
  void initState() {
    super.initState();
    // Initialize with provided selections or empty
    selectedPlayerIds = Set.from(widget.initialSelectedPlayerIds ?? {});
    captainId = widget.initialCaptainId;
    viceCaptainId = widget.initialViceCaptainId;
    fetchPlayers();
  }

  List<Map<String, dynamic>> _normalizePlayers(List<Map<String, dynamic>> raw) {
    return raw.map((p) {
      final id = p['id'] ?? p['pid'] ?? p['player_id'];
      final team =
          p['team'] ?? p['team_name'] ?? p['teamId'] ?? p['team_id'] ?? '';
      final name =
          p['name'] ?? p['full_name'] ?? p['title'] ?? p['short_name'] ?? '';
      final role = p['role'] ?? p['playing_role'] ?? p['position'] ?? '';
      return {
        ...p,
        'id': id,
        'team': team,
        'name': name,
        'role': role,
      };
    }).toList();
  }

  void fetchPlayers() async {
    // If players were passed in, normalize and use them directly, but always try to populate the global player cache
    if (widget.teamPlayers != null && widget.teamPlayers!.isNotEmpty) {
      final normalized = _normalizePlayers(
          List<Map<String, dynamic>>.from(widget.teamPlayers!));
      setState(() {
        players = normalized;
        // Also seed the local allPlayers cache so preview/creation doesn't trigger network
        allPlayers = normalized;
        isLoading = false;
      });
      // populate global cache in background (non-blocking)
      ApiProvider().getPlayers().then((fetched) {
        if (!mounted) return;
        setState(() {
          allPlayers =
              _normalizePlayers(List<Map<String, dynamic>>.from(fetched));
        });
      }).catchError((error) {
        if (kDebugMode)
          debugPrint(
              'Error fetching all players for cache: ${error.toString()}');
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Fallback: Fetch all available players and filter by team
      final List<Map<String, dynamic>> fetchedRaw =
          await ApiProvider().getPlayers();

      if (!mounted) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Normalize and cache all players for name lookups across teams
      final fetched =
          _normalizePlayers(List<Map<String, dynamic>>.from(fetchedRaw));
      allPlayers = fetched;

      // Filter players by team name (e.g., "India", "Pakistan", etc.)
      final filteredPlayers = fetched.where((player) {
        final playerTeam = player['team'] ?? '';
        return playerTeam.toString().toLowerCase() ==
            widget.teamName.toLowerCase();
      }).toList();

      setState(() {
        players = filteredPlayers;
        isLoading = false;
        // If a modal loader was shown in build, hide it now
        if (_loaderShown && _hideLoadingDialog != null) {
          _hideLoadingDialog!();
          _hideLoadingDialog = null;
          _loaderShown = false;
        }
      });
    } catch (e, stack) {
      if (kDebugMode) debugPrint('Error loading players: ${e.toString()}');
      if (kDebugMode) debugPrint('Stack trace: $stack');
      if (!mounted) {
        // Defensive: ensure spinner is stopped if widget is unmounted
        return;
      }
      setState(() {
        isLoading = false;
      });
      if (context.mounted) {
        AppNotification.showError(
          context,
          title: 'Error Loading Players',
          message: e.toString(),
        );
      }
    }
  }

  void togglePlayer(String id) {
    setState(() {
      if (selectedPlayerIds.contains(id)) {
        selectedPlayerIds.remove(id);
        if (captainId == id) captainId = null;
        if (viceCaptainId == id) viceCaptainId = null;
      } else {
        if (selectedPlayerIds.length < widget.requiredPlayers) {
          selectedPlayerIds.add(id);
        } else {
          AppNotification.showWarning(
            context,
            title: 'Player Limit Reached',
            message: 'Maximum ${widget.requiredPlayers} players allowed',
          );
        }
      }
    });
  }

  /// Ensure we have player records for the given ids in the local cache (`allPlayers`).
  /// Shows a blocking loading dialog while fetching if needed.
  Future<void> _ensurePlayersCachedForIds(Set<String> ids) async {
    // Determine which ids are missing from the cache
    final missing = ids.where((id) {
      return !allPlayers.any((p) {
        final pid = (p['id'] ?? p['pid'] ?? p['player_id'] ?? '').toString();
        return pid == id;
      });
    }).toList();

    if (missing.isEmpty) return;

    // Show a small blocking progress dialog while we fetch (auto-dismisses on timeout)
    final hideLoader =
        await showTimedLoader(context, timeout: const Duration(seconds: 10));
    final fetchTimeout = const Duration(seconds: 10);
    try {
      final fetched = await ApiProvider().getPlayers().timeout(fetchTimeout);
      if (!mounted) return;
      setState(() {
        // Normalize fetched players so `name` and `team` fields are available
        allPlayers =
            _normalizePlayers(List<Map<String, dynamic>>.from(fetched));
      });
    } on TimeoutException {
      if (context.mounted) {
        AppNotification.showError(context,
            title: 'Timeout',
            message: 'Fetching players took too long. Please try again.');
      }
    } catch (e) {
      // Non-fatal: show an error but continue (preview will show Unknown if still missing)
      if (context.mounted) {
        AppNotification.showError(context,
            title: 'Player Fetch Failed', message: e.toString());
      }
    } finally {
      // Ensure loader is dismissed
      hideLoader();
    }
  }

  Future<void> onCreateTeam() async {
    Function()? hideLoader;
    if (selectedPlayerIds.length != widget.requiredPlayers) {
      AppNotification.showWarning(
        context,
        title: 'Invalid Selection',
        message: 'Please select exactly ${widget.requiredPlayers} players',
      );
      return;
    }
    if (captainId == null || viceCaptainId == null) {
      AppNotification.showWarning(
        context,
        title: 'Select Captain',
        message: 'Please select captain and vice-captain',
      );
      return;
    }

    String name = '';
    final teamNameController = TextEditingController();
    // Ask for team name first
    final nameOk = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: TextField(
          controller: teamNameController,
          decoration: const InputDecoration(labelText: 'Team name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (teamNameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter team name')));
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Continue')),
        ],
      ),
    );

    if (nameOk != true) return;

    name = teamNameController.text.trim();

    // Ensure we have player names available before showing the preview (to avoid Unknown Player)
    await _ensurePlayersCachedForIds(selectedPlayerIds);

    // Show a preview dialog so user can confirm selected players, captain and vice
    final previewOk = await showDialog<bool>(
        context: context,
        builder: (context) {
          // Helper to find player name robustly by id and include team in parentheses when available
          String findPlayerDisplayNameById(String id) {
            String name = '';
            String team = '';

            // Search global cache first
            for (var pp in allPlayers) {
              final pid =
                  (pp['id'] ?? pp['pid'] ?? pp['player_id'] ?? '').toString();
              if (pid == id) {
                name = (pp['name'] ?? pp['full_name'] ?? pp['title'] ?? '')
                    .toString();
                team = (pp['team'] ?? pp['team_name'] ?? '').toString();
                break;
              }
            }

            // Fallback to team-specific players
            if (name.isEmpty) {
              for (var pp in players) {
                final pid =
                    (pp['id'] ?? pp['pid'] ?? pp['player_id'] ?? '').toString();
                if (pid == id) {
                  name = (pp['name'] ?? pp['full_name'] ?? pp['title'] ?? '')
                      .toString();
                  team = (pp['team'] ?? pp['team_name'] ?? '').toString();
                  break;
                }
              }
            }

            // If still not found, return a neutral label without implying a particular team
            if (name.isEmpty) return 'Unknown Player ($id)';

            if (team.isNotEmpty) {
              return '$name ($team)';
            }
            return name;
          }

          final selectedPlayers = selectedPlayerIds.map((id) {
            final displayName = findPlayerDisplayNameById(id);
            return {'id': id, 'displayName': displayName};
          }).toList();

          return AlertDialog(
            title: const Text('Preview Team'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: double.maxFinite),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Info Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Team Name: $name',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('Tournament: ${widget.tournamentName}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          // Removed explicit single-team label because fantasy teams can include players
                          // from multiple teams. If you want, we can show a list of unique teams.
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Players List Label
                    Text('Selected Players (${selectedPlayers.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    // Players List
                    ...selectedPlayers.map((sp) {
                      final isC = captainId == sp['id'];
                      final isV = viceCaptainId == sp['id'];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  (sp['displayName'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isC)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: const Text('C',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11)),
                                    ),
                                  if (isV)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 3),
                                      margin: const EdgeInsets.only(left: 4),
                                      decoration: BoxDecoration(
                                          color: Colors.blueGrey,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: const Text('VC',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm')),
            ],
          );
        });

    if (previewOk != true) return;

    // Confirm entry fee with the user if applicable
    if (widget.entryFee > 0) {
      final feeConfirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirm Entry Fee'),
          content: Text(
              'This tournament requires an entry fee of ৳${widget.entryFee}. Do you want to proceed?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes')),
          ],
        ),
      );
      if (feeConfirmed != true) return;
    }

    setState(() => isCreating = true);

    // Show a blocking 'creating' dialog with auto-timeout
    hideLoader =
        await showTimedLoader(context, timeout: const Duration(seconds: 10));

    // Defensive validation: ensure all selected player IDs parse to valid ints
    final intPlayerIds = selectedPlayerIds
        .map((s) => int.tryParse(s.toString()) ?? 0)
        .where((i) => i > 0)
        .toList();
    if (intPlayerIds.length != selectedPlayerIds.length) {
      try {
        hideLoader();
      } catch (_) {}
      setState(() => isCreating = false);
      AppNotification.showError(
        context,
        title: 'Invalid Player IDs',
        message:
            'Some selected players have invalid IDs. Please reselect the players and try again.',
      );
      return;
    }

    try {
      if (kDebugMode)
        debugPrint(
            '[TournamentPlayers] Creating team for tournament ${widget.tournamentId} with players ${selectedPlayerIds.toList()}');

      // Apply a hard timeout to the network call so it cannot hang indefinitely
      final resp = await ApiProvider()
          .createTeam(
            name: name,
            playerIds: selectedPlayerIds.toList(),
            captainId: captainId!,
            viceCaptainId: viceCaptainId!,
            tournamentId: widget.tournamentId,
            teamId: widget.teamId,
          )
          .timeout(const Duration(seconds: 15));

      // Log full response for debugging
      try {
        if (kDebugMode)
          debugPrint(
              '[TournamentPlayers] createTeam response: ${jsonEncode(resp)}');
      } catch (_) {}

      if (resp['success'] == true || resp['success'] == 1) {
        if (context.mounted) {
          AppNotification.showSuccess(
            context,
            title: 'Success',
            message: 'Team created successfully',
          );

          // Refresh user summary (profile + wallet) so UI shows updated wallet balance
          try {
            final profile = await ApiProvider().getProfile();
            final wallet = await ApiProvider().getWallet();

            final Map<String, dynamic> summary = {
              'profile': profile.data?.toJson() ?? {},
              'wallet': wallet,
              'fetched_at': DateTime.now().toIso8601String(),
            };

            await MySharedPreferences().setCacheJson('user_summary', summary);
            if (profile.data != null)
              await MySharedPreferences().setUserDataString(profile.data!);
            UserSummaryNotifier.update(summary);
          } catch (e) {
            if (kDebugMode)
              debugPrint('Error updating user summary after team creation: $e');
          }

          // Dismiss the creation dialog first (if shown) before navigating away
          try {
            hideLoader();
          } catch (_) {}
          // Then pop this screen to return to previous
          Navigator.pop(context);
        }
      } else {
        // Include backend error details when available to aid debugging
        String msg = resp['message'] ?? 'Failed to create team';

        // If validation errors are provided, build a concise message for the user
        if (resp['errors'] != null && resp['errors'] is Map) {
          try {
            final Map<String, dynamic> errors =
                Map<String, dynamic>.from(resp['errors']);
            final flattened = errors.entries
                .map((e) => (e.value is List)
                    ? (e.value as List).join(', ')
                    : e.value.toString())
                .toList();
            if (flattened.isNotEmpty) {
              msg = '$msg: ${flattened.join(' | ')}';
            }
          } catch (_) {}
        }

        if (resp['error'] != null && resp['error'].toString().isNotEmpty) {
          msg = '$msg: ${resp['error']}';
          if (kDebugMode)
            debugPrint(
                '[TournamentPlayers] createTeam backend error: ${resp['error']}');
        }

        try {
          hideLoader();
        } catch (_) {}

        if (context.mounted) {
          // Show the server message and also suggest checking server logs
          AppNotification.showError(
            context,
            title: 'Creation Failed',
            message: msg,
          );

          // Do not show verbose debug dialogs to users. Developers can use logs for debugging.
          // For development builds, use logging only (no dialog) to avoid exposing stack traces to users.
          if (kDebugMode) {
            try {
              if (kDebugMode)
                debugPrint(
                    '[TournamentPlayers] createTeam response: ${jsonEncode(resp)}');
            } catch (_) {}
          }
        }
      }
      // Cancel any creation timer
      // No timer to cancel since _creationTimeoutFuture is removed
    } catch (e, st) {
      if (kDebugMode)
        debugPrint('[TournamentPlayers] createTeam exception: $e');
      if (kDebugMode) debugPrint('[TournamentPlayers] createTeam stack: $st');

      try {
        hideLoader();
      } catch (_) {}

      if (context.mounted) {
        // Show a concise, user-friendly message instead of raw exception text
        AppNotification.showError(
          context,
          title: 'Network Error',
          message:
              'Network error occurred while creating team. Please try again.',
        );
      }
      // No timer to cancel since _creationTimeoutFuture is removed
    } finally {
      // Ensure loader is dismissed and isCreating flag is cleared in all cases
      try {
        hideLoader();
      } catch (_) {}
      setState(() => isCreating = false);
    }
  }

  bool _canSubmit() {
    return selectedPlayerIds.length == widget.requiredPlayers &&
        captainId != null &&
        viceCaptainId != null;
  }

  void _setCaptain(String playerId) {
    setState(() {
      if (captainId == playerId) {
        captainId = null;
      } else {
        captainId = playerId;
        if (viceCaptainId == captainId) viceCaptainId = null;
      }
    });
  }

  void _setViceCaptain(String playerId) {
    setState(() {
      if (viceCaptainId == playerId) {
        viceCaptainId = null;
      } else {
        viceCaptainId = playerId;
        if (captainId == viceCaptainId) captainId = null;
      }
    });
  }

  Future<void> _submitTeam() async {
    await onCreateTeam();
  }

  @override
  Widget build(BuildContext context) {
    // If loading and modal loader not yet shown, show timed modal loader
    if (isLoading && !_loaderShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        _loaderShown = true;
        _hideLoadingDialog = await showTimedLoader(context,
            timeout: const Duration(seconds: 12));
      });
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default back button
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select ${widget.requiredPlayers} Players'),
            Text(
              widget.tournamentName,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          // Button to browse other teams
          GestureDetector(
            onTap: () {
              // Return selections to parent
              Navigator.pop(context, {
                'selectedPlayerIds': selectedPlayerIds,
                'captainId': captainId,
                'viceCaptainId': viceCaptainId,
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.people,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Other Teams',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const SizedBox.shrink()
          : Column(
              children: [
                // Selection Counter and Team Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCounter('Selected', selectedPlayerIds.length,
                              widget.requiredPlayers),
                          _buildCounter(
                              'Captain', captainId != null ? 1 : 0, 1),
                          _buildCounter(
                              'Vice-Capt', viceCaptainId != null ? 1 : 0, 1),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // Players List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final p = players[index];
                      final playerId = p['id'].toString();
                      final playerName = p['name'] ?? 'Player';
                      final playerTeam = (p['team'] ?? 'No Team').toString();
                      final playerRole = p['role'] ?? 'Role Unknown';
                      final isSelected = selectedPlayerIds.contains(playerId);
                      final isCaptain = captainId == playerId;
                      final isViceCaptain = viceCaptainId == playerId;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (_) => togglePlayer(playerId),
                          ),
                          title: Text(
                            playerName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerTeam,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                playerRole,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'captain') {
                                      _setCaptain(playerId);
                                    } else if (value == 'vice') {
                                      _setViceCaptain(playerId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'captain',
                                      child: Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: isCaptain
                                                  ? Colors.orange
                                                  : Colors.grey,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Captain'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'vice',
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_half,
                                              color: isViceCaptain
                                                  ? Colors.blue
                                                  : Colors.grey,
                                              size: 20),
                                          const SizedBox(width: 8),
                                          const Text('Vice-Captain'),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () => togglePlayer(playerId),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submitTeam : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _canSubmit()
                    ? 'Create Fantasy Team'
                    : 'Select ${widget.requiredPlayers} players & set captain (${selectedPlayerIds.length}/${widget.requiredPlayers})',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int current, int max) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: current >= max ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$current/$max',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
