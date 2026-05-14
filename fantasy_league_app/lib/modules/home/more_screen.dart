import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
// import 'package:fantasyleague/modules/contests/contest_code_screen.dart';
import 'package:fantasyleague/modules/home/fantasy_point_system_screen.dart';
import 'package:fantasyleague/modules/home/points_system_info_screen.dart';
import 'package:fantasyleague/modules/home/about_us_screen.dart';
import 'package:fantasyleague/modules/home/legality_screen.dart';
import 'package:fantasyleague/modules/home/terms_and_conditions_screen.dart';
// import 'package:fantasyleague/modules/pyment_options/account_verification.dart';
// import 'package:fantasyleague/modules/settings/settings_screen.dart';

// Enum for AppBar behavior modes
enum AppBarBehaviorType { pinned, floating, snapping }

class MoreScreen extends StatefulWidget {
  final VoidCallback? inviteFriendClick;

  const MoreScreen({super.key, this.inviteFriendClick});
  @override
  _MoreScreenState createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final double _appBarHeight = 100.0;
  final AppBarBehaviorType _appBarBehavior = AppBarBehaviorType.pinned;
  bool isVerifiled = false;
  bool isProsses = false;

  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() async {
    var emialApproved = false;

    setState(() {
      isProsses = true;
    });
    var email = await ApiProvider().getEmailResponce();

    if ('Your E-mail and Mobile Number are Verified.' == email['message']) {
      emialApproved = true;
    }

    // Only email verification required (bank and pancard features removed)
    if (emialApproved) {
      isVerifiled = true;
    }
    setState(() {
      isProsses = false;
    });
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
            drawer: AppDrawer(
              mySettingClick: () {},
              referralClick: () {},
            ),
            backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
            body: Stack(
              children: <Widget>[
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverAppBar(
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      expandedHeight: _appBarHeight,
                      pinned: _appBarBehavior == AppBarBehaviorType.pinned,
                      floating:
                          _appBarBehavior == AppBarBehaviorType.floating ||
                              _appBarBehavior == AppBarBehaviorType.snapping,
                      snap: _appBarBehavior == AppBarBehaviorType.snapping,
                      backgroundColor:
                          AllCoustomTheme.getThemeData().primaryColor,
                      primary: true,
                      centerTitle: false,
                      flexibleSpace: sliverText(),
                      elevation: 1,
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => listItems(index),
                        childCount: 5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget sliverText() {
    return const FlexibleSpaceBar(
      centerTitle: false,
      titlePadding: EdgeInsetsDirectional.only(start: 16, bottom: 8, top: 0),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Info & More',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget listItems(int index) {
    if (index == 0) {
      // Points System
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PointsSystemInfoScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Points System",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                              .withValues(alpha: 200),
                        ),
                      ),
                    ),
                    Container(
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        size: ConstanceData.SIZE_TITLE22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      );
    } else if (index == 1) {
      // How to Play
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const fantasy_point_system_screen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "How to Play",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                              .withValues(alpha: 200),
                        ),
                      ),
                    ),
                    Container(
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        size: ConstanceData.SIZE_TITLE22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      );
    } else if (index == 2) {
      // About Us
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AboutUsScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "About Us",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                              .withValues(alpha: 200),
                        ),
                      ),
                    ),
                    Container(
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        size: ConstanceData.SIZE_TITLE22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      );
    } else if (index == 3) {
      // Legality
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LegalityScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Legality",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                              .withValues(alpha: 200),
                        ),
                      ),
                    ),
                    Container(
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        size: ConstanceData.SIZE_TITLE22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      );
    } else if (index == 4) {
      // Terms and Conditions
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TermsAndConditionsScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Container(
          child: Column(
            children: <Widget>[
              Container(
                height: 50,
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        "Terms and Conditions",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                              .withValues(alpha: 200),
                        ),
                      ),
                    ),
                    Container(
                      child: const Icon(
                        Icons.keyboard_arrow_right,
                        size: ConstanceData.SIZE_TITLE22,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
