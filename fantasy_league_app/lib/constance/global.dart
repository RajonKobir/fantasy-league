import 'package:flutter/material.dart';
import 'package:fantasyleague/models/user_data.dart';

var primaryColorString = const Color(0xFF3EB489);

var secondaryColorString = const Color(0xFF3145f5);
var usertoken = '';
UserData? userdata;

List<String> colors = [
  '#4FBE9F',
  '#32a852',
  '#e6230e',
  '#760ee6',
  '#db0ee6',
  '#db164e'
];
int colorsIndex = 0;

// Custom ChangeNotifier to broadcast theme changes across the app
// (rebuilds interested widgets). Using ChangeNotifier instead of ValueNotifier
// because theme can change without colorsIndex changing (e.g., custom color picker)
class ThemeChangeNotifier extends ChangeNotifier {
  int _changeCount = 0;

  int get changeCount => _changeCount;

  void notifyThemeChange() {
    _changeCount++;
    notifyListeners();
  }
}

final ThemeChangeNotifier themeNotifier = ThemeChangeNotifier();

bool isHideTabBar = false;
