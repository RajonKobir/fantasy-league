import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fantasyleague/utils/notification_service.dart';

/// Simple loader controller that returns a dismiss function
class LoaderController {
  final void Function() dismiss;

  LoaderController({required this.dismiss});

  /// Compatibility method for calling as function
  void call() => dismiss();
}

/// Shows a modal blocking loader and returns a controller to dismiss it.
/// The loader will auto-dismiss after [timeout] and show a timeout notification.
Future<LoaderController> showTimedLoader(
  BuildContext context, {
  Duration timeout = const Duration(seconds: 12),
  String? timeoutTitle,
  String? timeoutMessage,
}) async {
  bool dismissed = false;
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Material(
      color: Colors.black26,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  );

  // Insert the overlay
  try {
    Overlay.of(context).insert(overlayEntry);
  } catch (e) {
    debugPrint('[showTimedLoader] Error inserting overlay: $e');
    // Return a no-op controller if Overlay fails
    return LoaderController(dismiss: () {});
  }

  final timer = Timer(timeout, () {
    if (!dismissed && overlayEntry != null) {
      dismissed = true;
      try {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      } catch (_) {}

      // Show timeout error
      try {
        AppNotification.showError(
          context,
          title: timeoutTitle ?? 'Timeout',
          message: timeoutMessage ?? 'Operation timed out. Please try again.',
        );
      } catch (_) {}
    }
  });

  // Return a controller with dismiss function
  return LoaderController(
    dismiss: () {
      if (dismissed) return;
      dismissed = true;
      timer.cancel();

      // Remove the overlay immediately
      try {
        if (overlayEntry != null && overlayEntry.mounted) {
          overlayEntry.remove();
        }
      } catch (e) {
        debugPrint('[LoaderController] Error removing overlay: $e');
      }
    },
  );
}
