import 'package:flutter/material.dart';
// import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';

class LegalityScreen extends StatelessWidget {
  const LegalityScreen({super.key});

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
                                'Legality',
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
                      'Important Legal Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    bullet(
                        'Users must be of legal age to participate in contests and use the app.'),
                    bullet(
                        'We comply with applicable laws and regulations; use in prohibited jurisdictions is not allowed.'),
                    bullet(
                        'All transactions are subject to verification and audit.'),
                    bullet(
                        'Disputes will be handled per our terms and support processes.'),
                    const SizedBox(height: 12),
                    const Text(
                      'Liability',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    bullet(
                        'The platform aims to provide accurate data, but we are not liable for third-party data discrepancies.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
