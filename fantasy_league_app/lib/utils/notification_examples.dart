/// Notification System Examples & Documentation
/// 
/// This file shows examples of how to use the in-app notification system.
/// The app provides the following notification approaches:
/// 
/// 1. AppNotification (Flushbar-based) - Modern top-positioned notifications
/// 2. OverlayNotification (Dialog-based) - Alternative custom overlay notifications

// ============================================================================
// EXAMPLE 1: Using AppNotification (Recommended)
// ============================================================================
// 
// AppNotification provides a clean, Material Design-compliant notification
// system using Flushbar. It's the recommended approach for most use cases.
//
// Basic usage:
// ```dart
// import 'package:fantasyleague/utils/notification_service.dart';
// import 'package:flutter/material.dart';
//
// void exampleSuccessNotification(BuildContext context) {
//   AppNotification.showSuccess(
//     context,
//     title: 'Success!',
//     message: 'Team created successfully',
//     duration: const Duration(seconds: 3),
//   );
// }
//
// void exampleErrorNotification(BuildContext context) {
//   AppNotification.showError(
//     context,
//     title: 'Error',
//     message: 'Failed to delete team',
//     duration: const Duration(seconds: 4),
//   );
// }
//
// void exampleWarningNotification(BuildContext context) {
//   AppNotification.showWarning(
//     context,
//     title: 'Warning',
//     message: 'Please verify your account',
//     duration: const Duration(seconds: 3),
//   );
// }
//
// void exampleInfoNotification(BuildContext context) {
//   AppNotification.showInfo(
//     context,
//     title: 'Information',
//     message: 'Team updated successfully',
//     duration: const Duration(seconds: 3),
//   );
// }
//
// // Notification with tap action
// void exampleNotificationWithAction(BuildContext context) {
//   AppNotification.showSuccess(
//     context,
//     title: 'Payment Received',
//     message: 'You have received ৳500',
//     onTap: () {
//       // Handle tap action
//       Navigator.pushNamed(context, '/wallet');
//     },
//   );
// }
// ```

// ============================================================================
// EXAMPLE 2: Using OverlayNotification (Alternative)
// ============================================================================
//
// OverlayNotification provides an alternative using custom dialogs.
// Use this if you prefer a different UI style.
//
// Basic usage:
// ```dart
// import 'package:fantasyleague/utils/overlay_notification.dart';
// import 'package:flutter/material.dart';
//
// void exampleOverlayNotification(BuildContext context) async {
//   await showOverlayNotification(
//     context,
//     title: 'Profile Updated',
//     message: 'Your profile has been updated',
//     style: NotificationStyle.success,
//     duration: const Duration(seconds: 3),
//   );
// }
// ```

// ============================================================================
// EXAMPLE 3: Integration in API Calls
// ============================================================================
//
// Common pattern for showing notifications after API operations:
//
// ```dart
// import 'package:fantasyleague/api/api_provider.dart';
// import 'package:fantasyleague/utils/notification_service.dart';
// import 'package:flutter/material.dart';
//
// Future<void> submitTeamWithNotification(
//   BuildContext context,
//   Map<String, dynamic> teamData,
// ) async {
//   try {
//     final response = await ApiProvider().submitTeam(teamData);
//     
//     if (context.mounted) {
//       AppNotification.showSuccess(
//         context,
//         title: 'Success',
//         message: 'Team submitted successfully',
//       );
//     }
//   } catch (e) {
//     if (context.mounted) {
//       AppNotification.showError(
//         context,
//         title: 'Error',
//         message: 'Failed to submit team: ${e.toString()}',
//       );
//     }
//   }
// }
// ```

// ============================================================================
// EXAMPLE 4: Form Validation Notifications
// ============================================================================
//
// Show validation errors to users:
//
// ```dart
// void validateFormWithNotification(BuildContext context, String? errorMessage) {
//   if (errorMessage != null) {
//     AppNotification.showWarning(
//       context,
//       title: 'Validation Error',
//       message: errorMessage,
//     );
//   }
// }
// ```

// ============================================================================
// EXAMPLE 5: Payment/Transaction Notifications
// ============================================================================
//
// Specific patterns for payment-related notifications:
//
// ```dart
// void showPaymentNotification(
//   BuildContext context,
//   bool success,
//   String amount,
// ) {
//   if (success) {
//     AppNotification.showSuccess(
//       context,
//       title: 'Payment Successful',
//       message: '৳$amount transferred',
//     );
//   } else {
//     AppNotification.showError(
//       context,
//       title: 'Payment Failed',
//       message: 'Transaction could not be completed',
//     );
//   }
// }
// ```

// ============================================================================
// MIGRATION: Replacing SnackBar with AppNotification
// ============================================================================
//
// Old SnackBar approach:
// ```dart
// ScaffoldMessenger.of(context).showSnackBar(
//   SnackBar(content: Text('Team deleted successfully'))
// );
// ```
//
// New AppNotification approach:
// ```dart
// AppNotification.showSuccess(
//   context,
//   title: 'Team Deleted',
//   message: 'Team deleted successfully',
// );
// ```

// ============================================================================
// NOTIFICATION TYPES
// ============================================================================
//
// AppNotification provides four types:
//
// 1. SUCCESS - Green background, checkmark icon
//    AppNotification.showSuccess(context, title: '...', message: '...')
//
// 2. ERROR - Red background, error icon
//    AppNotification.showError(context, title: '...', message: '...')
//
// 3. WARNING - Orange/amber background, warning icon
//    AppNotification.showWarning(context, title: '...', message: '...')
//
// 4. INFO - Blue background, info icon
//    AppNotification.showInfo(context, title: '...', message: '...')
//
// All methods accept optional parameters:
// - duration: Duration for auto-dismiss (default: 3 seconds)
// - onTap: VoidCallback for tap actions
// - dismissible: bool to allow swipe-to-dismiss (default: true)

// ============================================================================
// INSTALLATION & SETUP
// ============================================================================
//
// 1. The notification system is already integrated in the app
// 2. Just import the notification service:
//    import 'package:fantasyleague/utils/notification_service.dart';
// 3. Call the appropriate method with BuildContext
// 4. System handles all styling and display logic




