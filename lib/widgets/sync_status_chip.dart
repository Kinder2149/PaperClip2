import 'package:flutter/material.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';

/// Widget discret affichant l'état de synchronisation global.
/// Mappe syncState ('ready' | 'syncing' | 'error') vers une puce minimaliste.
class SyncStatusChip extends StatelessWidget {
  final EdgeInsets padding;
  const SyncStatusChip({super.key, this.padding = const EdgeInsets.only(top: 8)});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: ValueListenableBuilder<String>(
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

  _Visual _map(String state, ThemeData theme) {
    switch (state) {
      case 'syncing':
        return _Visual(
          icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: 'Synchronisation…',
          bg: Colors.blue.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueAccent) ?? const TextStyle(fontSize: 12),
        );
      case 'error':
        return _Visual(
          icon: const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
          label: 'Erreur de sync',
          bg: Colors.amber.withOpacity(0.10),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber) ?? const TextStyle(fontSize: 12),
        );
      case 'ready':
      default:
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
