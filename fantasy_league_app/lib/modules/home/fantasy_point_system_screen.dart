import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/themes.dart';

class fantasy_point_system_screen extends StatefulWidget {
  const fantasy_point_system_screen({super.key});

  @override
  _fantasy_point_system_screenState createState() =>
      _fantasy_point_system_screenState();
}

class _fantasy_point_system_screenState
    extends State<fantasy_point_system_screen> {
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
                          const Expanded(
                            child: Center(
                              child: Text(
                                'How to Play',
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
                  padding: const EdgeInsets.all(20),
                  children: [
                    instructionItem(
                      'What is Fantasy',
                      'Create a team of players and score points based on real match performance. Learn about scoring and substitutions here.',
                    ),
                    const SizedBox(height: 16),
                    instructionItem(
                      'Game',
                      'Choose the sport (cricket, football, kabaddi) and join contests to compete with others.',
                    ),
                    const SizedBox(height: 16),
                    instructionItem(
                      'Football',
                      'Select players for your football fantasy team and follow match-up scoring rules.',
                    ),
                    const SizedBox(height: 16),
                    instructionItem(
                      'Kabaddi',
                      'Pick raiders and defenders, track points for tackles and raids in kabaddi contests.',
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget instructionItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                color: AllCoustomTheme.getThemeData().primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                fontSize: 14,
                height: 1.5,
              ),
        ),
      ],
    );
  }
}
