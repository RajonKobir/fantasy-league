import 'package:flutter/foundation.dart';

/// A simple global notifier to broadcast when the user summary cache is updated.
/// Value is the cached `user_summary` map or null.
class UserSummaryNotifier {
  static final ValueNotifier<Map<String, dynamic>?> notifier =
      ValueNotifier(null);

  static void update(Map<String, dynamic>? value) => notifier.value = value;
}
