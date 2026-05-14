import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fantasyleague/utils/avatar_image.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/utils/notification_service.dart';
import 'package:fantasyleague/utils/loader.dart';
import 'package:share_plus/share_plus.dart';

class TeamPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> team;

  const TeamPreviewScreen({super.key, required this.team});

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Team: ${team['team_name'] ?? team['name'] ?? ''}');
    if ((team['logo_url'] ?? team['logo'] ?? '').toString().isNotEmpty) {
      buffer.writeln('Logo: ${team['logo_url'] ?? team['logo']}');
    }
    buffer.writeln('Points: ${team['total_points'] ?? 0}');
    buffer.writeln('Players:');
    final players =
        team['players'] ?? team['player_list'] ?? team['player_ids'] ?? [];
    if (players is List) {
      for (var p in players) {
        if (p is Map) {
          final name = p['name'] ??
              p['full_name'] ??
              p['player_name'] ??
              p['title'] ??
              p['playerName'] ??
              p['pid'] ??
              p['id'] ??
              '';
          final id = p['id'] ?? p['pid'] ?? p['player_id'] ?? '';
          buffer.writeln('- ${name.toString()} (${id.toString()})');
        } else {
          buffer.writeln('- ${p.toString()}');
        }
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final logo = (team['logo_url'] ?? team['logo'] ?? '').toString();
    final points = (team['total_points'] ?? 0).toString();
    final players =
        team['players'] ?? team['player_list'] ?? team['player_ids'] ?? [];

    final canCancel = (team['status'] ?? '').toString() == 'approved' &&
        ((team['tournament']?['status'] ?? '').toString() == 'running' ||
            (team['tournament']?['status'] ?? '').toString() == 'active');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy summary',
            onPressed: () {
              final txt = _buildShareText();
              Clipboard.setData(ClipboardData(text: txt));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Team summary copied to clipboard')));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                logo.isNotEmpty
                    ? AvatarImage(
                        imageUrl: logo,
                        isCircle: true,
                        sizeValue: 64,
                        radius: 32,
                        entityType: 'team',
                      )
                    : const CircleAvatar(radius: 32, child: Icon(Icons.group)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Points: $points'),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            const Text('Players',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: players is List
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: players.length,
                      itemBuilder: (context, i) {
                        final p = players[i];
                        final playerMap =
                            p is Map ? p : {'id': p, 'name': p.toString()};
                        final pname = (playerMap['name'] ??
                                playerMap['full_name'] ??
                                playerMap['player_name'] ??
                                playerMap['title'] ??
                                '')
                            .toString();
                        final pid = (playerMap['id'] ??
                                playerMap['pid'] ??
                                playerMap['player_id'] ??
                                '')
                            .toString();
                        final isC = pid.isNotEmpty &&
                            pid ==
                                (team['captain_id'] ??
                                        team['captain'] ??
                                        team['captainId'] ??
                                        '')
                                    .toString();
                        final isV = pid.isNotEmpty &&
                            pid ==
                                (team['vice_captain_id'] ??
                                        team['vice_captain'] ??
                                        team['viceCaptainId'] ??
                                        '')
                                    .toString();
                        return ListTile(
                          title: Text(pname),
                          subtitle: Text(pid),
                          trailing:
                              Row(mainAxisSize: MainAxisSize.min, children: [
                            if (isC)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: const Text('C',
                                      style: TextStyle(color: Colors.white))),
                            if (isV)
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 4),
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.blueGrey,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: const Text('VC',
                                      style: TextStyle(color: Colors.white))),
                          ]),
                        );
                      })
                  : const Center(child: Text('No players')),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final txt = _buildShareText();
                      Clipboard.setData(ClipboardData(text: txt));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Team summary copied to clipboard')));
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: canCancel
                      ? 'Cancel and request refund'
                      : 'Cancel requests allowed only for admin-approved teams in running tournaments',
                  child: ElevatedButton.icon(
                    onPressed: canCancel
                        ? () => _confirmCancelAndRefund(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: canCancel ? Colors.white : Colors.grey,
                        foregroundColor: canCancel ? Colors.red : Colors.grey),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel & Refund'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final txt = _buildShareText();

                    await SharePlus.instance.share(
                      ShareParams(
                        text: txt,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancelAndRefund(BuildContext context) async {
    final teamId =
        (team['id'] ?? team['team_id'] ?? team['teamId'] ?? '').toString();
    if (teamId.isEmpty) {
      AppNotification.showError(context,
          title: 'Error', message: 'Invalid team ID');
      return;
    }
    // Client-side guard: only allow cancel when team is admin-approved and tournament running
    final teamStatus = (team['status'] ?? '').toString();
    final tournamentStatus = (team['tournament']?['status'] ?? '').toString();
    if (teamStatus != 'approved') {
      AppNotification.showError(context,
          title: 'Not allowed',
          message:
              'Cancel requests are allowed only for admin-approved teams.');
      return;
    }
    if (tournamentStatus != 'running' && tournamentStatus != 'active') {
      AppNotification.showError(context,
          title: 'Not allowed',
          message: 'Cancel requests are only allowed for running tournaments.');
      return;
    }

    final double refundPercentage;
    if (team['tournament'] is Map<String, dynamic>) {
      final tournament = team['tournament'] as Map<String, dynamic>;
      final rp = tournament['refund_percentage'] ?? 100.0;
      if (rp is num) {
        refundPercentage = rp.toDouble();
      } else if (rp is String) {
        refundPercentage = double.tryParse(rp) ?? 100.0;
      } else {
        refundPercentage = 100.0;
      }
    } else {
      refundPercentage = 100.0;
    }

    final double entryFee;
    if (team['tournament'] is Map<String, dynamic>) {
      final tournament = team['tournament'] as Map<String, dynamic>;
      final ef = tournament['entry_fee'] ?? 0.0;
      if (ef is num) {
        entryFee = ef.toDouble();
      } else if (ef is String) {
        entryFee = double.tryParse(ef) ?? 0.0;
      } else {
        entryFee = 0.0;
      }
    } else {
      entryFee = 0.0;
    }

    final refundAmount = entryFee * (refundPercentage / 100);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Team & Request Refund?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team: ${team['team_name'] ?? team['name'] ?? ''}'),
            const SizedBox(height: 12),
            const Text(
                'This will submit a cancel request for approval by the admin.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Refund Details:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800])),
                  const SizedBox(height: 8),
                  Text('Entry Fee: ৳${entryFee.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[700])),
                  // Refund percentage display removed as per requirements
                  const SizedBox(height: 8),
                  Text('You will receive: ৳${refundAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Cancel Request',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // show loader with timeout
    final hideLoader =
        await showTimedLoader(context, timeout: const Duration(seconds: 12));
    try {
      final result = await ApiProvider().submitCancelRequest(teamId);
      hideLoader(); // dismiss loader

      if (result['success'] == true) {
        await AppNotification.showSuccess(context,
            title: 'Cancel Request Submitted',
            message:
                'Your cancel request has been submitted for admin approval.');
        // close preview
        if (Navigator.canPop(context)) Navigator.pop(context);
      } else {
        await AppNotification.showError(context,
            title: 'Failed',
            message: result['message'] ?? 'Failed to submit cancel request');
      }
    } catch (e) {
      hideLoader();
      await AppNotification.showError(context,
          title: 'Error', message: 'An error occurred: $e');
    }
  }
}
