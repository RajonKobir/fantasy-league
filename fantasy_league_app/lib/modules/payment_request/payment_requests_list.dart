import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/modules/payment_request/payment_request_screen.dart';
import 'package:fantasyleague/constance/user_summary_notifier.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'dart:async';
import 'package:fantasyleague/models/drawer_info_responce_data.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class PaymentRequestsList extends StatefulWidget {
  const PaymentRequestsList({Key? key}) : super(key: key);

  @override
  _PaymentRequestsListState createState() => _PaymentRequestsListState();
}

class _PaymentRequestsListState extends State<PaymentRequestsList> {
  final ApiProvider _api = ApiProvider();
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

  // Tab controller to detect when Payments tab becomes active
  TabController? _tabController;
  bool _hasLoadedOnce = false;

  // Pagination metadata
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    // Do not load automatically here; wait until the Payments tab is active
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtain nearest DefaultTabController (used by MyProfile)
    final tc = DefaultTabController.of(context);
    if (_tabController != tc) {
      // Remove old listener if present
      try {
        _tabController?.removeListener(_onTabChanged);
      } catch (_) {}
      _tabController = tc;
      try {
        _tabController?.addListener(_onTabChanged);
      } catch (_) {}

      // If Payments tab (index 2) is already selected, trigger load once
      if (_tabController?.index == 2 && !_hasLoadedOnce) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_hasLoadedOnce) {
            _hasLoadedOnce = true;
            _loadRequests(page: 1);
          }
        });
      }
    }
  }

  void _onTabChanged() {
    // TabController listener
    if (!mounted) return;
    try {
      if (_tabController != null &&
          _tabController!.index == 2 &&
          !_hasLoadedOnce) {
        _hasLoadedOnce = true;
        _loadRequests(page: 1);
      }
    } catch (_) {}
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      _initialLoadTimer?.cancel();
    } catch (_) {}
    try {
      if (_tabController != null) {
        _tabController!.removeListener(_onTabChanged);
      }
    } catch (_) {}
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  // Member variable for initial load timeout
  Timer? _initialLoadTimer;

  Future<void> _loadRequests({int page = 1}) async {
    setState(() {
      if (page == 1) {
        _loading = true;
        _error = null;
        _requests = [];
      } else {
        _loadingMore = true;
      }
    });

    Timer? loadMoreTimer;
    try {
      // For initial load (page 1), add a timeout to clear _loading spinner
      if (page == 1) {
        _initialLoadTimer = Timer(const Duration(seconds: 12), () {
          if (!mounted) return;
          if (_loading) {
            setState(() {
              _loading = false;
              _error = 'Request timed out. Please try again.';
            });
          }
        });
      }
      // For load-more requests (page > 1), add a local timeout for the inline spinner
      else {
        loadMoreTimer = Timer(const Duration(seconds: 12), () {
          if (!mounted) return;
          if (_loadingMore) {
            setState(() {
              _loadingMore = false;
              _error = 'Request timed out while loading more.';
            });
          }
        });
      }

      // Load both payment requests and wallet in parallel
      final results = await Future.wait([
        _api.getPaymentRequests(page: page),
        page == 1 ? _api.getWallet() : Future.value({}),
        page == 1 ? _api.getProfile() : Future.value(null),
      ]);

      final paginatedData = results[0] as Map<String, dynamic>;
      final wallet = results[1] as Map<String, dynamic>;
      final profile = results[2];

      if (!mounted) return;

      // Extract pagination data from the response
      final List<dynamic> dataList = paginatedData['data'] ?? [];
      final newRequests = List<Map<String, dynamic>>.from(
        dataList.map((r) => Map<String, dynamic>.from(r)),
      );

      // Update pagination metadata
      _currentPage = paginatedData['current_page'] ?? 1;
      _lastPage = paginatedData['last_page'] ?? 1;
      _total = paginatedData['total'] ?? 0;

      // Update the wallet and profile in cache on first page load
      if (page == 1) {
        Map<String, dynamic>? profileData;
        if (profile is Map && profile['data'] != null) {
          profileData = Map<String, dynamic>.from(profile['data']);
        } else if (profile is UserDetail && profile.data != null) {
          profileData = profile.data!.toJson();
        }

        if (profileData != null) {
          final userSummary = {'profile': profileData, 'wallet': wallet};
          try {
            await MySharedPreferences()
                .setUserDataString(UserData.fromJson(profileData));
          } catch (_) {}
          UserSummaryNotifier.update(userSummary);
        }
      }

      setState(() {
        if (page == 1) {
          _initialLoadTimer?.cancel();
          _requests = newRequests;
          _loading = false;
        } else {
          _requests.addAll(newRequests);
          _loadingMore = false;
        }
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (page == 1) {
          _initialLoadTimer?.cancel();
          _loading = false;
          _error = 'Failed to load payment requests: ${e.toString()}';
          _requests = [];
        } else {
          _loadingMore = false;
        }
      });
    } finally {
      try {
        _initialLoadTimer?.cancel();
      } catch (_) {}
      try {
        loadMoreTimer?.cancel();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        color: AllCoustomTheme.getThemeData().colorScheme.surface,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading payment requests...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: AllCoustomTheme.getThemeData().colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: () => _loadRequests(page: 1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        _error ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Slide down to refresh',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return Container(
        color: AllCoustomTheme.getThemeData().colorScheme.surface,
        child: RefreshIndicator(
          onRefresh: () => _loadRequests(page: 1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No payment requests found',
                        style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Slide down to refresh',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      color: AllCoustomTheme.getThemeData().colorScheme.surface,
      child: RefreshIndicator(
        onRefresh: () => _loadRequests(page: 1),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Navigate to submit screen and refresh on return
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PaymentRequestScreen(),
                          ),
                        );
                        // Refresh list after returning from submit screen
                        await _loadRequests(page: 1);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Request'),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount:
                    _requests.length + (_currentPage < _lastPage ? 2 : 1),
                padding: const EdgeInsets.all(8.0),
                itemBuilder: (context, index) {
                  // Last item is pagination info + load more button
                  if (index == _requests.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Center(
                        child: Text(
                          'Showing ${_requests.length} of $_total requests (Page $_currentPage of $_lastPage)',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  // Load more button
                  if (index == _requests.length + 1) {
                    return _loadingMore
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AllCoustomTheme.getThemeData().primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _currentPage < _lastPage
                                    ? () =>
                                        _loadRequests(page: _currentPage + 1)
                                    : null,
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Load More'),
                              ),
                            ),
                          );
                  }

                  // Actual request item
                  final r = _requests[index];
                  final amount = r['amount']?.toString() ?? '';
                  final status =
                      r['status'] ?? r['payment_status'] ?? 'pending';
                  final method = r['payment_method'] ?? '';
                  final trx = r['transaction_number'] ?? r['trx_id'] ?? '';
                  final createdAt = r['created_at'] ?? r['created_time'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ListTile(
                      title:
                          Text('৳$amount - ${method.toString().toUpperCase()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6.0),
                          Text('Status: ${status.toString()}'),
                          if (trx.isNotEmpty) Text('Transaction: $trx'),
                          if (createdAt.isNotEmpty) Text('Date: $createdAt'),
                        ],
                      ),
                      trailing: Text(
                        status.toString().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
