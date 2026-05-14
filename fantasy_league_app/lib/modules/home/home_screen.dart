import 'dart:async';

import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:fantasyleague/models/schedule_response_data.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/models/drawer_info_responce_data.dart';
import 'package:fantasyleague/modules/drawer/drawer.dart';
import 'package:fantasyleague/modules/notification/notification_screen.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/utils/countdown_timer.dart';
import 'package:fantasyleague/validator/validator.dart';
// import 'package:fantasyleague/api/api_client.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/modules/tournament/tournament_detail_screen.dart';
import 'package:fantasyleague/services/data_cache_service.dart';

class home_screen extends StatefulWidget {
  final void Function()? menuCallBack;

  const home_screen({super.key, this.menuCallBack});
  @override
  _home_screenState createState() => _home_screenState();
}

class _home_screenState extends State<home_screen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  var sheduallist = <ShedualData>[];
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoginProsses = false;
  late UserData userData;
  var responseData;
  // Pagination state for matches
  List<Map<String, dynamic>> _matches = [];
  int _matchesPage = 1;
  int _matchesLastPage = 1;
  List<Map<String, dynamic>> tournaments = [];
  bool isTournamentsLoading = true;

  @override
  void initState() {
    _controller = TabController(length: 2, vsync: this);

    // Defer API calls until after the first frame renders to avoid blocking UI
    // This also ensures user is fully logged in before fetching their data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        allmatches();
        fetchTournaments();
        _fetchUserSummaryInBackground();
      }
    });

    // Rebuild Home when theme changes so color updates take effect immediately
    try {
      globals.themeNotifier.addListener(_onThemeChanged);
    } catch (_) {}

    super.initState();
  }

  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> allmatches() async {
    Timer? matchesTimer;
    try {
      setState(() {
        isLoginProsses = true; // Show the loader
      });

      // Add 15s timeout for fetching matches to prevent spinner hang
      matchesTimer = Timer(const Duration(seconds: 15), () {
        if (!mounted || !isLoginProsses) return;
        setState(() => isLoginProsses = false);
        debugPrint('Error: Fetching matches timed out after 15 seconds');
      });

      // Use paginated API to fetch first page of matches
      final resp = await ApiProvider().getMatchesPage(page: 1, perPage: 50);
      final List<dynamic> data = resp['data'] ?? [];
      final int current = resp['current_page'] ?? 1;
      final int last = resp['last_page'] ?? 1;
      setState(() {
        _matches = List<Map<String, dynamic>>.from(
            data.map((m) => Map<String, dynamic>.from(m)));
        _matchesPage = current;
        _matchesLastPage = last;
        responseData = _matches;
        isLoginProsses = false;
      });
    } catch (error) {
      // Handle exceptions or errors here
      setState(() {
        isLoginProsses = false;
      });
      debugPrint('Error fetching matches from backend: $error');
      throw Exception('Failed to fetch matches.');
    } finally {
      matchesTimer?.cancel();
    }
  }

  Future<void> fetchTournaments() async {
    try {
      // First check if tournaments are already cached from login
      final cached = DataCacheService().tournaments;
      if (cached.isNotEmpty && DataCacheService().tournamentsLoaded) {
        if (mounted) {
          setState(() {
            tournaments = cached;
            isTournamentsLoading = false;
          });
        }
        return;
      }

      // If not cached, fetch from API
      final fetched = await ApiProvider().getTournaments();
      if (mounted) {
        setState(() {
          tournaments = fetched;
          isTournamentsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isTournamentsLoading = false;
        });
      }
      debugPrint('Error fetching tournaments: $e');
    }
  }

  /// Fetch user profile and wallet in background and cache them locally.
  /// This runs non-blocking so Home renders immediately and background updates the cache.
  Future<void> _fetchUserSummaryInBackground() async {
    try {
      // If a cached summary exists we don't block on network; background fetch will refresh cache when done.
      final cached = await MySharedPreferences().getCacheJson('user_summary');
      if (cached != null) {
        // Optionally set local state from cache so drawer/profile show immediately
        try {
          if (mounted && (cached['profile'] as Map?) != null) {
            final profileMap = Map<String, dynamic>.from(cached['profile']);
            // If UserData is needed elsewhere, update stored user data
            try {
              final userData = UserData.fromJson(profileMap);
              await MySharedPreferences().setUserDataString(userData);
            } catch (_) {}
          }
        } catch (_) {}
      }

      // Fetch fresh values in parallel
      final profileF = ApiProvider().getProfile();
      final walletF = ApiProvider().getWallet();
      final results = await Future.wait([profileF, walletF]);

      final profile = results[0] as UserDetail;
      final wallet = results[1] as Map<String, dynamic>;

      final Map<String, dynamic> summary = {
        'profile': profile.data?.toJson() ?? {},
        'wallet': wallet,
        'fetched_at': DateTime.now().toIso8601String()
      };

      await MySharedPreferences().setCacheJson('user_summary', summary);

      // Also update the persistent user data cache used elsewhere
      if (profile.data != null) {
        await MySharedPreferences().setUserDataString(profile.data!);
      }

      // Broadcast update so UI (Drawer/Profile) can react immediately
      UserSummaryNotifier.update(summary);
    } catch (e) {
      debugPrint('Error background fetching user summary: $e');
    }
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          color: AllCoustomTheme.getThemeData().primaryColor,
        ),
        SafeArea(
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
              title: const Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            drawer: AppDrawer(
              mySettingClick: () {},
              referralClick: () {},
            ),
            key: _scaffoldKey,
            backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
            body: RefreshIndicator(
              displacement: 100,
              key: _refreshIndicatorKey,
              onRefresh: () async {
                await Future.wait([
                  allmatches(),
                  fetchTournaments(),
                  _fetchUserSummaryInBackground(),
                ]);
              },
              child: ModalProgressHUD(
                inAsyncCall: isLoginProsses,
                color: Colors.transparent,
                progressIndicator: const CircularProgressIndicator(
                  strokeWidth: 2.0,
                ),
                child: Stack(
                  children: <Widget>[
                    CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: <Widget>[
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Column(
                              children: [
                                tournamentsSection(),
                                listItems(),
                              ],
                            ),
                            childCount: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget drawerButton() {
    return InkWell(
      onTap: openDrawer,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor:
                AllCoustomTheme.getThemeData().scaffoldBackgroundColor,
            radius: 16,
            child: AvatarImage(
              imageUrl: globals.userdata?.image ?? '',
              isCircle: true,
              radius: 28,
              sizeValue: 28,
              entityType: 'user',
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          const Icon(
            Icons.sort,
            size: 30,
          )
        ],
      ),
    );
  }

  Widget notificationButton() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const notification_screen(),
            fullscreenDialog: true,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(
          Icons.notifications,
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        ),
      ),
    );
  }

  Widget sliverText() {
    return FlexibleSpaceBar(
      centerTitle: false,
      titlePadding:
          const EdgeInsetsDirectional.only(start: 16, bottom: 8, top: 0),
      title: Container(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Upcoming Matches',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showInSnackBar(String value) {
    var snackBar = SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: ConstanceData.SIZE_TITLE14,
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget tournamentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Tournaments',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AllCoustomTheme.getTextThemeColors(),
            ),
          ),
          const SizedBox(height: 12),
          if (isTournamentsLoading)
            const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (tournaments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: const Text(
                'No tournaments available',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final tournament = tournaments[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TournamentDetailScreen(
                            tournamentId: tournament['id'].toString(),
                            tournamentName: tournament['name'] ?? 'Tournament',
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(right: 12),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Tournament Logo
                            if (tournament['logo_url'] != null &&
                                tournament['logo_url'].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  tournament['logo_url'].toString(),
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.emoji_events),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Icon(Icons.emoji_events, size: 40),
                                ),
                              ),
                            const SizedBox(height: 8),
                            // Tournament Name
                            Expanded(
                              child: Text(
                                tournament['name'] ?? 'Tournament',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AllCoustomTheme.getTextThemeColors(),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Entry Fee
                            Text(
                              'Entry: ৳${tournament['entry_fee'] ?? 0}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
        ],
      ),
    );
  }

  Widget listItems() {
    final matches = _matches;
    if (matches.isEmpty) {
      return Container();
    }

    final matchCards = matches.map<Widget>((match) {
      final title = match['title'];
      final country1 = match['teama'];
      final country2 = match['teamb'];

      // Check if the required data is not null
      if (title != null && country1 != null && country2 != null) {
        // final country1Name = country1['name'];
        final country1Name = country1['short_name'];
        // final country2Name = country2['name'];
        final country2Name = country2['short_name'];
        final teamA = country1;
        final teamB = country2;

        List<Widget> teamWidgets = [];

        if (teamA != null && teamB != null) {
          final allTeams = [teamA, teamB];

          for (var team in allTeams) {
            // final name = team['name'];
            final shortName = team['short_name'];
            final img = team['logo_url'];
            teamWidgets.add(
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Text('Name: $name'),
                    Text('Shortname: $shortName'),
                    if (img != null) Image.network(img),
                  ],
                ),
              ),
            );
          }
        } else {
          teamWidgets.add(const Text('No teamInfo available for this match.'));
        }

        final country1Flag = country1Name != null ? country1['logo_url'] : null;
        final country2Flag = country2Name != null ? country2['logo_url'] : null;

        const price = "?2 Lakhs"; // You may extract the price from the data.
        // final time = match['date_start'];
        final time = match['date_start_ist'];
        // final cid = match['competition']['cid'];

        if (country1Name != null && country2Name != null) {
          return MatchesList(
            matchId: match['match_id'].toString(),
            titel: title,
            country1Name: country1Name,
            country2Name: country2Name,
            country1Flag: country1Flag,
            country2Flag: country2Flag,
            price: price,
            time: time,
            cid: match['competition']['cid'].toString(),
          );
        }
      }

      // Handle null values or incomplete data
      return Container(); // You can return an empty container or a placeholder
    }).toList();

    final widgets = matchCards.toList();
    // Pagination footer - removed as we don't need pagination UI for this screen

    if (_matchesPage < _matchesLastPage) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              final next = _matchesPage + 1;
              try {
                final resp =
                    await ApiProvider().getMatchesPage(page: next, perPage: 50);
                final List<dynamic> data = resp['data'] ?? [];
                final newMatches = List<Map<String, dynamic>>.from(
                    data.map((m) => Map<String, dynamic>.from(m)));
                setState(() {
                  _matches.addAll(newMatches);
                  _matchesPage = resp['current_page'] ?? next;
                  _matchesLastPage = resp['last_page'] ?? _matchesLastPage;
                  responseData = _matches;
                });
              } catch (e) {
                debugPrint('Error loading more matches: $e');
              }
            },
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More'),
          ),
        ),
      ));
    }

    return Column(children: widgets);
  }

  void openDrawer() {
    widget.menuCallBack!();
  }
}

class MatchesList extends StatefulWidget {
  final String? titel;
  final String? country1Name;
  final String? country1Flag;
  final String? country2Name;
  final String? country2Flag;
  final String? time;
  final String? price;
  final String? matchId; // Add matchId
  final String? cid; // Add competitionId

  const MatchesList({
    super.key,
    this.titel,
    this.country1Name,
    this.country2Name,
    this.time,
    this.price,
    this.country1Flag,
    this.country2Flag,
    this.matchId, // Include matchId in the constructor
    this.cid, // Include competitionId in the constructor
  });

  @override
  _MatchesListState createState() => _MatchesListState();
}

class _MatchesListState extends State<MatchesList> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        debugPrint(widget.cid);
        debugPrint(widget.matchId);
        // Get an instance of SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();

// Store a key-value pair in SharedPreferences
        prefs.setString('cid', widget.cid!);
        prefs.setString('matchId', widget.matchId!);
        prefs.setString('country1Flag', widget.country1Flag!);
        prefs.setString('country1Name', widget.country1Name!);
        prefs.setString('time', widget.time!);

        prefs.setString('time', widget.time!);

        prefs.setString('country2Flag', widget.country2Flag!);
        prefs.setString('country2Name', widget.country2Name!);

// prefs.setString('country2Flag',widget.country2Flag!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Contests')),
              body: const Center(
                  child: Text('This contest screen has been removed.')),
            ),
          ),
        );
      },
      onLongPress: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (
            BuildContext context,
          ) =>
              UnderGroundDrawer(
            country1Flag: widget.country1Flag!,
            country2Flag: widget.country2Flag!,
            country1Name: widget.country1Name!,
            country2Name: widget.country2Name!,
            price: widget.price!,
            time: widget.time!,
            titel: widget.titel!,
          ),
        );
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        widget.titel!,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2, // Limit title to 2 lines
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Image.asset(
                        ConstanceData.lineups,
                        height: 14,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Icon(
                        Icons.notification_add_outlined,
                        size: 16,
                      ),
                    ],
                  ),
                  const Divider(
                    thickness: 1.3,
                  ),
                  Row(
                    children: [
                      Text(
                        widget.country1Name!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                      Text(
                        widget.country2Name!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(widget.country1Flag!),
                      ),
                      Container(
                        child: CountdownTimerWidget(
                          startDateTime: widget.time,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: ConstanceData.SIZE_TITLE12,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                          format: 'auto',
                          liveText: 'Live',
                          liveColor: Colors.red,
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.network(widget.country2Flag!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AllCoustomTheme.isLight
                    ? HexColor("#f5f5f5")
                    : Theme.of(context).disabledColor.withValues(alpha: 26),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(right: 3, left: 3),
                        child: Text(
                          "Mega",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: ConstanceData.SIZE_TITLE12,
                            color: Colors.green,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.price!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE12,
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                    Image.asset(
                      ConstanceData.tv,
                      height: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UnderGroundDrawer extends StatefulWidget {
  final String? titel;
  final String? country1Name;
  final String? country1Flag;
  final String? country2Name;
  final String? country2Flag;
  final String? time;
  final String? price;

  const UnderGroundDrawer({
    super.key,
    this.titel,
    this.country1Name,
    this.country1Flag,
    this.country2Name,
    this.country2Flag,
    this.time,
    this.price,
  });

  @override
  _UnderGroundDrawerState createState() => _UnderGroundDrawerState();
}

class _UnderGroundDrawerState extends State<UnderGroundDrawer> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: <Widget>[
          matchSchedulData(),
          const Divider(
            height: 1,
          ),
          Expanded(
            child: matchInfoList(),
          ),
        ],
      ),
    );
  }

  Widget matchInfoList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: 1,
      itemBuilder: (context, index) {
        return Container(
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(
                    right: 16, left: 16, top: 10, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Match',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        "${widget.country1Name!} vs ${widget.country2Name!}",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Series',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        widget.titel!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Start Date',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        widget.time!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Start Time',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        '15:00:00',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Venue',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        'India',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Umpires',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        'Martine',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Referee',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        'Charls piter',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.only(right: 16, left: 16, bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Match Format',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getTextThemeColors(),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Text(
                        'Match Formate',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE16,
                          color: AllCoustomTheme.getBlackAndWhiteThemeColors(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Location section removed
            ],
          ),
        );
      },
    );
  }

  Widget matchSchedulData() {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              SizedBox(
                width: 30,
                height: 30,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: Image.network(widget.country1Flag!),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.country1Name!,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: AllCoustomTheme.getThemeData().primaryColor,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            child: const Text(
              'vs',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: ConstanceData.SIZE_TITLE14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Container(
            child: Text(
              widget.country2Name!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: AllCoustomTheme.getThemeData().primaryColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              child: SizedBox(
                width: 50,
                height: 50,
                child: Image.network(widget.country2Flag!),
              ),
            ),
          ),
          Expanded(
            child: Container(),
          ),
          Text(
            widget.time!,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: HexColor(
                '#AAAFBC',
              ),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

enum AppBarBehavior { normal, pinned, floating, snapping }
