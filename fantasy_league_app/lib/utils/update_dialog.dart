import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showUpdateDialog(
    BuildContext context, Map<String, dynamic> data) async {
  final minVersion = data['min_version']?.toString() ?? '';
  final force = data['force_update'] == true;
  final updateUrl = data['update_url']?.toString() ?? '';

  // Prevent stacking multiple dialogs
  if (ModalRoute.of(context)?.isCurrent != true) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: !force,
    builder: (ctx) {
      return PopScope(
        canPop: !force,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
        },
        child: AlertDialog(
          title: const Text('Update Required'),
          content: Text(
            force
                ? 'A new required update is available. Please update to continue.\nMinimum version: $minVersion'
                : 'A new version is available. Please update to enjoy the latest features.\nMinimum version: $minVersion',
          ),
          actions: <Widget>[
            if (!force)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Later'),
              ),
            TextButton(
              onPressed: updateUrl.isNotEmpty
                  ? () async {
                      final uri = Uri.tryParse(updateUrl);
                      if (uri != null) {
                        try {
                          final launched = await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          if (!launched) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Could not open update link.')));
                          }
                        } catch (_) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Could not open update link.')));
                        }
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('Invalid update URL.')));
                      }
                      if (!force) Navigator.of(ctx).pop();
                    }
                  : null,
              child: const Text('Update'),
            ),
          ],
        ),
      );
    },
  );
}
