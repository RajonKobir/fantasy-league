import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class AllCoustomTheme {
  static bool isLight = true;

  static ThemeData getThemeData() {
    if (isLight) {
      return buildLightTheme();
    } else {
      return buildDarkTheme();
    }
  }

  static Color getTextThemeColors() {
    if (isLight) {
      return const Color(0xFF9E9E9E);
    } else {
      return const Color(0xFF636466);
    }
  }

  static Color getBlackAndWhiteThemeColors() {
    if (isLight) {
      return Colors.black;
    } else {
      return Colors.white;
    }
  }

  static Color getReBlackAndWhiteThemeColors() {
    if (isLight) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  static ThemeData buildDarkTheme() {
    Color primaryColor = (globals.primaryColorString);
    Color secondaryColor = (globals.secondaryColorString);
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
    );
    final ThemeData base = ThemeData.dark();
    return base.copyWith(
      popupMenuTheme: const PopupMenuThemeData(color: Colors.black),
      appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          elevation: 0,
          titleTextStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600),
          iconTheme: const IconThemeData(color: Colors.white)),
      primaryColor: primaryColor,
      splashColor: Colors.white24,
      splashFactory: InkRipple.splashFactory,
      canvasColor: Colors.white,
      scaffoldBackgroundColor: Colors.grey[850],
      buttonTheme: ButtonThemeData(
        colorScheme: colorScheme,
        textTheme: ButtonTextTheme.primary,
      ),
      platform: TargetPlatform.iOS,
      colorScheme: colorScheme.copyWith(surface: Colors.grey[850]),
      tabBarTheme: const TabBarThemeData(indicatorColor: Colors.white),
    );
  }

  static ThemeData buildLightTheme() {
    Color primaryColor = (globals.primaryColorString);
    Color secondaryColor = (globals.secondaryColorString);
    final ColorScheme colorScheme = const ColorScheme.light().copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
    );
    final ThemeData base = ThemeData.light();
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      primaryColor: primaryColor,
      splashColor: Colors.white24,
      splashFactory: InkRipple.splashFactory,
      canvasColor: Colors.white,
      scaffoldBackgroundColor: const Color(0xFFEFF1F4),
      buttonTheme: ButtonThemeData(
        colorScheme: colorScheme,
        textTheme: ButtonTextTheme.primary,
      ),
      colorScheme: colorScheme
          .copyWith(surface: const Color(0xFFFFFFFF))
          .copyWith(error: const Color(0xFFB00020)),
      tabBarTheme: const TabBarThemeData(indicatorColor: Colors.white),
    );
  }
}
