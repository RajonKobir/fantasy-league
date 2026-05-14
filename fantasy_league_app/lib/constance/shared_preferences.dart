import 'dart:async';
import 'dart:convert';
import 'package:fantasyleague/constance/constance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fantasyleague/constance/global.dart';
import 'package:fantasyleague/models/user_data.dart';

class MySharedPreferences {
  Future clearSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    return;
  }

  Future<String?> getUsertokenString() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(ConstanceData.Usertoken) == null) {
      await prefs.setString(ConstanceData.Usertoken, '');
    }
    return prefs.getString(ConstanceData.Usertoken);
  }

  Future<UserData?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(ConstanceData.UserData) == null) {
      await prefs.setString(ConstanceData.UserData, '');
    }
    var userDataTxt = prefs.getString(ConstanceData.UserData);
    if (userDataTxt != '') {
      UserData userData = UserData.fromJson(jsonDecode(userDataTxt!));
      return userData;
    } else {
      return userdata;
    }
  }

  Future setUserDataString(UserData userData) async {
    final usertxt = jsonEncode(userData);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(ConstanceData.UserData, usertxt);
  }

  /// Generic JSON cache setter. Stores a map as JSON string under the provided key.
  Future<void> setCacheJson(String key, Map<String, dynamic> value) async {
    final s = jsonEncode(value);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, s);
  }

  /// Generic JSON cache getter. Returns the parsed map or null if not present.
  Future<Map<String, dynamic>?> getCacheJson(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(key);
    if (s == null || s.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s));
    } catch (e) {
      return null;
    }
  }

  /// Remove a cached key
  Future<void> removeCache(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // Theme persistence helpers
  Future<void> setThemeColorInt(int colorValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_primary_color', colorValue);
  }

  Future<int?> getThemeColorInt() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('app_primary_color');
  }

  Future<void> setThemeIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('app_theme_index', index);
  }

  Future<int?> getThemeIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('app_theme_index');
  }
}
