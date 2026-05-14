import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/api/logout.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/models/transaction_response.dart';
// import 'package:fantasyleague/modules/home/home_screen.dart';
import 'package:fantasyleague/modules/my_profile/transaction_history_screen.dart';
import 'package:fantasyleague/modules/my_profile/update_profile_screen.dart';
// WithdrawScreen removed — withdraw feature not required
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/utils/countdown_timer.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
import 'package:fantasyleague/modules/payment_request/payment_request_screen.dart';
import 'package:fantasyleague/modules/payment_request/payment_requests_list.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

var responseData;

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  var name = '';
  var imageUrl = '';
  UserData? profile;
  bool _isDataCached = false; // Flag to track if data is cached
  bool _didInitialLoad =
      false; // Tracks whether we attempted the initial load (helps hot reload)

  // Wallet data fetched separately and shown as read-only in Account Info
  Map<String, dynamic> walletData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Listen for background updates from home screen
    UserSummaryNotifier.notifier.addListener(_onSummaryUpdateProfile);
  }

  void _onSummaryUpdateProfile() {
    final val = UserSummaryNotifier.notifier.value;
    if (val == null) return;
    try {
      var profileMap = Map<String, dynamic>.from(val['profile'] ?? {});
      if (profileMap.isNotEmpty && profileMap['data'] is Map) {
        profileMap = Map<String, dynamic>.from(profileMap['data']);
      }
      if (profileMap.isNotEmpty) {
        profile = UserData.fromJson(profileMap);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error parsing notifier profile: $e');
    }
    try {
      walletData = Map<String, dynamic>.from(val['wallet'] ?? {});
    } catch (_) {
      walletData = {};
    }

    // If profile is still empty, try the older cache fallback
    if ((profile == null || (profile?.name?.isEmpty ?? true))) {
      try {
        MySharedPreferences().getUserData().then((old) {
          if (old != null) {
            profile = old;
            if (mounted) setState(() {});
          }
        });
      } catch (_) {}
    }

    // Update the display variables from the profile
    _updateUI();

    // mark as fresh data
    _isDataCached = false;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    UserSummaryNotifier.notifier.removeListener(_onSummaryUpdateProfile);
    super.dispose();
  }

  void _loadUserData({bool force = false}) async {
    // Check if we already have cached data from shared preferences
    // When `force` is true override cached flag and re-fetch (helps hot reload)
    if (_isDataCached && !force) {
      return; // Data already loaded and cached
    }

    try {
      // Prefer the new 'user_summary' cache which includes profile and wallet
      final cachedSummary =
          await MySharedPreferences().getCacheJson('user_summary');
      if (cachedSummary != null) {
        try {
          var profileMap =
              Map<String, dynamic>.from(cachedSummary['profile'] ?? {});
          // If profile is nested { data: { ... } } (different codepaths), unwrap it
          if (profileMap.isNotEmpty && profileMap['data'] is Map) {
            profileMap = Map<String, dynamic>.from(profileMap['data']);
          }
          if (profileMap.isNotEmpty) {
            profile = UserData.fromJson(profileMap);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Error parsing cached profile: $e');
        }

        try {
          walletData = Map<String, dynamic>.from(cachedSummary['wallet'] ?? {});
        } catch (_) {
          walletData = {};
        }

        // If cached profile was empty, try old user data cache as fallback
        if ((profile == null || (profile?.name?.isEmpty ?? true))) {
          try {
            final old = await MySharedPreferences().getUserData();
            if (old != null) {
              profile = old;
            }
          } catch (_) {}
        }

        _updateUI();
        _isDataCached = true;

        // Refresh fresh data in background
        _fetchFreshUserData();
        return;
      }
    } catch (e) {
      // ignore cache read errors and fall back
    }

    try {
      // Try to load from old user data cache
      final cachedData = await MySharedPreferences().getUserData();
      if (cachedData != null &&
          cachedData.userId != null &&
          cachedData.userId!.isNotEmpty) {
        profile = cachedData;
        _updateUI();
        _isDataCached = true;

        // Then fetch fresh data from API in the background
        _fetchFreshUserData();
        return;
      }
    } catch (e) {
      // Cache miss or error, continue to fetch from API
    }

    // If no cache, fetch from API
    _fetchFreshUserData();
  }

  void _fetchFreshUserData() async {
    try {
      final responseData = await ApiProvider().getProfile();

      if (responseData.data != null) {
        // Handle if responseData.data is a Map (some codepaths return raw maps)
        try {
          if (responseData.data is Map) {
            profile = UserData.fromJson(
                Map<String, dynamic>.from(responseData.data as Map));
          } else {
            profile = responseData.data;
          }
        } catch (e) {
          if (kDebugMode) debugPrint('Failed to parse profile data: $e');
          profile = responseData.data;
        }

        // Ensure we pass a proper UserData instance for caching
        UserData _toCache;
        if (profile is UserData) {
          _toCache = profile as UserData;
        } else if (profile is Map) {
          _toCache =
              UserData.fromJson(Map<String, dynamic>.from(profile as Map));
        } else {
          _toCache = UserData();
        }
        // Persist profile into the generic JSON cache as part of user_summary (wallet will be added after fetch)
        try {
          final Map<String, dynamic> _summary = {
            'profile': _toCache.toJson(),
            'wallet': <String, dynamic>{},
            'fetched_at': DateTime.now().toIso8601String()
          };
          await MySharedPreferences().setCacheJson('user_summary', _summary);
        } catch (e) {
          if (kDebugMode) debugPrint('Error caching profile summary: $e');
        }
        _isDataCached = true;

        if (!mounted) return;
        _updateUI();

        // Also fetch wallet balance (read-only) to display in Account Info
        try {
          final walletResponse = await ApiProvider().getWallet();
          walletData = Map<String, dynamic>.from(walletResponse);

          // Broadcast wallet update to drawer
          try {
            final cached =
                await MySharedPreferences().getCacheJson('user_summary');
            if (cached != null) {
              final summary = {
                'profile': cached['profile'] ?? {},
                'wallet': walletData,
                'fetched_at': DateTime.now().toIso8601String()
              };
              await MySharedPreferences().setCacheJson('user_summary', summary);
              UserSummaryNotifier.update(summary);
            }
          } catch (_) {}

          if (!mounted) return;
          setState(() {});
        } catch (e) {
          if (kDebugMode) print('Error fetching wallet: $e');
        }
      } else {
        if (kDebugMode)
          debugPrint(
              'getProfile returned null data, raw: ${responseData.toJson()}');
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching profile: $e');
    }
  }

  void _updateUI() {
    if (profile != null) {
      // Use the full name returned by backend for display
      final rawName = profile?.name?.trim() ?? '';
      if (rawName.isNotEmpty) {
        name = rawName;
      }
      imageUrl = profile?.image ?? '';
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we attempt to load profile if the widget was hot-reloaded or mounted without data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_didInitialLoad) {
        _didInitialLoad = true;
        if (profile == null ||
            (profile is UserData && (profile?.name?.isEmpty ?? true)) ||
            (profile is Map && ((profile as Map)['name'] ?? '') == '')) {
          // Force reload to bypass stale cache states from hot reload
          _loadUserData(force: true);
        }
      }
    });

    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          Container(
            color: AllCoustomTheme.getThemeData().primaryColor,
          ),
          SafeArea(
            child: Scaffold(
              drawer: AppDrawer(
                mySettingClick: () {},
                referralClick: () {},
              ),
              backgroundColor:
                  AllCoustomTheme.getThemeData().colorScheme.surface,
              appBar: AppBar(
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        height: 44,
                        width: 44,
                        child: _buildAvatar(imageUrl),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: AllCoustomTheme.getThemeData()
                              .colorScheme
                              .surface,
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: TabBar(
                  labelColor: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
                  unselectedLabelColor:
                      AllCoustomTheme.getReBlackAndWhiteThemeColors()
                          .withValues(alpha: 0.85),
                  indicatorColor:
                      AllCoustomTheme.getReBlackAndWhiteThemeColors(),
                  tabs: [
                    Tab(
                      icon: Text(
                        "My Detail",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      icon: Text(
                        "Matches",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Tab(
                      icon: Text(
                        "Payments",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: FloatingActionButton(
                  foregroundColor:
                      AllCoustomTheme.getThemeData().colorScheme.surface,
                  backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
                  onPressed: () async {
                    // Ensure we have profile data before opening edit
                    if (profile == null) {
                      _fetchFreshUserData();
                      if (profile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profile not loaded yet')),
                        );
                        return;
                      }
                    }

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateProfileScreen(
                          loginUserData: profile,
                        ),
                      ),
                    );

                    if (result != null) {
                      // If UpdateProfileScreen returned updated UserData (or Map), use it
                      UserData updatedUser;
                      if (result is UserData) {
                        updatedUser = result;
                      } else if (result is Map<String, dynamic>) {
                        updatedUser = UserData.fromJson(result);
                      } else {
                        // Try to coerce other map-like types
                        updatedUser = UserData.fromJson(
                            Map<String, dynamic>.from(result));
                      }

                      profile = updatedUser;
                      await MySharedPreferences().setUserDataString(profile!);
                      _updateUI();
                    } else {
                      // Fallback: refresh from API
                      _isDataCached = false; // Reset cache to fetch fresh data
                      _fetchFreshUserData();
                    }
                  },
                  child: const Icon(Icons.edit),
                ),
              ),
              body: Container(
                color: AllCoustomTheme.getThemeData().colorScheme.surface,
                child: TabBarView(
                  children: <Widget>[
                    Container(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(0),
                        physics: const BouncingScrollPhysics(),
                        child: Container(
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.only(
                                    right: 16, left: 16, top: 4, bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'Name',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                          color: AllCoustomTheme
                                              .getTextThemeColors(),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(),
                              Container(
                                padding: const EdgeInsets.only(
                                    right: 16, left: 16, top: 4, bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'Email',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                          color: AllCoustomTheme
                                              .getTextThemeColors(),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        profile?.email ?? 'N/A',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                        ),
                                        textAlign: TextAlign.end,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(),
                              // Wallet (read-only) displayed in Account Info
                              Container(
                                padding: const EdgeInsets.only(
                                    right: 16, left: 16, top: 4, bottom: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'Wallet',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                          color: AllCoustomTheme
                                              .getTextThemeColors(),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Text(
                                        '৳${walletData['balance'] ?? walletData['wallet_balance'] ?? profile?.balance ?? '0.00'}',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: ConstanceData.SIZE_TITLE16,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(),
                              // Removed extra Edit Profile button above logout
                              logoutButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const PlayingHistory(),
                    const PaymentRequestsList(),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget logoutButton() {
    return SizedBox(
      height: 30,
      child: InkWell(
        onTap: () {
          LogOut().logout(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: const Icon(
                  FontAwesomeIcons.powerOff,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Container(
                  child: const Text(
                    'Logout',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontSize: ConstanceData.SIZE_TITLE14,
                      fontWeight: FontWeight.w400,
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

  Widget _buildAvatar(String? url) {
    try {
      return AvatarImage(
        sizeValue: 44,
        radius: 44,
        isCircle: true,
        imageUrl: url,
        entityType: 'user',
      );
    } catch (e) {
      // Fallback to default avatar if there's an error
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[300],
        ),
        child: Icon(Icons.person, color: Colors.grey[600]),
      );
    }
  }

  Widget sliverText() {
    return FlexibleSpaceBar(
      titlePadding:
          const EdgeInsetsDirectional.only(start: 16, bottom: 8, top: 0),
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 44,
            width: 44,
            child: AvatarImage(
              sizeValue: 44,
              radius: 44,
              isCircle: true,
              imageUrl: profile?.image ?? '',
              entityType: 'user',
            ),
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            'Enric',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AllCoustomTheme.getThemeData().colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class AccountInfoScreen extends StatefulWidget {
  final Function? update;

  const AccountInfoScreen({super.key, this.update});
  @override
  _AccountInfoScreenState createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  bool isLoginProsses = false;
  UserData data = UserData();

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    setState(() {
      isLoginProsses = true;
    });
    final responseData = await ApiProvider().getProfile();
    if (responseData.data != null) {
      data = responseData.data!;
    }
    setState(() {
      isLoginProsses = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
      body: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            child: ModalProgressHUD(
              inAsyncCall: isLoginProsses,
              color: Colors.transparent,
              progressIndicator: const CircularProgressIndicator(
                strokeWidth: 2.0,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                physics: const BouncingScrollPhysics(),
                child: data.name != ''
                    ? Container(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.name ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Email',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.email ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Mobile No',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.mobileNumber ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Date of Birth',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.dob != null && data.dob!.isNotEmpty
                                          ? DateFormat('dd MMM, yyyy').format(
                                              DateFormat('dd/MM/yyyy')
                                                  .parse(data.dob!))
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.gender != null &&
                                              data.gender!.isNotEmpty
                                          ? data.gender![0].toUpperCase() +
                                              data.gender!.substring(1)
                                          : 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'Country',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.country ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'State',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.state ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            Container(
                              padding: const EdgeInsets.only(
                                  right: 16, left: 16, top: 4, bottom: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'City',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                        color: AllCoustomTheme
                                            .getTextThemeColors(),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    child: Text(
                                      data.city ?? 'N/A',
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE16,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const Divider(),
                            logoutButton(),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: -10, right: 30),
            child: FloatingActionButton(
              foregroundColor:
                  AllCoustomTheme.getThemeData().colorScheme.surface,
              backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
              onPressed: () async {
                if (data.name != '') {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateProfileScreen(
                        loginUserData: data,
                      ),
                    ),
                  );

                  if (result != null) {
                    if (result is UserData) {
                      data = result;
                    } else if (result is Map<String, dynamic>) {
                      data = UserData.fromJson(result);
                    } else {
                      data =
                          UserData.fromJson(Map<String, dynamic>.from(result));
                    }
                    setState(() {});
                    if (widget.update != null) widget.update!();
                  } else {
                    getUserData();
                  }
                }
              },
              child: const Icon(Icons.edit),
            ),
          ),
        ],
      ),
    );
  }

  Widget logoutButton() {
    return SizedBox(
      height: 30,
      child: InkWell(
        onTap: () {
          LogOut().logout(context);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 14, right: 14),
          child: Row(
            children: <Widget>[
              Container(
                child: const Icon(
                  FontAwesomeIcons.powerOff,
                  size: 22,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Container(
                  child: const Text(
                    'Logout',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontSize: ConstanceData.SIZE_TITLE14,
                      fontWeight: FontWeight.w400,
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

class PlayingHistory extends StatefulWidget {
  const PlayingHistory({super.key});

  @override
  _PlayingHistoryState createState() => _PlayingHistoryState();
}

class _PlayingHistoryState extends State<PlayingHistory> {
  bool isLoading = false;
  UserData data = UserData();
  List<Map<String, dynamic>> matches = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetch();
    // Listen for theme changes to rebuild with new theme colors
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final profile = await ApiProvider().getProfile();
      if (profile.data != null) data = profile.data!;
      final m = await ApiProvider().getMatches();
      if (!mounted) return;
      setState(() {
        matches = m;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('Error in PlayingHistory._fetch: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load matches';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Container(
        color: AllCoustomTheme.getThemeData().colorScheme.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!,
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Slide down to refresh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AllCoustomTheme.getThemeData().colorScheme.surface,
      child: ModalProgressHUD(
        inAsyncCall: isLoading,
        color: Colors.transparent,
        progressIndicator: const CircularProgressIndicator(strokeWidth: 2.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Removed contests, matches, series, wins info rows per request
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Upcoming / Recent Matches',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          fontWeight: FontWeight.bold,
                          color: AllCoustomTheme.getTextThemeColors())),
                ),
              ),
              matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('No matches available',
                          style: TextStyle(
                              color: AllCoustomTheme.getTextThemeColors())),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: matches.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final m = matches[idx];
                        final teamA = m['team_a'] ??
                            m['teamA'] ??
                            m['team_a_name'] ??
                            m['home_team'] ??
                            '';
                        final teamB = m['team_b'] ??
                            m['teamB'] ??
                            m['team_b_name'] ??
                            m['away_team'] ??
                            '';
                        final start = m['start_time'] ??
                            m['start_at'] ??
                            m['startAt'] ??
                            m['startTime'] ??
                            '';
                        return ListTile(
                          title: Text(
                              '${teamA.toString()} vs ${teamB.toString()}',
                              style: const TextStyle(fontFamily: 'Poppins')),
                          subtitle: start.toString().isNotEmpty
                              ? CountdownTimerWidget(
                                  startDateTime: start.toString(),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: ConstanceData.SIZE_TITLE12,
                                    color: AllCoustomTheme.getTextThemeColors(),
                                  ),
                                  format: 'auto',
                                  liveText: 'Live',
                                  liveColor: Colors.orangeAccent,
                                )
                              : Text(start.toString()),
                          trailing:
                              const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MatchDetailScreen(
                                match: Map<String, dynamic>.from(m),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  _WalletState createState() => _WalletState();
}

class MatchDetailScreen extends StatelessWidget {
  final Map<String, dynamic> match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    final teamA = match['team_a'] ??
        match['teamA'] ??
        match['team_a_name'] ??
        match['home_team'] ??
        '';
    final teamB = match['team_b'] ??
        match['teamB'] ??
        match['team_b_name'] ??
        match['away_team'] ??
        '';
    final start = match['start_time'] ??
        match['start_at'] ??
        match['startAt'] ??
        match['startTime'] ??
        '';
    final venue = match['venue'] ?? match['ground'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('${teamA.toString()} vs ${teamB.toString()}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${teamA.toString()} vs ${teamB.toString()}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Start: ${start.toString()}'),
            if (venue.toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Venue: ${venue.toString()}'),
            ],
            const SizedBox(height: 16),
            const Text('Match Info',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(match.entries
                    .where((e) => ![
                          'id',
                          'team_a_id',
                          'team_b_id',
                          'tournament_id',
                          'venue_id',
                          'venue',
                          'team_a_name',
                          'team_b_name'
                        ].contains(e.key))
                    .map((e) => '${e.key}: ${e.value}')
                    .join('\n')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletState extends State<Wallet> {
  bool isLoginProsses = false;
  UserData data = UserData();
  Map<String, dynamic> walletData = {};
  bool emialApproved = false;
  bool allApproved = false;
  String? errorMessage;
  List<Transaction> recentTransactions = [];

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    setState(() {
      isLoginProsses = true;
      errorMessage = null;
    });

    try {
      final responseData = await ApiProvider().getProfile();
      if (responseData.data != null) {
        data = responseData.data!;
      }

      // Fetch wallet data
      final walletResponse = await ApiProvider().getWallet();
      if (!mounted) return;
      setState(() {
        walletData = walletResponse;
      });

      // Broadcast wallet update to drawer
      try {
        final cached = await MySharedPreferences().getCacheJson('user_summary');
        if (cached != null) {
          final summary = {
            'profile': cached['profile'] ?? {},
            'wallet': walletResponse,
            'fetched_at': DateTime.now().toIso8601String()
          };
          await MySharedPreferences().setCacheJson('user_summary', summary);
          UserSummaryNotifier.update(summary);
        }
      } catch (_) {}

      // Fetch recent transactions preview
      try {
        final txResp = await ApiProvider().getTransaction();
        if (txResp.transaction != null) {
          recentTransactions = txResp.transaction!.take(3).toList();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Error fetching recent transactions: $e');
        recentTransactions = [];
      }

      var email = await ApiProvider().getEmailResponce();
      if ('Your E-mail and Mobile Number are Verified.' == email['message']) {
        emialApproved = true;
      }

      // Only email verification required (bank and pancard features removed)
      if (emialApproved) {
        allApproved = true;
      }

      if (!mounted) return;
      setState(() {
        isLoginProsses = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) debugPrint('Error fetching wallet data: $e');
      setState(() {
        isLoginProsses = false;
        errorMessage = 'Failed to load wallet data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: ModalProgressHUD(
          inAsyncCall: isLoginProsses,
          color: Colors.transparent,
          progressIndicator: const CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
          child: data.name != ''
              ? Column(
                  children: <Widget>[
                    _buildCachedBanner(),
                    Container(
                      padding: const EdgeInsets.only(
                          right: 16, left: 16, top: 4, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            'My Balance',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                              color: AllCoustomTheme.getTextThemeColors(),
                            ),
                          ),
                          Text(
                            '৳${walletData['balance'] ?? data.balance ?? '0.00'}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: ConstanceData.SIZE_TITLE16,
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.only(
                          right: 16, left: 16, top: 4, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Deposit',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE16,
                                color: AllCoustomTheme.getTextThemeColors(),
                              ),
                            ),
                          ),
                          Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '৳${walletData['deposit'] ?? '0.00'}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: ConstanceData.SIZE_TITLE16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const PaymentRequestScreen(),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AllCoustomTheme.getThemeData()
                                              .primaryColor),
                                    ),
                                    child: Text('Add Balance',
                                        style: TextStyle(
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .primaryColor,
                                            fontSize:
                                                ConstanceData.SIZE_TITLE12)),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.only(
                          right: 16, left: 16, top: 4, bottom: 4),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Winning',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE16,
                                color: AllCoustomTheme.getTextThemeColors(),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: SizedBox(),
                          ),
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Withdraw feature removed.'),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, top: 4, bottom: 4),
                              decoration: BoxDecoration(
                                color: AllCoustomTheme.getThemeData()
                                    .colorScheme
                                    .surface,
                                borderRadius: BorderRadius.circular(8),
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
                                  'withdraw'.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.green,
                                    fontSize: ConstanceData.SIZE_TITLE14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Container(
                            child: Text(
                              '৳${walletData['winning'] ?? '0.00'}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE16,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    !allApproved
                        ? Container(
                            padding: const EdgeInsets.only(top: 4),
                            alignment: Alignment.centerRight,
                            child: const Text(
                              'Verify your account to be eligible to withdraw.      ',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE12,
                                color: Colors.red,
                              ),
                            ),
                          )
                        : const SizedBox(),
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.only(
                          right: 16, left: 16, top: 8, bottom: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(
                            width: 110,
                            child: Text(
                              'Bonus',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE16,
                                color: AllCoustomTheme.getTextThemeColors(),
                              ),
                            ),
                          ),
                          Container(
                            child: Text(
                              '৳${walletData['bonus'] ?? data.cashBonus ?? '0.00'}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: ConstanceData.SIZE_TITLE16,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const TransectionHistoryScreen(),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                      child: Column(
                        children: <Widget>[
                          Container(
                            height: 60,
                            color: AllCoustomTheme.getThemeData()
                                .primaryColor
                                .withValues(alpha: 51),
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    "My Transactions",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ConstanceData.SIZE_TITLE16,
                                      fontWeight: FontWeight.bold,
                                      color: AllCoustomTheme.getThemeData()
                                          .primaryColor,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_right,
                                  size: ConstanceData.SIZE_TITLE22,
                                  color: AllCoustomTheme.getThemeData()
                                      .primaryColor,
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                          ),
                        ],
                      ),
                    ),

                    // Recent transactions preview (up to 3 items)
                    if (recentTransactions.isNotEmpty)
                      Column(
                        children: recentTransactions.map((t) {
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                title: Text(t.remark ?? '',
                                    style:
                                        const TextStyle(fontFamily: 'Poppins')),
                                subtitle: Text(t.time ?? ''),
                                trailing: Text(
                                    '${t.type == 'RECEIVE' ? '+' : '-'} ৳${t.amount ?? ''}'),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 8),
                  ],
                )
              : const SizedBox(),
        ),
      ),
    );
  }
}

// Top-level cached banner used by multiple widgets (keeps build code DRY).
// Currently returns an empty widget unless you wire a cached flag into callers.
Widget _buildCachedBanner() {
  return const SizedBox.shrink();
}

class PersistentHeader extends SliverPersistentHeaderDelegate {
  final TabController controller;

  PersistentHeader(
    this.controller,
  );

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Column(
      children: <Widget>[
        Container(
          height: 40,
          color: AllCoustomTheme.getThemeData().colorScheme.surface,
          child: TabBar(
            unselectedLabelColor:
                Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            labelColor: Theme.of(context).primaryColor,
            labelStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor,
            ),
            tabs: const [
              Tab(text: 'Account Info'),
              Tab(text: 'Playing History'),
              Tab(text: 'Payment Request'),
            ],
            controller: controller,
          ),
        ),
        const Divider(
          height: 1,
        )
      ],
    );
  }

  @override
  double get maxExtent => 41.0;

  @override
  double get minExtent => 41.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
