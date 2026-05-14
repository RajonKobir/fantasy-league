import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/api/logout.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/modules/register/registerView.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  var isLoginProsses = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // allow back navigation
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Call your logout/back splash logic
        await LogOut().backSplashScreen(context);
      },
      child: Stack(
        children: <Widget>[
          Container(
            color: AllCoustomTheme.getThemeData().colorScheme.surface,
          ),
          SafeArea(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: ModalProgressHUD(
                inAsyncCall: isLoginProsses,
                child: Stack(
                  children: <Widget>[
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.only(top: 24),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 14),
                                child: Text(
                                  'Register',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 40,
                                    color: AllCoustomTheme.getThemeData()
                                        .primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            RegisterView(
                              callBack: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}




