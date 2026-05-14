import 'package:flutter/material.dart';
import 'package:fantasyleague/utils/avatar_image.dart';

class PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onSelectCaptain;
  final VoidCallback? onSelectViceCaptain;
  final bool isCaptain;
  final bool isViceCaptain;

  const PlayerTile({
    super.key,
    required this.player,
    this.selected = false,
    this.onTap,
    this.onSelectCaptain,
    this.onSelectViceCaptain,
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          player['image_url'] != null && (player['image_url'] ?? '').isNotEmpty
              ? AvatarImage(
                  imageUrl: player['image_url'],
                  sizeValue: 40,
                  radius: 20,
                  isCircle: true,
                  entityType: 'player',
                )
              : const Icon(Icons.person),
      title: Text(player['name'] ?? player['title'] ?? ''),
      subtitle: Text(player['role'] ?? player['playing_role'] ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCaptain)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              child: const Text('C',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          if (isViceCaptain)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('VC',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          Checkbox(value: selected, onChanged: (_) => onTap?.call()),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'captain') onSelectCaptain?.call();
              if (v == 'vice') onSelectViceCaptain?.call();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'captain', child: Text('Set as Captain')),
              const PopupMenuItem(
                  value: 'vice', child: Text('Set as Vice Captain')),
            ],
          )
        ],
      ),
      onTap: onTap,
    );
  }
}
