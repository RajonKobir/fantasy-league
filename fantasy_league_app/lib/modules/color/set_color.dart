import 'package:flutter/material.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/main.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

class set_colorScreen extends StatefulWidget {
  const set_colorScreen({super.key});

  @override
  _set_colorScreenState createState() => _set_colorScreenState();
}

class _set_colorScreenState extends State<set_colorScreen> {
  bool selectFirstColor = false;
  bool selectSecondColor = false;
  bool selectThirdColor = false;
  bool selectFourthColor = false;
  bool selectFifthColor = false;
  bool selectSixthColor = false;

  Color _currentColor = Colors.blue;
  final _controller = CircleColorPickerController(
    initialColor: globals.primaryColorString,
  );

  @override
  void initState() {
    super.initState();
    // Start with the persisted primary color
    _currentColor = globals.primaryColorString;
    // Try to update the picker controller safely using the supported property
    try {
      _controller.color = _currentColor;
    } catch (_) {}
    // Rebuild when global theme changes so this screen reflects the new theme immediately
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    setState(() {
      _currentColor = globals.primaryColorString;
      try {
        _controller.color = _currentColor;
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AllCoustomTheme.getThemeData().primaryColor,
            AllCoustomTheme.getThemeData().primaryColor,
            Colors.white,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).primaryColor,
          title: const Text(
            "Choose Color",
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: CircleColorPicker(
            controller: _controller,
            onEnded: (color) {
              setState(() {
                _currentColor = color;
              });
              MyApp.setCustomeTheme(context, 0, color: _currentColor);
            },
            size: const Size(240, 240),
            strokeWidth: 4,
            thumbSize: 36,
          ),
        ),
      ),
    );
  }

  selectfirstColor() {
    if (selectFirstColor) {
      setState(() {
        selectFirstColor = false;
        selectSecondColor = false;
        selectThirdColor = false;
        selectFourthColor = false;
        selectFifthColor = false;
        selectSixthColor = false;
      });
      MyApp.setCustomeTheme(context, 0);
    }
  }

  selectsecondColor() {
    if (!selectSecondColor) {
      setState(() {
        selectFirstColor = true;
        selectSecondColor = true;
        selectThirdColor = false;
        selectFourthColor = false;
        selectFifthColor = false;
        selectSixthColor = false;
      });
      MyApp.setCustomeTheme(context, 1);
    }
  }

  selectthirdColor() {
    if (!selectThirdColor) {
      setState(() {
        selectFirstColor = true;
        selectSecondColor = false;
        selectThirdColor = true;
        selectFourthColor = false;
        selectFifthColor = false;
        selectSixthColor = false;
      });
    }
    MyApp.setCustomeTheme(context, 2);
  }

  selectfourthColor() {
    if (!selectFourthColor) {
      setState(() {
        selectFirstColor = true;
        selectSecondColor = false;
        selectThirdColor = false;
        selectFourthColor = true;
        selectFifthColor = false;
        selectSixthColor = false;
      });
    }
    MyApp.setCustomeTheme(context, 3);
  }

  selectfifthColor() {
    if (!selectFifthColor) {
      setState(() {
        selectFirstColor = true;
        selectSecondColor = false;
        selectThirdColor = false;
        selectFourthColor = false;
        selectFifthColor = true;
        selectSixthColor = false;
      });
    }
    MyApp.setCustomeTheme(context, 4);
  }

  selectsixthColor() {
    if (!selectSixthColor) {
      setState(() {
        selectFirstColor = true;
        selectSecondColor = false;
        selectThirdColor = false;
        selectFourthColor = false;
        selectFifthColor = false;
        selectSixthColor = true;
      });
    }
    MyApp.setCustomeTheme(context, 5);
  }
}
