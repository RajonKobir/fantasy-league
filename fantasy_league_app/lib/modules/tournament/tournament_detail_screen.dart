import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/modules/tournament/tournament_teams_screen.dart';
import 'package:fantasyleague/utils/avatar_image.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  const TournamentDetailScreen(
      {super.key, required this.tournamentId, required this.tournamentName});

  @override
  _TournamentDetailScreenState createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  Map<String, dynamic>? details;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    if (kDebugMode)
      debugPrint(
          '[TournamentDetail] initState called, tournamentId=${widget.tournamentId}');
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    if (kDebugMode)
      debugPrint(
          '[TournamentDetail] fetchDetails() called for ID: ${widget.tournamentId}');

    setState(() {
      isLoading = true;
      error = null;
    });

    late Timer timeoutTimer;
    try {
      if (kDebugMode)
        debugPrint(
            '[TournamentDetail] Starting API call for tournament ${widget.tournamentId}');

      // Set a 12-second timeout
      timeoutTimer = Timer(const Duration(seconds: 12), () {
        if (mounted && isLoading) {
          if (kDebugMode)
            debugPrint('[TournamentDetail] API timeout after 12s');
          setState(() {
            isLoading = false;
            error = 'Loading took too long. Please try again.';
          });
        }
      });

      final fetched =
          await ApiProvider().getTournamentDetails(widget.tournamentId);

      // Cancel the timeout since we got a response
      timeoutTimer.cancel();

      if (fetched == null) {
        if (kDebugMode)
          debugPrint('[TournamentDetail] Response was null, setting error');
        setState(() {
          details = null;
          error = 'Tournament not found or failed to load';
          isLoading = false;
        });
      } else {
        if (kDebugMode)
          debugPrint('[TournamentDetail] Got valid response, setting details');
        setState(() {
          details = fetched;
          error = null;
          isLoading = false;
        });
      }
    } catch (e, st) {
      if (kDebugMode)
        debugPrint('[TournamentDetail] Exception in fetchDetails: $e');
      if (kDebugMode) debugPrint('[TournamentDetail] Stack: $st');
      if (!mounted) {
        if (kDebugMode)
          debugPrint(
              '[TournamentDetail] Widget unmounted after exception, returning early');
        return;
      }
      setState(() {
        details = null;
        error = 'Failed to load tournament: ${e.toString()}';
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
      appBar: AppBar(title: Text(widget.tournamentName)),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : (details == null || error != null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error ?? 'Failed to load tournament',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text('Slide down to refresh',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500])),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tournament Header
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey.shade200,
                            child: details!['logo_url'] != null &&
                                    (details!['logo_url'] ?? '')
                                        .toString()
                                        .isNotEmpty
                                ? AvatarImage(
                                    imageUrl: details!['logo_url'],
                                    isCircle: true,
                                    sizeValue: 80,
                                    radius: 40,
                                    entityType: 'tournament',
                                  )
                                : const Icon(Icons.emoji_events, size: 40),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(details!['name'] ?? widget.tournamentName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if ((details!['description'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    details!['description'],
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 8),
                                if ((details!['entry_fee'] ?? 0)
                                        .toString()
                                        .isNotEmpty &&
                                    (double.tryParse(
                                                (details!['entry_fee'] ?? '0')
                                                    .toString()) ??
                                            0.0) >
                                        0) ...[
                                  Text(
                                    'Entry: ৳${(double.tryParse((details!['entry_fee'] ?? '0').toString()) ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  if ((details!['refund_percentage'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        'Refund: ${(double.tryParse((details!['refund_percentage'] ?? '0').toString()) ?? 0.0).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Button to browse teams
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentTeamsScreen(
                                  tournamentId: widget.tournamentId,
                                  tournamentName: widget.tournamentName,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.groups),
                          label: const Text('Select Team to Play'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${((details!['teams'] ?? []) as List).length} teams available',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
    );
  }
}
