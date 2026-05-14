import 'package:flutter/material.dart';
import 'package:fantasyleague/modules/login/login_form_screen.dart';

// Small placeholder that immediately pushes the real login form screen. This allows
// reusing the button UI in FacebookGoogleView without directly importing the
// full LoginFormScreen file there (keeps a shallow dependency graph).
class StartLoginFormPlaceholder extends StatelessWidget {
  const StartLoginFormPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Push the actual login form screen.
    Future.microtask(() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginFormScreen()),
      );
    });

    // While waiting, show a blank scaffold to avoid rendering issues.
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
