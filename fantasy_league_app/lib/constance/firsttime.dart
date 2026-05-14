import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:fantasyleague/constance/shared_preferences.dart';

class FirstTime {
  static getValues() async {
    globals.usertoken = (await MySharedPreferences().getUsertokenString())!;
    globals.userdata = await MySharedPreferences().getUserData();

    // Load persisted theme color and index if available
    try {
      final colorInt = await MySharedPreferences().getThemeColorInt();
      final idx = await MySharedPreferences().getThemeIndex();
      if (colorInt != null) {
        globals.primaryColorString = Color(colorInt);
        globals.secondaryColorString = globals.primaryColorString;
      }
      if (idx != null) {
        globals.colorsIndex = idx;
        // Notify listeners that the theme has changed so they rebuild correctly on app start
        globals.themeNotifier.notifyThemeChange();
      }
    } catch (_) {}
  }
}
