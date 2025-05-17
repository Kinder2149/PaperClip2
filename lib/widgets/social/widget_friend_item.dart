// lib/widgets/social/widget_friend_item.dart
import 'package:flutter/material.dart';
import '../../models/social/friend_model.dart';

class WidgetFriendItem extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback onCompare;
  final VoidCallback onRemove;

  const WidgetFriendItem({
    Key? key,
    required this.friend,
    required this.onCompare,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: friend.photoUrl != null
                      ? NetworkImage(friend.photoUrl!)
                      : null,
                  child: friend.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Dernière activité: ${_formatLastActive(friend.lastActive)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Comparer'),
                  onPressed: onCompare,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer'),
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastActive(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 5) {
      return 'En ligne';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} minutes';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} heures';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}