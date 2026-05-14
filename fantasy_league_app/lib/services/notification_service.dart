import 'dart:async';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:fantasyleague/models/notification.dart';

/// NotificationService - Handles polling for new notifications from backend
///
/// Features:
/// - Automatically polls backend every 30 seconds
/// - Notifies listeners when new notifications arrive
/// - Caches unread count for badge display
/// - Stops polling when app is inactive (saves battery)
///
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  final ApiProvider _apiProvider = ApiProvider();
  Timer? _pollTimer;

  List<NotificationData> _notifications = [];
  int _unreadCount = 0;

  /// Stream to notify UI of notification updates
  final StreamController<List<NotificationData>> _notificationController =
      StreamController<List<NotificationData>>.broadcast();

  /// Stream to notify UI of unread count changes
  final StreamController<int> _unreadCountController =
      StreamController<int>.broadcast();

  /// Private constructor for singleton pattern
  NotificationService._internal();

  /// Get singleton instance
  factory NotificationService() {
    return _instance;
  }

  /// Stream of notifications
  Stream<List<NotificationData>> get notificationsStream =>
      _notificationController.stream;

  /// Stream of unread count
  Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Get current notifications
  List<NotificationData> get notifications => _notifications;

  /// Get current unread count
  int get unreadCount => _unreadCount;

  /// Start polling for notifications
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    // Stop existing timer if running
    stopPolling();

    // Fetch immediately
    _fetchNotifications();

    // Then poll at regular intervals
    _pollTimer = Timer.periodic(interval, (_) {
      _fetchNotifications();
    });
  }

  /// Start polling for notifications with a default interval of 5 minutes
  void startPollingWithDefault() {
    startPolling(interval: const Duration(seconds: 300));
  }

  /// Stop polling
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Force refresh notifications
  Future<void> refreshNotifications() async {
    await _fetchNotifications();
  }

  /// Private method to fetch notifications from backend
  Future<void> _fetchNotifications() async {
    try {
      final response = await _apiProvider.notificationApiDataList();

      if (response.notificationData != null) {
        _notifications = response.notificationData!;

        // Calculate unread count (notifications without read_at)
        _unreadCount = _notifications.where((n) => n.readAt == null).length;

        // Notify listeners
        _notificationController.add(_notifications);
        _unreadCountController.add(_unreadCount);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error fetching notifications: $e');
      // Don't close the stream on error, just skip this poll
    }
  }

  /// Mark notification as read
  void markAsRead(int index) {
    if (index < _notifications.length) {
      _notifications[index].readAt = DateTime.now().toIso8601String();
      _unreadCount = _notifications.where((n) => n.readAt == null).length;
      _unreadCountController.add(_unreadCount);
      _notificationController.add(_notifications);
    }
  }

  /// Cleanup resources
  void dispose() {
    stopPolling();
    _notificationController.close();
    _unreadCountController.close();
  }
}
