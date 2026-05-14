import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:fantasyleague/validator/validator.dart';
import 'package:fantasyleague/modules/login/start_login_form_placeholder.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/facebook_auth_helper.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/modules/login/loginScreen.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FacebookGoogleView extends StatefulWidget {
  final loginCallBack;

  const FacebookGoogleView({super.key, this.loginCallBack});
  @override
  _FacebookGoogleViewState createState() => _FacebookGoogleViewState();
}

class _FacebookGoogleViewState extends State<FacebookGoogleView> {
  var emailtxt = '';
  var name = '';
  var id = '';
  var imageUrl = '';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
        inAsyncCall: _isProcessing,
        child: Container(
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 8,
              ),
              Container(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: HexColor('#4267B2'),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            _handleFacebookLogin();
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    FontAwesomeIcons.facebookF,
                                    size: 18,
                                    color: AllCoustomTheme.getThemeData()
                                        .colorScheme
                                        .surface,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Facebook',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ConstanceData.SIZE_TITLE14,
                                      color: AllCoustomTheme.getThemeData()
                                          .colorScheme
                                          .surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    // Google login button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            _handleGoogleLogin();
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(top: 12, bottom: 12),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.g_mobiledata,
                                    size: 18,
                                    color: Colors.red,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Google',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ConstanceData.SIZE_TITLE14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    // Email Login button (opens email login form)
                    Container(
                      decoration: BoxDecoration(
                        color: AllCoustomTheme.getThemeData().primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const StartLoginFormPlaceholder(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 12),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Icon(
                                    Icons.email,
                                    size: 18,
                                    color: AllCoustomTheme.getThemeData()
                                        .colorScheme
                                        .surface,
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Email Login',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ConstanceData.SIZE_TITLE14,
                                      color: AllCoustomTheme.getThemeData()
                                          .colorScheme
                                          .surface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                  ],
                ),
              )
            ],
          ),
        ));
  }

  Future<void> _handleFacebookLogin() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _isProcessing = true);
    try {
      if (kIsWeb) {
        // Ensure web init uses configured Facebook App ID
        final fbAppId = dotenv.env['FACEBOOK_APP_ID'] ?? '';
        if (fbAppId.isNotEmpty) {
          await (FacebookAuth.instance as dynamic).webInitialize(
            appId: fbAppId,
            cookie: true,
            xfbml: true,
            version: "v10.0",
          );
        }
      }
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);
      if (result.status == LoginStatus.success && result.accessToken != null) {
        final accessToken = fbAccessTokenString(result.accessToken);
        final resp = await ApiProvider().socialLogin('facebook', accessToken);
        if (resp['token'] != null) {
          // Require server-provided user payload; do not fallback to extra GET.
          if (resp['user'] != null) {
            try {
              globals.userdata =
                  UserData.fromJson(Map<String, dynamic>.from(resp['user']));
              Fluttertoast.showToast(
                  msg: 'Login successful', toastLength: Toast.LENGTH_SHORT);
            } catch (_) {}
            setState(() => _isProcessing = false);
            Navigator.pushReplacementNamed(context, Routes.TAB);
            return;
          } else {
            setState(() => _isProcessing = false);
            Dialogs.showDialogWithOneButton(context, 'Login failed',
                'Server did not return user data. Please try again.',
                onButtonPress: () {
              Navigator.pop(context);
            });
            return;
          }
        }
        Dialogs.showDialogWithOneButton(context, 'Login failed',
            (resp['message'] ?? 'Unable to login with Facebook').toString(),
            onButtonPress: () {
          Navigator.pop(context);
        });
      } else if (result.status == LoginStatus.cancelled) {
        // user cancelled
      } else {
        Dialogs.showDialogWithOneButton(
            context, 'Login failed', 'Facebook login failed',
            onButtonPress: () {
          Navigator.pop(context);
        });
      }
    } catch (e) {
      Dialogs.showDialogWithOneButton(
          context, 'Error', 'Facebook login failed. Please try again.',
          onButtonPress: () {
        Navigator.pop(context);
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => _isProcessing = true);
    try {
      final clientId = kIsWeb
          ? (dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '')
          : ((Theme.of(context).platform == TargetPlatform.iOS)
              ? dotenv.env['GOOGLE_CLIENT_ID_IOS']
              : dotenv.env['GOOGLE_CLIENT_ID_ANDROID']);

      // Client ID configuration is being used

      if (clientId == null || clientId.isEmpty) {
        Dialogs.showDialogWithOneButton(context, 'Configuration Error',
            'Google Client ID not found in .env file. Please check your configuration.',
            onButtonPress: () {
          Navigator.pop(context);
        });
        setState(() => _isProcessing = false);
        return;
      }

      final googleSignIn = GoogleSignIn(
        clientId: clientId,
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken ?? auth.accessToken;
        if (idToken != null) {
          final resp = await ApiProvider().socialLogin('google', idToken);
          if (resp['token'] != null) {
            if (resp['user'] != null) {
              try {
                globals.userdata =
                    UserData.fromJson(Map<String, dynamic>.from(resp['user']));
                Fluttertoast.showToast(
                    msg: 'Login successful', toastLength: Toast.LENGTH_SHORT);
              } catch (_) {}
              setState(() => _isProcessing = false);
              Navigator.pushReplacementNamed(context, Routes.TAB);
              return;
            } else {
              setState(() => _isProcessing = false);
              Dialogs.showDialogWithOneButton(context, 'Login failed',
                  'Server did not return user data. Please try again.',
                  onButtonPress: () {
                Navigator.pop(context);
              });
              return;
            }
          }
          Dialogs.showDialogWithOneButton(context, 'Login failed',
              (resp['message'] ?? 'Unable to login with Google').toString(),
              onButtonPress: () {
            Navigator.pop(context);
          });
        } else {
          Dialogs.showDialogWithOneButton(
              context, 'Login failed', 'Google did not return a token',
              onButtonPress: () {
            Navigator.pop(context);
          });
        }
      } else {
        // Google sign in was cancelled by user
      }
    } catch (e) {
      // Handle Google login error
      Dialogs.showDialogWithOneButton(
          context, 'Error', 'Google login failed: ${e.toString()}',
          onButtonPress: () {
        Navigator.pop(context);
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
