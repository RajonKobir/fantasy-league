import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

enum NotificationType { success, error, warning, info }

class AppNotification {
  /// Show a success notification
  static Future<void> showSuccess(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    return _show(
      context,
      type: NotificationType.success,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show an error notification
  static Future<void> showError(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
  }) {
    return _show(
      context,
      type: NotificationType.error,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show a warning notification
  static Future<void> showWarning(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    return _show(
      context,
      type: NotificationType.warning,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Show an info notification
  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    return _show(
      context,
      type: NotificationType.info,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
    );
  }

  /// Generic notification method
  static Future<void> _show(
    BuildContext context, {
    required NotificationType type,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    final colors = _getColors(type);

    return Flushbar<void>(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: FlushbarPosition.TOP,
      backgroundColor: colors['bg'] as Color,
      titleColor: colors['text'] as Color,
      messageText: message != null
          ? Text(
              message,
              style: TextStyle(color: colors['text'] as Color),
            )
          : null,
      icon: Icon(
        colors['icon'] as IconData,
        color: colors['text'] as Color,
      ),
      borderRadius: BorderRadius.circular(8),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      onTap: (_) => onTap?.call(),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ).show(context);
  }

  static Map<String, dynamic> _getColors(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return {
          'bg': const Color(0xFF4CAF50),
          'text': Colors.white,
          'icon': Icons.check_circle,
        };
      case NotificationType.error:
        return {
          'bg': const Color(0xFFF44336),
          'text': Colors.white,
          'icon': Icons.error,
        };
      case NotificationType.warning:
        return {
          'bg': const Color(0xFFFFC107),
          'text': Colors.black87,
          'icon': Icons.warning,
        };
      case NotificationType.info:
        return {
          'bg': const Color(0xFF2196F3),
          'text': Colors.white,
          'icon': Icons.info,
        };
    }
  }
}




