import 'package:flutter/material.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/sync_state.dart';

/// Widget discret affichant l'état de synchronisation global.
/// Utilise l'enum SyncState pour une gestion cohérente des états.
class SyncStatusChip extends StatelessWidget {
  final EdgeInsets padding;
  const SyncStatusChip({super.key, this.padding = const EdgeInsets.only(top: 8)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: ValueListenableBuilder<SyncState>(
        valueListenable: GamePersistenceOrchestrator.instance.syncState,
        builder: (context, state, _) {
          final _Visual v = _map(state, theme);
          return Container(
            decoration: BoxDecoration(
              color: v.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                v.icon,
                const SizedBox(width: 6),
                Text(v.label, style: v.style),
              ],
            ),
          );
        },
      ),
    );
  }

  _Visual _map(SyncState state, ThemeData theme) {
    switch (state) {
      case SyncState.syncing:
      case SyncState.downloading:
        return _Visual(
          icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: state == SyncState.downloading ? 'Téléchargement…' : 'Synchronisation…',
          bg: Colors.blue.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueAccent) ?? const TextStyle(fontSize: 12),
        );
      case SyncState.error:
        return _Visual(
          icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
          label: 'Erreur de synchronisation',
          bg: Colors.amber.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber) ?? const TextStyle(fontSize: 12),
        );
      case SyncState.pendingIdentity:
        return _Visual(
          icon: const Icon(Icons.person_off, size: 16, color: Colors.orange),
          label: 'Connexion requise',
          bg: Colors.orange.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange) ?? const TextStyle(fontSize: 12),
        );
      case SyncState.ready:
        return _Visual(
          icon: const Icon(Icons.cloud_done_rounded, size: 16, color: Colors.green),
          label: 'À jour',
          bg: Colors.green.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.green) ?? const TextStyle(fontSize: 12),
        );
    }
  }
}

class _Visual {
  final Widget icon;
  final String label;
  final Color bg;
  final TextStyle style;
  _Visual({required this.icon, required this.label, required this.bg, required this.style});
}
