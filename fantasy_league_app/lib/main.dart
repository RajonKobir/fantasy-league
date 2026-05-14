import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fantasyleague/constance/firsttime.dart';
import 'package:fantasyleague/constance/global.dart' as globals;
import 'package:bloc/bloc.dart';
import 'package:fantasyleague/api/api_client.dart';
import 'package:fantasyleague/api/config_service.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/modules/home/tab_screen.dart';
import 'package:fantasyleague/modules/login/login_screen.dart';
import 'package:fantasyleague/modules/splash/splash_screen.dart';
// import 'package:fantasyleague/services/notification_service.dart';
import 'package:fantasyleague/utils/update_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fantasyleague/constance/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Global navigator key for navigation from anywhere without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class SimpleBlocDelegate extends BlocObserver {
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    // Only log errors to reduce overhead during normal operation
    debugPrint('Bloc error in ${bloc.runtimeType}: $error');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = SimpleBlocDelegate();

    // Load environment variables before initializing any services
    await dotenv.load(fileName: ".env").catchError((_) async {
      await dotenv.load(fileName: "env.test").catchError((_) {});
    });

    // Initialize API client after env is loaded
    const _buildDefineAppVersion =
        String.fromEnvironment('APP_VERSION', defaultValue: '');
    String _appVersionToPersist = _buildDefineAppVersion;
    try {
      if (_appVersionToPersist.isEmpty && dotenv.isInitialized) {
        final envV = dotenv.env['APP_VERSION'] ?? '';
        if (envV.isNotEmpty) _appVersionToPersist = envV;
      }
    } catch (_) {}

    if (_appVersionToPersist.isNotEmpty) {
      try {
        final _prefs = await SharedPreferences.getInstance();
        await _prefs.setString('app_version', _appVersionToPersist);
      } catch (e) {
        // Silently ignore persistence errors
      }
    }

    await ApiClient().init();

    // Minimal global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log full error details in debug builds for developer diagnostics
      if (kDebugMode) {
        debugPrint('Unhandled UI error: ${details.exceptionAsString()}');
        if (details.stack != null) debugPrint(details.stack.toString());
      }

      // Show a concise, user-friendly message to end users
      // In debug mode show the real exception message in-app to help debugging.
      final message = kDebugMode
          ? details.exceptionAsString()
          : 'An unexpected error occurred. Please restart the app or contact support.';
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    };

    // Set preferred orientations but do not await to keep startup snappy
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((_) {});

    // Run app immediately
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error');
    debugPrint(stack.toString());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static setCustomeTheme(BuildContext context, int index, {Color? color}) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    // Use safe call and allow nullable color; callers may omit color intentionally
    state?.setCustomeTheme(index, color: color);
  }

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Apply status bar style once (avoid doing this on every build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness:
            AllCoustomTheme.isLight ? Brightness.dark : Brightness.light,
      ));
    });

    // Listen to persisted theme changes so the app rebuilds when FirstTime sets the theme
    globals.themeNotifier.addListener(_onThemeChanged);

    // Non-blocking background initializations
    Future.microtask(() async {
      try {
        await FirstTime.getValues();
      } catch (_) {}
      try {
        await ConfigService().init();
      } catch (_) {}
      try {
        // Register update required callback to show blocking dialog
        ApiClient().onUpdateRequired = (data) {
          final ctx = navigatorKey.currentState?.overlay?.context ??
              navigatorKey.currentContext;
          if (ctx != null) {
            showUpdateDialog(ctx, Map<String, dynamic>.from(data));
          }
        };
      } catch (_) {}
      try {
        // Notification polling disabled for now - will implement Firebase FCM instead
        // NotificationService().startPolling();
      } catch (_) {}
    });
  }

  void setCustomeTheme(int index, {Color? color}) {
    setState(() {
      if (index == 6) {
        AllCoustomTheme.isLight = true;
      } else if (index == 7) {
        AllCoustomTheme.isLight = false;
      }
      globals.colorsIndex = index;
      globals.primaryColorString = color ?? const Color(0xFF4FBE9F);
      globals.secondaryColorString = globals.primaryColorString;
    });

    // Persist theme choices so they survive app restarts
    try {
      MySharedPreferences().setThemeIndex(index);
      // Persist the primary color using the native ARGB integer value
      // (toARGB32() returns the ARGB 32-bit integer representation).
      MySharedPreferences()
          .setThemeColorInt(globals.primaryColorString.toARGB32());
    } catch (_) {}

    // Always notify interested widgets that the theme has changed so they can rebuild immediately
    try {
      globals.themeNotifier.notifyThemeChange();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = AllCoustomTheme.getThemeData();
    // Use ValueKey driven by the theme change count to force a full rebuild
    // of the widget tree when the theme changes. This ensures any `const`
    // subtrees that depend on the theme are rebuilt when the user selects
    // a new color in the Set Color screen.
    return Container(
      color: theme.primaryColor,
      child: MaterialApp(
        key: ValueKey(globals.themeNotifier.changeCount),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Fantasy League',
        theme: theme,
        initialRoute: Routes.LOGIN,
        routes: routes,
      ),
    );
  }

  @override
  void dispose() {
    try {
      globals.themeNotifier.removeListener(_onThemeChanged);
    } catch (_) {}
    super.dispose();
  }

  void _onThemeChanged() {
    // Rebuild the app when theme notifier changes (e.g., persisted theme loaded at startup)
    try {
      setState(() {});
    } catch (_) {}
  }

  var routes = <String, WidgetBuilder>{
    Routes.SPLASH: (BuildContext context) => const SplashScreen(),
    Routes.LOGIN: (BuildContext context) => const LoginScreen(),
    Routes.TAB: (BuildContext context) => const TabScreen(),
  };
}
