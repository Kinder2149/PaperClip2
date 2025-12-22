import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/game_config.dart';
import '../models/game_state.dart';
import '../services/save_system/save_manager_adapter.dart';
import '../services/save_game.dart' show SaveGameInfo;

class BackupsHistoryScreen extends StatefulWidget {
  const BackupsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BackupsHistoryScreen> createState() => _BackupsHistoryScreenState();
}

class _BackupsHistoryScreenState extends State<BackupsHistoryScreen> {
  bool _loading = true;
  List<SaveGameInfo> _all = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await SaveManagerAdapter.listSaves();
      setState(() {
        _all = list.where((e) => e.isBackup).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Map<String, List<SaveGameInfo>> _groupByPartieId(List<SaveGameInfo> backups) {
    final map = <String, List<SaveGameInfo>>{};
    for (final b in backups) {
      final base = b.name.split(GameConstants.BACKUP_DELIMITER).first;
      map.putIfAbsent(base, () => []).add(b);
    }
    return map;
  }

  Future<void> _restoreBackup(SaveGameInfo b) async {
    try {
      final gs = context.read<GameState>();
      final ok = await SaveManagerAdapter.restoreFromBackup(b.name, gs);
      if (!ok) {
        _showSnack('Échec de la restauration');
        return;
      }
      _showSnack('Backup restauré');
      await _load();
    } catch (e) {
      _showSnack('Erreur restauration: $e');
    }
  }

  Future<void> _deleteBackup(SaveGameInfo b) async {
    try {
      await SaveManagerAdapter.deleteSaveById(b.id);
      _showSnack('Backup supprimé');
      await _load();
    } catch (e) {
      _showSnack('Erreur suppression: $e');
    }
  }

  Future<void> _applyRetention(String partieId) async {
    try {
      final n = await SaveManagerAdapter.applyBackupRetention(partieId: partieId);
      _showSnack('Rétention appliquée: $n supprimés');
      await _load();
    } catch (e) {
      _showSnack('Erreur rétention: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Backups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Erreur: $_error'))
              : _buildGroupedList(theme),
    );
  }

  Widget _buildGroupedList(ThemeData theme) {
    final groups = _groupByPartieId(_all);
    if (groups.isEmpty) {
      return const Center(child: Text('Aucun backup disponible'));
    }
    return ListView(
      children: groups.entries.map((e) {
        final partieId = e.key;
        final items = e.value..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ExpansionTile(
            title: Text('Partie $partieId'),
            subtitle: Text('Backups: ${items.length}'),
            trailing: TextButton.icon(
              onPressed: () => _applyRetention(partieId),
              icon: const Icon(Icons.cleaning_services),
              label: Text('Rétention N=${GameConstants.BACKUP_RETENTION_MAX}, TTL=${GameConstants.BACKUP_RETENTION_TTL.inDays}j'),
            ),
            children: items.map((b) {
              final ts = b.timestamp.toLocal().toString().split('.')[0];
              return ListTile(
                dense: true,
                title: Text(b.name.split(GameConstants.BACKUP_DELIMITER).last),
                subtitle: Text('Créé le: $ts  |  v${b.version}'),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore),
                      tooltip: 'Restaurer',
                      onPressed: () => _restoreBackup(b),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => _deleteBackup(b),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
