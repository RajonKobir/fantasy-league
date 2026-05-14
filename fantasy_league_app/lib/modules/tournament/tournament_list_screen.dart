import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:fantasyleague/modules/tournament/tournament_detail_screen.dart';
import 'package:fantasyleague/utils/avatar_image.dart';

class TournamentListScreen extends StatefulWidget {
  @override
  _TournamentListScreenState createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  List<Map<String, dynamic>> tournaments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTournaments();
  }

  void fetchTournaments() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final hide =
        await showTimedLoader(context, timeout: const Duration(seconds: 12));
    try {
      final fetched = await ApiProvider().getTournaments();
      if (!mounted) return;
      setState(() {
        tournaments = fetched;
        isLoading = false;
        if (fetched.isEmpty) {
          errorMessage = 'No tournaments available';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load tournaments: $e';
      });
    } finally {
      hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tournaments'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchTournaments,
          )
        ],
      ),
      body: isLoading
          ? const SizedBox.shrink()
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      Text('Tap refresh icon above or slide down to try again',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center)
                    ],
                  ),
                )
              : tournaments.isEmpty
                  ? Center(
                      child: Text('No tournaments available'),
                    )
                  : ListView.builder(
                      itemCount: tournaments.length,
                      itemBuilder: (context, index) {
                        final t = tournaments[index];
                        final logo =
                            (t['logo_url'] ?? t['logo'] ?? '').toString();
                        return ListTile(
                          leading: logo.isNotEmpty
                              ? AvatarImage(
                                  imageUrl: logo,
                                  sizeValue: 40,
                                  radius: 20,
                                  isCircle: true,
                                  entityType: 'tournament',
                                )
                              : Icon(Icons.emoji_events),
                          title: Text(t['name'] ?? 'Tournament'),
                          subtitle: Text(
                              '${t['start_at'] ?? ''} ${t['end_at'] ?? ''} - Entry: ${t['entry_fee'] ?? 0}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TournamentDetailScreen(
                                    tournamentId: (t['id'] ?? '').toString(),
                                    tournamentName: t['name'] ?? ''),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
