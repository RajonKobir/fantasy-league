import 'package:flutter/material.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:fantasyleague/main.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LogOut {
  Future<void> logout(BuildContext context) async {
    try {
      // Call the backend logout endpoint to revoke the token
      final response = await ApiClient().post('/logout');
      debugPrint('Logout response: $response');

      // Clear local data
      globals.usertoken = '';
      globals.userdata = null;
      await MySharedPreferences().clearSharedPreferences();
      await const FlutterSecureStorage().delete(key: 'token');

      // Use global navigator key which works even if context is disposed
      debugPrint('Using global navigator to navigate to LOGIN');
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.LOGIN,
        (Route<dynamic> route) => false,
      );
      debugPrint('Navigation called successfully via global key');
    } catch (e) {
      // Even if API call fails, clear local data and redirect
      debugPrint('Logout error (clearing locally): $e');
      globals.usertoken = '';
      globals.userdata = null;
      await MySharedPreferences().clearSharedPreferences();
      await const FlutterSecureStorage().delete(key: 'token');

      // Use global navigator key
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.LOGIN,
        (Route<dynamic> route) => false,
      );

      // Show error message if navigator is available
      if (navigatorKey.currentContext != null &&
          navigatorKey.currentContext!.mounted) {
        Dialogs.showDialogWithOneButton(
          navigatorKey.currentContext!,
          "Warning",
          "Logged out locally, but couldn't reach server.",
          onButtonPress: () {},
        );
      }
    }
  }

  Future<void> backSplashScreen(BuildContext context) async {
    try {
      // Call the backend logout endpoint to revoke the token
      await ApiClient().post('/logout');

      // Clear local data
      globals.usertoken = '';
      globals.userdata = null;
      await MySharedPreferences().clearSharedPreferences();
      await const FlutterSecureStorage().delete(key: 'token');

      // Use global navigator key
      debugPrint('Using global navigator from backSplashScreen');
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.LOGIN,
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      // Even if API call fails, clear local data and redirect
      debugPrint('Logout error (backSplashScreen): $e');
      globals.usertoken = '';
      globals.userdata = null;
      await MySharedPreferences().clearSharedPreferences();
      await const FlutterSecureStorage().delete(key: 'token');

      // Use global navigator key
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        Routes.LOGIN,
        (Route<dynamic> route) => false,
      );
    }
  }
}
