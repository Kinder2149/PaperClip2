import 'package:flutter/material.dart';
import 'package:paperclip2/services/saves/saves_facade.dart';
import 'package:intl/intl.dart';

class WorldListItem extends StatelessWidget {
  final SaveEntry entry;
  final String cloudState; // canonical: cloud_synced | cloud_pending | cloud_error | local_only
  final String cloudLabel;
  final int backupCount;
  final VoidCallback onPlay;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;

  const WorldListItem({
    super.key,
    required this.entry,
    required this.cloudState,
    required this.cloudLabel,
    this.backupCount = 0,
    required this.onPlay,
    required this.onRename,
    required this.onDelete,
    this.onRestore,
  });

  Color _cloudColor(BuildContext context) {
    switch (cloudState) {
      case 'cloud_synced':
        return Colors.green.shade100;
      case 'cloud_pending':
        return Colors.orange.shade100;
      case 'cloud_error':
        return Colors.red.shade100;
      case 'local_only':
      default:
        return Colors.grey.shade200;
    }
  }

  IconData _cloudIcon() {
    switch (cloudState) {
      case 'cloud_synced':
        return Icons.cloud_done_rounded;
      case 'cloud_pending':
        return Icons.cloud_upload_rounded;
      case 'cloud_error':
        return Icons.cloud_off_rounded;
      case 'local_only':
      default:
        return Icons.cloud_queue_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastModified = entry.lastModified?.toLocal();
    final lastText = lastModified != null
        ? DateFormat.yMMMd().add_Hm().format(lastModified)
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cloud badge
            Container(
              decoration: BoxDecoration(
                color: _cloudColor(context),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(_cloudIcon(), size: 16),
                  const SizedBox(width: 6),
                  Text(cloudLabel, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (backupCount > 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.backup_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('$backupCount', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Dernière sauvegarde locale: $lastText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version: ${entry.version}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Jouer',
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
                IconButton(
                  tooltip: 'Renommer',
                  onPressed: onRename,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                if (onRestore != null)
                  IconButton(
                    tooltip: 'Restaurer',
                    onPressed: onRestore,
                    icon: const Icon(Icons.restore_outlined),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
