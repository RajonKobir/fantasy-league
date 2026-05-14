import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/models/user_data.dart';
import 'package:fantasyleague/modules/login/slider_view.dart';
import 'package:fantasyleague/modules/login/registration_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:fantasyleague/modules/login/start_login_form_placeholder.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fantasyleague/validator/validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fantasyleague/utils/facebook_auth_helper.dart';
import 'package:fantasyleague/services/data_cache_service.dart';
import 'package:fantasyleague/constance/global.dart' as globals;

var loginUserData = UserData();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var isLoginType = '';
  var email = '';
  var name = '';
  var id = '';
  var imageUrl = '';

  var isLoginProsses = false;
  static const bool showFacebook = true; // toggle to hide/show button
  static const bool showGoogle = true; // toggle to hide/show button

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => isLoginProsses = true);
    try {
      final googleSignIn = GoogleSignIn(
        clientId: kIsWeb
            ? (dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '')
            : ((Theme.of(context).platform == TargetPlatform.iOS)
                ? dotenv.env['GOOGLE_CLIENT_ID_IOS']
                : dotenv.env['GOOGLE_CLIENT_ID_ANDROID']),
      );
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final auth = await account.authentication;
        final idToken = auth.idToken ?? auth.accessToken;
        if (idToken != null) {
          final resp = await ApiProvider().socialLogin('google', idToken);
          if (resp['token'] != null) {
            // Prefer server-provided user payload to avoid extra GET.
            if (resp['user'] != null) {
              try {
                loginUserData =
                    UserData.fromJson(Map<String, dynamic>.from(resp['user']));
              } catch (_) {}
            } else {
              try {
                final userResp = await ApiClient().get('user');
                loginUserData =
                    UserData.fromJson(Map<String, dynamic>.from(userResp.data));
              } catch (_) {}
            }
            if (mounted) setState(() => isLoginProsses = false);
            _preloadDataAndNavigate();
            return;
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
      }
    } catch (e) {
      Dialogs.showDialogWithOneButton(
          context, 'Error', 'Google login failed. Please try again.',
          onButtonPress: () {
        Navigator.pop(context);
      });
    } finally {
      if (mounted) setState(() => isLoginProsses = false);
    }
  }

  @override
  void initState() {
    super.initState();
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _handleFacebookSignIn() async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => isLoginProsses = true);
    try {
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);
      if (result.status == LoginStatus.success && result.accessToken != null) {
        final accessToken = fbAccessTokenString(result.accessToken);
        final resp = await ApiProvider().socialLogin('facebook', accessToken);
        if (resp['token'] != null) {
          // Require server-provided user payload; do not fallback to extra GET.
          if (resp['user'] != null) {
            try {
              loginUserData =
                  UserData.fromJson(Map<String, dynamic>.from(resp['user']));
              Fluttertoast.showToast(
                  msg: 'Login successful', toastLength: Toast.LENGTH_SHORT);
            } catch (_) {}
            if (mounted) setState(() => isLoginProsses = false);
            _preloadDataAndNavigate();
            return;
          } else {
            if (mounted) setState(() => isLoginProsses = false);
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
      if (mounted) setState(() => isLoginProsses = false);
    }
  }

  /// Pre-load important data (tournaments, user data) right after login for faster app performance
  Future<void> _preloadDataAndNavigate() async {
    try {
      // Pre-fetch tournaments in background while navigating
      DataCacheService().preloadTournaments();

      if (mounted) {
        // Navigate to home after user data is ready
        Navigator.pushReplacementNamed(context, Routes.TAB);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error pre-loading data: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, Routes.TAB);
      }
    }
  }

  Future<String> _debugInfo() async {
    try {
      final base = ApiClient().baseUrl;
      final envLoaded = dotenv.env.isNotEmpty ? 'env' : 'no-env';
      return 'base=$base | $envLoaded';
    } catch (_) {
      return 'no-debug';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globals.themeNotifier,
      builder: (context, child) {
        return Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AllCoustomTheme.getThemeData().primaryColor,
                    AllCoustomTheme.getThemeData().primaryColor,
                    AllCoustomTheme.getThemeData().colorScheme.surface,
                    AllCoustomTheme.getThemeData().colorScheme.surface,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Scaffold(
                backgroundColor:
                    AllCoustomTheme.getThemeData().colorScheme.surface,
                body: ModalProgressHUD(
                  inAsyncCall: isLoginProsses,
                  child: Stack(
                    children: <Widget>[
                      // Debug banner (only in debug mode) to help diagnose blank screen issues
                      if (const bool.fromEnvironment('dart.vm.product') ==
                          false)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 125),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FutureBuilder<String>(
                              future: _debugInfo(),
                              builder: (context, snap) {
                                return Text(
                                  snap.hasData ? snap.data! : 'loading...',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),

                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                color:
                                    AllCoustomTheme.getThemeData().primaryColor,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const SizedBox(
                                      height: 50,
                                    ),
                                    Image.asset(
                                      "assets/stump.png",
                                      height: 70,
                                    ),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    const Text(
                                      'Fantasy League',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Flexible(
                                      child: SliderView(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            // Facebook Button (hidden by flag)
                            if (showFacebook) ...[
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
                                      _handleFacebookSignIn();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12, bottom: 12),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              FontAwesomeIcons.facebookF,
                                              size: 18,
                                              color:
                                                  AllCoustomTheme.getThemeData()
                                                      .colorScheme
                                                      .surface,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Continue with Facebook',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize:
                                                    ConstanceData.SIZE_TITLE14,
                                                color: AllCoustomTheme
                                                        .getThemeData()
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
                              const SizedBox(height: 8),
                            ],
                            // Google Button (hidden by flag)
                            if (showGoogle) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8.0),
                                    onTap: () {
                                      _handleGoogleSignIn();
                                    },
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.only(top: 12, bottom: 12),
                                      child: Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            Icon(
                                              Icons.g_mobiledata,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Continue with Google',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize:
                                                    ConstanceData.SIZE_TITLE14,
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
                              const SizedBox(height: 8),
                            ],
                            // Email/Password Button
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    AllCoustomTheme.getThemeData().primaryColor,
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
                                    padding: const EdgeInsets.only(
                                        top: 12, bottom: 12),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.email,
                                            size: 18,
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .colorScheme
                                                    .surface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Login with Email',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize:
                                                  ConstanceData.SIZE_TITLE14,
                                              color:
                                                  AllCoustomTheme.getThemeData()
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
                            const SizedBox(height: 8),
                            // Register Button
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AllCoustomTheme.getThemeData()
                                      .primaryColor,
                                ),
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
                                            const RegistrationScreen(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 12, bottom: 12),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            Icons.person_add,
                                            size: 18,
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Create New Account',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize:
                                                  ConstanceData.SIZE_TITLE14,
                                              color:
                                                  AllCoustomTheme.getThemeData()
                                                      .primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service ',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE12,
                                        color: AllCoustomTheme.getThemeData()
                                            .primaryColor,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Privacy Policy.',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: ConstanceData.SIZE_TITLE12,
                                        color: AllCoustomTheme.getThemeData()
                                            .primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
