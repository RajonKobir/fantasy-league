import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/models/notification.dart';
import 'package:fantasyleague/services/notification_service.dart';

class notification_screen extends StatefulWidget {
  const notification_screen({super.key});

  @override
  _notification_screenState createState() => _notification_screenState();
}

class _notification_screenState extends State<notification_screen> {
  late NotificationService _notificationService;
  List<NotificationData> notificationList = <NotificationData>[];
  bool isProsses = false;
  // Pagination state
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _loadNotificationsPage(page: 1);
  }

  Future<void> _loadNotificationsPage({int page = 1, int perPage = 30}) async {
    if (page == 1) {
      setState(() {
        isProsses = true;
        notificationList = [];
        _currentPage = 1;
        _lastPage = 1;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final resp = await ApiProvider()
          .getNotificationsPage(page: page, perPage: perPage);
      final List<dynamic> data = resp['data'] ?? [];
      final newItems = data
          .map((d) => NotificationData.fromJson(Map<String, dynamic>.from(d)))
          .toList();
      final int current = resp['current_page'] ?? page;
      final int last = resp['last_page'] ?? page;

      setState(() {
        if (page == 1)
          notificationList = newItems;
        else
          notificationList.addAll(newItems);
        _currentPage = current;
        _lastPage = last;
        isProsses = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isProsses = false;
          _isLoadingMore = false;
        });
      }
      if (kDebugMode) debugPrint('Error loading notifications page: $e');
    }
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh() async {
    await _notificationService.refreshNotifications();
    setState(() {
      notificationList = _notificationService.notifications;
    });
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
      child: Stack(
        children: <Widget>[
          SafeArea(
            child: Scaffold(
              backgroundColor:
                  AllCoustomTheme.getThemeData().colorScheme.surface,
              body: Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: <Widget>[
                  Column(
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
                                      child: Text(
                                        'Notifications',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          color: AllCoustomTheme.getThemeData()
                                              .colorScheme
                                              .surface,
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
                        child: ModalProgressHUD(
                          inAsyncCall: isProsses,
                          color: Colors.transparent,
                          progressIndicator: const CircularProgressIndicator(
                            strokeWidth: 2.0,
                          ),
                          child: RefreshIndicator(
                            key: _refreshIndicatorKey,
                            onRefresh: _handleRefresh,
                            child: notificationList.isEmpty
                                ? ListView(
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.5,
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.notifications_none,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No Notifications',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'You\'re all caught up!',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: notificationList.length +
                                        (_currentPage < _lastPage ? 2 : 1),
                                    itemBuilder: (context, index) {
                                      if (index < notificationList.length) {
                                        return listItems(
                                            notificationList[index], index);
                                      }

                                      if (index == notificationList.length) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          child: Center(
                                            child: Text(
                                              'Showing ${notificationList.length} (Page $_currentPage of $_lastPage)',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        );
                                      }

                                      return _isLoadingMore
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16.0),
                                              child: SizedBox(
                                                height: 40,
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                            Color>(
                                                      AllCoustomTheme
                                                              .getThemeData()
                                                          .primaryColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0,
                                                      horizontal: 8.0),
                                              child: SizedBox(
                                                width: double.infinity,
                                                child: ElevatedButton.icon(
                                                  onPressed: _currentPage <
                                                          _lastPage
                                                      ? () =>
                                                          _loadNotificationsPage(
                                                              page:
                                                                  _currentPage +
                                                                      1)
                                                      : null,
                                                  icon: const Icon(
                                                      Icons.expand_more),
                                                  label:
                                                      const Text('Load More'),
                                                ),
                                              ),
                                            );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget listItems(NotificationData data, int index) {
    final isUnread = data.readAt == null;

    return GestureDetector(
      onTap: () {
        // Mark as read when tapped
        if (isUnread) {
          _notificationService.markAsRead(index);
          setState(() {
            notificationList = _notificationService.notifications;
          });
        }
      },
      child: Container(
        color: isUnread
            ? AllCoustomTheme.getThemeData()
                .primaryColor
                .withValues(alpha: 0.05)
            : Colors.transparent,
        constraints: const BoxConstraints(minHeight: 60),
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Unread indicator
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AllCoustomTheme.getThemeData().primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    height: 55,
                    width: 55,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 36,
                      height: 40,
                      padding: const EdgeInsets.only(top: 4),
                      child: Image.asset(
                        ConstanceData.notificationCup,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            data.notificationDetail!,
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color:
                                  AllCoustomTheme.getBlackAndWhiteThemeColors(),
                              fontSize: ConstanceData.SIZE_TITLE14,
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.only(left: 4, top: 4),
                          child: Text(
                            DateFormat('dd MMM, yyyy').format(
                                DateFormat('dd/MM/yyyy').parse(data.date!)),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AllCoustomTheme.getTextThemeColors(),
                              fontSize: ConstanceData.SIZE_TITLE14,
                            ),
                          ),
                        )
                      ],
                    ),
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
    );
  }
}
