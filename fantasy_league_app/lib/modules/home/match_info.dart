import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/models/match_info.dart';
import 'package:fantasyleague/models/schedule_response_data.dart';

import 'mach_timer_view.dart';

class MatchInfoScreen extends StatefulWidget {
  final ShedualData? shedualData;

  const MatchInfoScreen({super.key, this.shedualData});
  @override
  _MatchInfoScreenState createState() => _MatchInfoScreenState();
}

class _MatchInfoScreenState extends State<MatchInfoScreen> {
  bool isLoginProsses = false;
  var sheduallist = <ShedualInfoData>[];
  @override
  void initState() {
    getMatchInfo();
    super.initState();
  }

  Future<void> getMatchInfo() async {
    Timer? matchInfoTimer;
    try {
      setState(() => isLoginProsses = true);
      // Add 12s timeout for match info fetch
      matchInfoTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted || !isLoginProsses) return;
        setState(() => isLoginProsses = false);
      });
    } finally {
      matchInfoTimer?.cancel();
      if (mounted) setState(() => isLoginProsses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: AllCoustomTheme.getThemeData().primaryColor,
        ),
        SafeArea(
          child: Scaffold(
            backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
            appBar: AppBar(
              elevation: 0,
              title: Text(
                'Match Info',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color:
                      AllCoustomTheme.buildLightTheme().bottomAppBarTheme.color,
                ),
              ),
            ),
            body: ModalProgressHUD(
              inAsyncCall: isLoginProsses,
              color: Colors.transparent,
              progressIndicator: const CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
              child: Column(
                children: <Widget>[
                  matchSchedulData(),
                  Expanded(
                    child: matchInfoList(),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget matchInfoList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: sheduallist.length,
      itemBuilder: (context, index) {
        return Container(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(
                    right: 16, left: 16, top: 10, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Match',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].match.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Series',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].seriesName.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Date',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].dateStart.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Time',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].timeStart.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Venue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].venue.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'umpires',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].umpires.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Column(
                        children: <Widget>[
                          Text(
                            'referee',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    Flexible(
                      child: Column(
                        children: <Widget>[
                          Text(
                            sheduallist[index].referee.toString(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Location section removed
            ],
          ),
        );
      },
    );
  }

  Widget matchSchedulData() {
    return SizedBox(
      height: 40,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(top: 8, right: 16, left: 16),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CachedNetworkImage(
                    imageUrl: widget.shedualData!.teamLogo!.a!.logoUrl!,
                    placeholder: (context, url) => Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                    fit: BoxFit.contain,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    widget.shedualData!.teamLogo!.a!.shortName!,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  child: Text(
                    'vs',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE12,
                        color: AllCoustomTheme.getTextThemeColors()),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  child: Text(
                    widget.shedualData!.teamLogo!.b!.shortName!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 4),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CachedNetworkImage(
                      imageUrl: widget.shedualData!.teamLogo!.b!.logoUrl!,
                      placeholder: (context, url) => Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.error),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                TimerView(
                  dateStart: widget.shedualData!.dateStart,
                  timestart: widget.shedualData!.timeStart,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(),
          ),
          const Divider(
            height: 1,
          )
        ],
      ),
    );
  }
}
