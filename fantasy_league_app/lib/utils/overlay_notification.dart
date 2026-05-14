import 'package:flutter/material.dart';

/// Custom overlay notification widget for advanced use cases
class OverlayNotification extends StatefulWidget {
  final String title;
  final String? message;
  final NotificationStyle style;
  final Duration duration;
  final VoidCallback? onDismiss;
  final Widget? icon;

  const OverlayNotification({
    super.key,
    required this.title,
    this.message,
    this.style = NotificationStyle.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
    this.icon,
  });

  @override
  State<OverlayNotification> createState() => _OverlayNotificationState();
}

class _OverlayNotificationState extends State<OverlayNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _scheduleDissmiss();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();
  }

  void _scheduleDissmiss() {
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss?.call();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: widget.icon!,
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  _getIcon(),
                  color: _getTextColor(),
                  size: 24,
                ),
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: _getTextColor(),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.message!,
                        style: TextStyle(
                          color: _getTextColor().withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: _dismiss,
                child: Icon(
                  Icons.close,
                  color: _getTextColor(),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.style) {
      case NotificationStyle.success:
        return const Color(0xFF4CAF50);
      case NotificationStyle.error:
        return const Color(0xFFF44336);
      case NotificationStyle.warning:
        return const Color(0xFFFFC107);
      case NotificationStyle.info:
        return const Color(0xFF2196F3);
    }
  }

  Color _getTextColor() {
    switch (widget.style) {
      case NotificationStyle.warning:
        return Colors.black87;
      default:
        return Colors.white;
    }
  }

  IconData _getIcon() {
    switch (widget.style) {
      case NotificationStyle.success:
        return Icons.check_circle;
      case NotificationStyle.error:
        return Icons.error;
      case NotificationStyle.warning:
        return Icons.warning;
      case NotificationStyle.info:
        return Icons.info;
    }
  }
}

enum NotificationStyle { success, error, warning, info }

/// Show an overlay notification
Future<void> showOverlayNotification(
  BuildContext context, {
  required String title,
  String? message,
  NotificationStyle style = NotificationStyle.info,
  Duration duration = const Duration(seconds: 3),
  VoidCallback? onDismiss,
  Widget? icon,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: false,
    builder: (_) => OverlayNotification(
      title: title,
      message: message,
      style: style,
      duration: duration,
      onDismiss: onDismiss,
      icon: icon,
    ),
  );
}




