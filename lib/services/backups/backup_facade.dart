// lib/services/backups/backup_facade.dart

import 'package:flutter/foundation.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/save_game.dart' show SaveGameInfo;
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';

/// Façade légère pour découpler l'UI des APIs de persistance de backups.
/// Aucune logique métier nouvelle: délègue strictement aux adaptateurs existants.
class BackupFacade {
  const BackupFacade();

  /// Liste toutes les sauvegardes de type backup, triées par date (desc).
  Future<List<SaveGameInfo>> listBackups() async {
    final mgr = await LocalSaveGameManager.getInstance();
    final allMeta = await mgr.listSaves();
    final all = allMeta.map((meta) => SaveGameInfo(
      id: meta.id,
      name: meta.name,
      timestamp: meta.lastModified,
      version: meta.version,
      paperclips: 0,
      money: 0,
      totalPaperclipsSold: 0,
      autoClipperCount: 0,
      isBackup: meta.name.contains(GameConstants.BACKUP_DELIMITER),
      isRestored: meta.isRestored,
    )).toList();
    final backups = all.where((e) => e.isBackup).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return backups;
  }

  /// Regroupe les backups par enterpriseId extrait du nom (avant le délimiteur).
  Map<String, List<SaveGameInfo>> groupByEnterpriseId(List<SaveGameInfo> backups) {
    final map = <String, List<SaveGameInfo>>{};
    for (final b in backups) {
      final base = b.name.split(GameConstants.BACKUP_DELIMITER).first;
      map.putIfAbsent(base, () => <SaveGameInfo>[]).add(b);
    }
    return map;
  }

  /// Restaure une sauvegarde depuis un backup identifié par son nom.
  Future<bool> restoreFromBackup({required String backupName, required GameState state}) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.restoreFromBackup(backupName, state);
  }

  /// Supprime un backup par id technique.
  Future<void> deleteBackupById(String id) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.deleteSave(id);
  }

  /// Applique la politique de rétention sur un enterpriseId.
  Future<int> applyRetention({required String enterpriseId}) async {
    final mgr = await LocalSaveGameManager.getInstance();
    return mgr.applyBackupRetention(enterpriseId: enterpriseId);
  }
}
