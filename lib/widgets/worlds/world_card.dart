import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paperclip2/services/persistence/save_aggregator.dart' show SaveEntry;

/// Carte réutilisable pour l'affichage d'un monde dans la liste "Mes Mondes".
class WorldCard extends StatelessWidget {
  final SaveEntry entry;
  final String cloudState; // canonical: cloud_synced | cloud_pending | cloud_error | local_only
  final String cloudLabel;
  final int backupCount;
  final bool canLoad;
  final VoidCallback onPlay;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onDownload; // action pour cloud-only
  final VoidCallback? onRetry; // action pour relancer la sync cloud

  const WorldCard({
    super.key,
    required this.entry,
    required this.cloudState,
    required this.cloudLabel,
    this.backupCount = 0,
    required this.canLoad,
    required this.onPlay,
    required this.onRename,
    required this.onDelete,
    this.onRestore,
    this.onDownload,
    this.onRetry,
  });

  Color _cloudColor() {
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
    final theme = Theme.of(context);
    final lastModified = entry.lastModified?.toLocal();
    final lastText = lastModified != null
        ? DateFormat.yMMMd().add_Hm().format(lastModified)
        : '—';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: canLoad ? onPlay : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : Nom + Cloud Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Cloud status badge compact
                  Container(
                    decoration: BoxDecoration(
                      color: _cloudColor(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_cloudIcon(), size: 14, color: Colors.black87),
                        const SizedBox(width: 4),
                        Text(
                          cloudLabel,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats row - Bien visible
              Row(
                children: [
                  _StatChip(
                    icon: Icons.content_cut,
                    label: 'Trombones',
                    value: entry.paperclips > 0 ? NumberFormat.compact().format(entry.paperclips) : '0',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.monetization_on_outlined,
                    label: 'Argent',
                    value: entry.money > 0 ? NumberFormat.compact().format(entry.money) : '0€',
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    icon: Icons.star_rounded,
                    label: 'Niveau',
                    value: 'Niv. ${entry.level}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Info row : Date + Version + Backups
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lastText,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  if (backupCount > 0) ...[
                    Icon(Icons.backup_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '$backupCount backup${backupCount > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    'v${entry.version}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Actions row
              Row(
                children: [
                  // Bouton principal : Jouer ou Télécharger
                  if (canLoad)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20),
                        label: const Text('Jouer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    )
                  else if (onDownload != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onDownload,
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: const Text('Télécharger'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Actions secondaires
                  IconButton(
                    tooltip: 'Renommer',
                    onPressed: onRename,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                  if (onRestore != null)
                    IconButton(
                      tooltip: 'Restaurer backup',
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore_outlined),
                    ),
                  if (onRetry != null)
                    IconButton(
                      tooltip: 'Retry sync cloud',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.orange),
                    ),
                  IconButton(
                    tooltip: 'Supprimer',
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget helper pour les stats
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
