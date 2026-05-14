import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fantasyleague/api/logout.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/main.dart';
import 'package:fantasyleague/modules/color/set_color.dart';
import 'package:fantasyleague/modules/notification/notification_screen.dart';
import 'package:fantasyleague/modules/payment_request/payment_request_screen.dart';
import 'package:fantasyleague/modules/my_profile/my_profile_screen.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class AppDrawer extends StatefulWidget {
  final VoidCallback? mySettingClick;
  final VoidCallback? referralClick;

  const AppDrawer({super.key, this.mySettingClick, this.referralClick});
  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool isLoginProsses = false;

  UserData? userData;
  Map<String, dynamic>? walletData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen for background updates to the cached user summary
    UserSummaryNotifier.notifier.addListener(_onSummaryUpdate);
  }

  void _loadUserData() async {
    // Prefer cached user_summary so drawer shows immediately after home background fetch
    try {
      final cached = await MySharedPreferences().getCacheJson('user_summary');
      if (cached != null) {
        try {
          final profileMap = Map<String, dynamic>.from(cached['profile'] ?? {});
          if (profileMap.isNotEmpty) {
            userData = UserData.fromJson(profileMap);
          }
        } catch (e) {
          // ignore malformed profile
        }
        try {
          walletData = Map<String, dynamic>.from(cached['wallet'] ?? {});
        } catch (e) {
          walletData = null;
        }
        setState(() {});
        return;
      }
    } catch (e) {
      // ignore cache read errors
    }

    // Fallback to older user data storage
    userData = await MySharedPreferences().getUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      child: Column(
        children: <Widget>[
          Container(
            color: AllCoustomTheme.getThemeData().primaryColor,
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: MediaQuery.of(context).padding.top,
                ),
                userDetail(),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: <Widget>[
                    myNotification(),
                    const Divider(
                      height: 1,
                    ),
                    myBalance(),
                    const Divider(
                      height: 1,
                    ),
                    poinSystem(),
                    const Divider(
                      height: 1,
                    ),
                    setThemeMode(),
                    const Divider(
                      height: 1,
                    ),
                    logoutButton(),
                    const Divider(
                      height: 1,
                    ),
                    const Expanded(child: SizedBox()),
                    const Text(
                      'v 1.2',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget userDetail() {
    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Back chevron on the far left
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.only(right: 12.0),
                child: const Icon(
                  FontAwesomeIcons.chevronLeft,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ),

            // Avatar on the left
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 64,
                height: 64,
                child: AvatarImage(
                  isCircle: true,
                  imageUrl: userData?.image ?? '',
                  radius: 64,
                  sizeValue: 64,
                  entityType: 'user',
                ),
              ),
            ),

            // Name and optional subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    userData?.name?.isNotEmpty == true
                        ? userData!.name!
                        : 'Guest',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      // navigate to profile details
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProfileScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'My Details',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE12,
                        color: Colors.white.withAlpha((0.9 * 255).round()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget myNotification() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const notification_screen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Icon(
                    FontAwesomeIcons.solidBell,
                    size: 22,
                    color: AllCoustomTheme.getThemeData().primaryColor,
                  ),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Text(
                  'Notification',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AllCoustomTheme.getThemeData().primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myBalance() {
    return SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 14),
        child: Row(
          children: <Widget>[
            Container(
              child: Icon(
                FontAwesomeIcons.wallet,
                color: AllCoustomTheme.getThemeData().primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: Container(
                child: Text(
                  'My Balance',
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AllCoustomTheme.getThemeData().primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Display cached balance as small single-line text to avoid overflow
                Padding(
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    '৳${(walletData != null ? (walletData!['balance'] ?? walletData!['wallet_balance']) : '') ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: ConstanceData.SIZE_TITLE12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PaymentRequestScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 10, right: 10, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: AllCoustomTheme.getThemeData().colorScheme.surface,
                      borderRadius: BorderRadius.circular(4.0),
                      border: Border.all(
                        color: Colors.green,
                        width: 1,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 51),
                            offset: const Offset(0, 1),
                            blurRadius: 5.0),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'ADD CASH'.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.green,
                          fontSize: ConstanceData.SIZE_TITLE12,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget myRewardsOffers() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  FontAwesomeIcons.gift,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'My Rewards & Offers',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int light = 1;
  int dark = 2;
  changeColor(BuildContext context, int color) {
    Navigator.pop(context);
    if (color == light) {
      MyApp.setCustomeTheme(context, 6, color: globals.primaryColorString);
    } else {
      MyApp.setCustomeTheme(context, 7, color: globals.primaryColorString);
    }
  }

  void _onSummaryUpdate() {
    final val = UserSummaryNotifier.notifier.value;
    if (val == null) return;
    try {
      final profileMap = Map<String, dynamic>.from(val['profile'] ?? {});
      if (profileMap.isNotEmpty) {
        userData = UserData.fromJson(profileMap);
      }
    } catch (_) {}
    try {
      walletData = Map<String, dynamic>.from(val['wallet'] ?? {});
    } catch (_) {
      walletData = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    UserSummaryNotifier.notifier.removeListener(_onSummaryUpdate);
    super.dispose();
  }

  openShowPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(
            child: Text(
              'Select theme mode',
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      changeColor(context, light);
                    },
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.black,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 32,
                        child: Text(
                          'Light',
                          style: TextStyle(
                              fontFamily: 'Poppins', color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      changeColor(context, dark);
                    },
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          Theme.of(context).textTheme.titleLarge!.color,
                      child: const CircleAvatar(
                        backgroundColor: Colors.black,
                        radius: 32,
                        child: Text(
                          'Dark',
                          style: TextStyle(
                              fontFamily: 'Poppins', color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget setThemeMode() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {
          openShowPopup(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  Icons.colorize,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'Theme',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myReferrals() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          widget.referralClick!();
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  Icons.group_add,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'My Referrals',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myInfoSetting() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () async {
          widget.mySettingClick!();
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  FontAwesomeIcons.gear,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'My Info & Settings',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget poinSystem() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const set_colorScreen(),
              fullscreenDialog: true,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  Icons.color_lens,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'Set Color',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myProfile() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () async {
          widget.mySettingClick!();
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  FontAwesomeIcons.solidCircleUser,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'My Profile',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget logoutButton() {
    return SizedBox(
      height: 54,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          LogOut().logout(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: Icon(
                  FontAwesomeIcons.powerOff,
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Expanded(
                child: Container(
                  child: Text(
                    'Logout',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AllCoustomTheme.getThemeData().primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
