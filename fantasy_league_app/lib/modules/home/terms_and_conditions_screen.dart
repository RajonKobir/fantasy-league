import 'package:flutter/material.dart';
// import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  Widget bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 20)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AllCoustomTheme.getThemeData().colorScheme.surface,
          body: Column(
            children: <Widget>[
              Container(
                color: AllCoustomTheme.getThemeData().primaryColor,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: AppBar().preferredSize.height,
                      child: Row(
                        children: <Widget>[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: SizedBox(
                                width: AppBar().preferredSize.height,
                                height: AppBar().preferredSize.height,
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                'Terms and Conditions',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: AppBar().preferredSize.height,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 6),
                    const Text(
                      'Summary of key terms',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    bullet(
                        'By using the app you agree to follow the rules and our privacy policy.'),
                    bullet(
                        'Wallet funds are subject to verification and may take time to reflect after transactions.'),
                    bullet(
                        'Users are responsible for maintaining account security and credentials.'),
                    bullet(
                        'Disputes and refunds are handled per our support and verification procedures.'),
                    bullet(
                        'We reserve the right to suspend or ban accounts that violate rules.'),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
