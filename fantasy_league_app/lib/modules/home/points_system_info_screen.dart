import 'package:flutter/material.dart';
// import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';

class PointsSystemInfoScreen extends StatelessWidget {
  const PointsSystemInfoScreen({super.key});

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 20)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AllCoustomTheme.getThemeData().primaryColor,
            AllCoustomTheme.getThemeData().primaryColor,
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
          body: Column(
            children: <Widget>[
              Container(
                color: AllCoustomTheme.getThemeData().primaryColor,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: AppBar().preferredSize.height,
                      child: Row(
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: SizedBox(
                                width: AppBar().preferredSize.height,
                                height: AppBar().preferredSize.height,
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: const Text(
                                'Points System',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: AppBar().preferredSize.height,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'How points are calculated for players',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    bullet(
                        'Batsman: Points awarded for runs scored, boundaries (4/6), strike rate bonuses or penalties based on performance.'),
                    bullet(
                        'Bowler: Points for wickets taken, maiden overs, economy based bonuses/penalties, and wickets in powerplay/late overs adjustments.'),
                    bullet(
                        'All-rounder: Combination of batting and bowling points when contributing in both disciplines.'),
                    bullet(
                        'Fielding: Points for catches, stumpings and run-outs.'),
                    bullet(
                        'Captain / Vice-captain: Captain earns 2x points and Vice-captain earns 1.5x points for the match.'),
                    bullet(
                        'Match-specific rules: Some matches or tournaments may have adjusted point rules; admin can update scoring rules in settings.'),
                    const SizedBox(height: 12),
                    const Text(
                      'Notes',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    bullet(
                        'Points are computed from official match events and aggregated to update fantasy team totals.'),
                    bullet(
                        'Final scores are calculated after match completion and are subject to verification.'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
