import 'dart:async';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/modules/login/login_view.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:fantasyleague/utils/dialogs.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:fantasyleague/constance/themes.dart';

class LoginFormScreen extends StatefulWidget {
  const LoginFormScreen({super.key});

  @override
  _LoginFormScreenState createState() => _LoginFormScreenState();
}

class _LoginFormScreenState extends State<LoginFormScreen> {
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Rebuild when theme changes so AppBar updates immediately
    globals.themeNotifier.addListener(_onThemeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  void _handleLogin(String? email, String? password) async {
    if (email == null || password == null) return;
    setState(() {
      _isLoading = true;
    });

    Timer? loginTimer;
    try {
      // Add 12s timeout for login attempt to prevent spinner from hanging
      loginTimer = Timer(const Duration(seconds: 12), () {
        if (!mounted) return;
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
          Dialogs.showDialogWithOneButton(
            context,
            'Request Timeout',
            'Login request took too long. Please try again.',
            onButtonPress: () => Navigator.pop(context),
          );
        }
      });

      final resp = await ApiProvider().login(email, password);
      if (resp['token'] != null) {
        // Fetch current user to prime app state (best-effort)
        try {
          await ApiClient().get('/user');
        } catch (_) {}
        // Successful login; navigate to main tab
        Navigator.pushReplacementNamed(context, Routes.TAB);
      } else {
        Dialogs.showDialogWithOneButton(
          context,
          'Login failed',
          (resp['message'] ?? 'Unable to login').toString(),
          onButtonPress: () {
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      // Clean up "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      Dialogs.showDialogWithOneButton(
        context,
        'Login Failed',
        errorMessage,
        onButtonPress: () {
          Navigator.pop(context);
        },
      );
    } finally {
      loginTimer?.cancel();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: globals.themeNotifier,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Login',
              style: TextStyle(
                color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
              ),
            ),
            // Use custom theme so AppBar color changes with theme selection
            backgroundColor: AllCoustomTheme.getThemeData().primaryColor,
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: AllCoustomTheme.getReBlackAndWhiteThemeColors()),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ModalProgressHUD(
            inAsyncCall: _isLoading,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoginView(loginCallBack: _handleLogin),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }
}
