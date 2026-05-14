import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
import 'package:fantasyleague/modules/home/winners.dart';
import 'package:fantasyleague/modules/my_profile/my_profile_screen.dart';
import 'package:fantasyleague/modules/my_teams/my_teams_screen.dart';
import 'package:fantasyleague/services/notification_service.dart';
import 'home_screen.dart';
import 'more_screen.dart';
import 'package:fantasyleague/constance/global.dart' as global;

class TabScreen extends StatefulWidget {
  final BuildContext? menuScreenContext;
  const TabScreen({super.key, this.menuScreenContext});

  @override
  _TabScreenState createState() => _TabScreenState();
}

class _TabScreenState extends State<TabScreen> {
  PersistentTabController? _controller;
  int currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late bool hideNavBar = false;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController();
    global.isHideTabBar = hideNavBar = false;
    home_screen(
      menuCallBack: () {
        _scaffoldKey.currentState!.openEndDrawer();
      },
    );
  }

  List<Widget> _buildScreens() {
    return [
      home_screen(
        menuCallBack: () {
          _scaffoldKey.currentState!.openEndDrawer();
        },
      ),
      MyTeamsScreen(
        menuCallBack: () {
          _scaffoldKey.currentState!.openEndDrawer();
        },
      ),
      const MyProfileScreen(),
      const Winners(),
      MoreScreen(inviteFriendClick: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) => uderGroundDrawer(),
        );
      }),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(
          FontAwesomeIcons.house,
          size: 18,
        ),
        title: "home",
        activeColorPrimary: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        inactiveColorPrimary: Colors.white70,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
          fontSize: ConstanceData.SIZE_TITLE10,
          fontWeight: FontWeight.w600,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(
          FontAwesomeIcons.trophy,
          size: 18,
        ),
        title: ("My Teams"),
        activeColorPrimary: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        inactiveColorPrimary: Colors.white70,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
          fontSize: ConstanceData.SIZE_TITLE10,
          fontWeight: FontWeight.w600,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(
          FontAwesomeIcons.user,
          size: 18,
        ),
        title: "My Details",
        activeColorPrimary: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        inactiveColorPrimary: Colors.white70,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
          fontSize: ConstanceData.SIZE_TITLE10,
          fontWeight: FontWeight.w600,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(
          Icons.military_tech,
          size: 26,
        ),
        title: ("Winners"),
        activeColorPrimary: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        inactiveColorPrimary: Colors.white70,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
          fontSize: ConstanceData.SIZE_TITLE10,
          fontWeight: FontWeight.w600,
        ),
      ),
      PersistentBottomNavBarItem(
        icon: StreamBuilder<int>(
          stream: NotificationService().unreadCountStream,
          initialData: 0,
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            return Stack(
              children: [
                const Icon(
                  FontAwesomeIcons.gear,
                  size: 18,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        title: ("Info & More"),
        activeColorPrimary: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        inactiveColorPrimary: Colors.white70,
        textStyle: TextStyle(
          fontFamily: 'Poppins',
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
          fontSize: ConstanceData.SIZE_TITLE10,
          fontWeight: FontWeight.w600,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: global.themeNotifier,
      builder: (context, child) {
        // Rebuild the scaffold + persistent nav when the theme changes so the Home screen reflects the new color immediately.
        return Scaffold(
          key: _scaffoldKey,
          drawer: SizedBox(
            width: MediaQuery.of(context).size.width * 0.75,
            child: AppDrawer(
              mySettingClick: () {
                setState(() {
                  currentIndex = 2;
                  _buildScreens();
                });
              },
              referralClick: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) => uderGroundDrawer(),
                );
              },
            ),
          ),
          body: PersistentTabView(
            context,
            key: ValueKey(global.themeNotifier.changeCount),
            controller: _controller!,
            screens: _buildScreens(),
            items: _navBarsItems(),
            // Force the bottom nav background to follow the current primary theme
            // so the top strip and middle icon area match the app theme.
            backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
            handleAndroidBackButtonPress: true,
            resizeToAvoidBottomInset: true,
            hideNavigationBarWhenKeyboardAppears: true,

            // NEW parameter replacing hideNavigationBar & itemAnimationProperties
            animationSettings: const NavBarAnimationSettings(
              navBarItemAnimation: ItemAnimationSettings(
                duration: Duration(milliseconds: 400),
                curve: Curves.ease,
              ),
              screenTransitionAnimation: ScreenTransitionAnimationSettings(
                animateTabTransition: true,
                duration: Duration(milliseconds: 200),
                screenTransitionAnimationType:
                    ScreenTransitionAnimationType.fadeIn,
              ),
            ),
            // Use a style that always shows labels and works well with our
            // forced color scheme so the icon text remains visible.
            navBarStyle: NavBarStyle.style6,
            navBarHeight: 56.0,
            decoration: NavBarDecoration(
              // Force the color behind the nav bar to the primary color so
              // the bottom middle menu visually matches the selected theme.
              colorBehindNavBar: AllCoustomTheme.getThemeData().primaryColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -1),
                  blurRadius: 8,
                ),
              ],
              borderRadius: BorderRadius.zero,
            ),
          ),
        );
      },
    );
  }

  Widget uderGroundDrawer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.only(top: 4),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(
                height: 15,
              ),
              Text(
                "Kick off your friend's Fixturers journey!",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                  fontWeight: FontWeight.bold,
                  fontSize: ConstanceData.SIZE_TITLE16,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "For every friend that plays, you both get 100 for free!",
                textAlign: TextAlign.justify,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AllCoustomTheme.getTextThemeColors(),
                  fontSize: ConstanceData.SIZE_TITLE14,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Divider(
                height: 1,
              ),
              const SizedBox(
                height: 15,
              ),
              Text(
                'SHARE YOUR INVITE CODE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AllCoustomTheme.getBlackAndWhiteThemeColors()
                      .withValues(alpha: 52 / 255),
                  fontSize: ConstanceData.SIZE_TITLE12,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "How it works",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AllCoustomTheme.getThemeData().primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: ConstanceData.SIZE_TITLE14,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 128 / 255),
                    ),
                  ),
                  InkWell(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        "Rules of FairPlay",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AllCoustomTheme.getThemeData().primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: ConstanceData.SIZE_TITLE14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 15,
              ),
              const Divider(
                height: 1,
              ),
              Text(
                'Game123',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                  fontWeight: FontWeight.bold,
                  fontSize: ConstanceData.SIZE_TITLE20,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  // Share.share('check out my website https://example.com');
                },
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 4, bottom: 4),
                  decoration: BoxDecoration(
                    color: AllCoustomTheme.getThemeData().colorScheme.surface,
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: Colors.green,
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 51 / 255),
                          offset: const Offset(0, 1),
                          blurRadius: 5.0),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Share Code'.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.green,
                        fontSize: ConstanceData.SIZE_TITLE12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
