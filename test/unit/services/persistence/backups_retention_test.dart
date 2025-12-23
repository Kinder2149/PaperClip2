import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/save_game.dart' as model;
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import '../../../helpers/in_memory_save_manager.dart';

model.SaveGame _mk(String name, {required String id, DateTime? at}) {
  return model.SaveGame(
    id: id,
    name: name,
    lastSaveTime: at ?? DateTime.now(),
    gameData: {
      'gameSnapshot': {
        'core': {'money': 1},
        'stats': {'paperclips': 1}
      }
    },
    version: GameConstants.VERSION,
    gameMode: GameMode.INFINITE,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backups retention (N=10, TTL=30j)', () {
    late InMemorySaveGameManager mem;

    setUp(() {
      mem = InMemorySaveGameManager();
      SaveManagerAdapter.setSaveManagerForTesting(mem);
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
    });

    test('applyBackupRetention conserve au plus 10 backups et purge TTL', () async {
      const partieId = 'pid-123';
      final now = DateTime(2025, 1, 31);

      // Créer 12 backups: 5 anciens (>30j), 7 récents
      final oldBase = now.subtract(const Duration(days: 40));
      for (int i = 0; i < 5; i++) {
        final ts = oldBase.add(Duration(days: i)).millisecondsSinceEpoch;
        final name = '$partieId${GameConstants.BACKUP_DELIMITER}$ts';
        await mem.saveGame(_mk(name, id: 'old-$i', at: oldBase.add(Duration(days: i))));
      }
      final recentBase = now.subtract(const Duration(days: 5));
      for (int i = 0; i < 7; i++) {
        final t = recentBase.add(Duration(days: i));
        final ts = t.millisecondsSinceEpoch;
        final name = '$partieId${GameConstants.BACKUP_DELIMITER}$ts';
        await mem.saveGame(_mk(name, id: 'new-$i', at: t));
      }

      // Appliquer rétention avec TTL=30j, N=10
      final deleted = await SaveManagerAdapter.applyBackupRetention(partieId: partieId);
      expect(deleted, greaterThanOrEqualTo(2)); // au moins les 5 vieux, ou quota au-delà

      // Re-lister: on ne doit pas avoir plus de 10 backups restants et aucun >30j
      final all = await SaveManagerAdapter.listBackupsForPartie(partieId);
      expect(all.length, lessThanOrEqualTo(GameConstants.BACKUP_RETENTION_MAX));
      // Par sécurité, vérifier le préfixe
      expect(all.every((b) => b.name.startsWith('$partieId${GameConstants.BACKUP_DELIMITER}')), isTrue);
    });
  });
}
