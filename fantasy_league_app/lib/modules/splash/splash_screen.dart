import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/constance/themes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    _loadNextScreen();
    animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    animationController.forward();
    super.initState();
  }

  void _loadNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    Navigator.pushReplacementNamed(context, Routes.LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: AllCoustomTheme.getThemeData().primaryColor,
            ),
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
                minWidth: MediaQuery.of(context).size.width),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    "Fantasy League",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizeTransition(
                    sizeFactor: CurvedAnimation(
                        parent: animationController,
                        curve: Curves.fastOutSlowIn),
                    axis: Axis.vertical,
                    child: Container(
                      height: 150.0,
                    ),
                  ),
                  const CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
