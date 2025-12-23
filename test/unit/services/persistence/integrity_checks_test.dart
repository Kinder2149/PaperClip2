import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/models/save_game.dart' as model;
import 'package:paperclip2/models/save_metadata.dart';

import '../../../helpers/in_memory_save_manager.dart';

model.SaveGame _save({
  required String id,
  required String name,
  Map<String, dynamic>? data,
  String version = '1.0.3',
  GameMode mode = GameMode.INFINITE,
}) {
  return model.SaveGame(
    id: id,
    name: name,
    lastSaveTime: DateTime.now(),
    gameData: data ?? <String, dynamic>{},
    version: version,
    gameMode: mode,
  );
}

SaveMetadata _meta({
  required String id,
  required String name,
  String version = '1.0.3',
  GameMode mode = GameMode.INFINITE,
}) {
  return SaveMetadata(
    id: id,
    name: name,
    creationDate: DateTime.now().subtract(const Duration(days: 1)),
    lastModified: DateTime.now(),
    version: version,
    gameMode: mode,
    isRestored: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Integrity checks', () {
    late InMemorySaveGameManager mem;

    setUp(() {
      mem = InMemorySaveGameManager();
      SaveManagerAdapter.setSaveManagerForTesting(mem);
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('Détecte snapshot manquant et JSON invalide', () async {
      // 1) Snapshot manquant
      await mem.saveGame(_save(id: 's1', name: 'no-snapshot', data: {}));
      await mem.updateSaveMetadata('s1', _meta(id: 's1', name: 'no-snapshot'));
      // 2) Snapshot format invalide (int)
      final key = LocalGamePersistenceService.snapshotKey;
      await mem.saveGame(_save(id: 's2', name: 'bad-snapshot', data: {key: 42}));
      await mem.updateSaveMetadata('s2', _meta(id: 's2', name: 'bad-snapshot'));

      await expectLater(
        () async => GamePersistenceOrchestrator.instance.runIntegrityChecks(),
        prints(contains('INTEGRITY ERROR: Snapshot manquant')),
      );
    });

    test('Détecte doublons de nom vers IDs distincts', () async {
      await mem.saveGame(_save(id: 'a1', name: 'dup-name'));
      await mem.updateSaveMetadata('a1', _meta(id: 'a1', name: 'dup-name'));
      await mem.saveGame(_save(id: 'a2', name: 'dup-name'));
      await mem.updateSaveMetadata('a2', _meta(id: 'a2', name: 'dup-name'));

      await expectLater(
        () async => GamePersistenceOrchestrator.instance.runIntegrityChecks(),
        prints(contains('INTEGRITY WARNING: Noms en doublon')),
      );
    });

    test('Vérifie format backups, orphelins et rétention', () async {
      // Regular save present for r1, absent for orphan o1
      await mem.saveGame(_save(id: 'r1', name: 'regular-1', data: {LocalGamePersistenceService.snapshotKey: {'core': {}, 'stats': {}}}));
      await mem.updateSaveMetadata('r1', _meta(id: 'r1', name: 'regular-1'));

      // Backups
      final badFormat = 'r1${GameConstants.BACKUP_DELIMITER}not_a_number';
      final good1 = 'r1${GameConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';
      final orphan = 'o1${GameConstants.BACKUP_DELIMITER}${DateTime.now().millisecondsSinceEpoch}';

      await mem.saveGame(_save(id: 'b1', name: badFormat));
      await mem.updateSaveMetadata('b1', _meta(id: 'b1', name: badFormat));

      await mem.saveGame(_save(id: 'b2', name: good1));
      await mem.updateSaveMetadata('b2', _meta(id: 'b2', name: good1));

      await mem.saveGame(_save(id: 'b3', name: orphan));
      await mem.updateSaveMetadata('b3', _meta(id: 'b3', name: orphan));

      await expectLater(
        () async => GamePersistenceOrchestrator.instance.runIntegrityChecks(),
        prints(contains('INTEGRITY WARNING: Backup orphelin')),
      );
    });

    test('Détecte désalignements meta/save (name, version, gameMode)', () async {
      // Save et meta décalés
      await mem.saveGame(_save(id: 'm1', name: 'save-name', version: '1.0.3', mode: GameMode.INFINITE));
      await mem.updateSaveMetadata('m1', _meta(id: 'm1', name: 'meta-name', version: '2.0.0', mode: GameMode.COMPETITIVE));

      await expectLater(
        () async => GamePersistenceOrchestrator.instance.runIntegrityChecks(),
        prints(allOf(
          contains('INTEGRITY WARNING: Désalignement name meta="meta-name" vs save="save-name"'),
          contains('INTEGRITY WARNING: Version meta=2.0.0 vs save=1.0.3'),
          contains('INTEGRITY WARNING: GameMode meta=GameMode.COMPETITIVE vs save=GameMode.INFINITE'),
        )),
      );
    });
  });
}
