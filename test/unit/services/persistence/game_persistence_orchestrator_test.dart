import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/save_game.dart' as model;
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/services/persistence/game_persistence_orchestrator.dart';
import 'package:paperclip2/services/persistence/game_snapshot.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';

class _UninitializedGameState extends GameState {
  @override
  bool get isInitialized => false;
}

class _InMemorySaveGameManager extends Fake implements LocalSaveGameManager {
  final Map<String, model.SaveGame> _saves = <String, model.SaveGame>{};
  final Map<String, SaveMetadata> _metas = <String, SaveMetadata>{};
  String? _activeSaveId;

  @override
  String? get activeSaveId => _activeSaveId;

  @override
  set activeSaveId(String? id) {
    _activeSaveId = id;
  }

  @override
  Future<List<SaveMetadata>> listSaves() async {
    final list = _metas.values.toList();
    list.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return list;
  }

  @override
  Future<model.SaveGame?> loadSave(String saveId) async {
    return _saves[saveId];
  }

  @override
  Future<bool> saveGame(model.SaveGame save) async {
    _saves[save.id] = save;
    final now = DateTime.now();
    final existing = _metas[save.id];
    _metas[save.id] = SaveMetadata(
      id: save.id,
      name: save.name,
      creationDate: existing?.creationDate ?? now,
      lastModified: now,
      version: save.version,
      gameMode: save.gameMode,
      isRestored: false,
    );
    _activeSaveId ??= save.id;
    return true;
  }

  @override
  Future<bool> deleteSave(String saveId) async {
    _saves.remove(saveId);
    _metas.remove(saveId);
    if (_activeSaveId == saveId) {
      _activeSaveId = null;
    }
    return true;
  }

  @override
  Future<bool> updateSaveMetadata(String saveId, SaveMetadata metadata) async {
    _metas[saveId] = metadata;
    return true;
  }

  @override
  Future<SaveMetadata?> getSaveMetadata(String saveId) async {
    return _metas[saveId];
  }

  @override
  String compressData(String data) => data;

  @override
  String decompressData(String compressed) => compressed;
}

model.SaveGame _makeSave(
  String name,
  Map<String, dynamic> gameData, {
  String id = 'fixed-id',
  DateTime? lastSaveTime,
}) {
  return model.SaveGame(
    id: id,
    name: name,
    gameData: gameData,
    gameMode: GameMode.INFINITE,
    lastSaveTime: lastSaveTime ?? DateTime(2025, 1, 1),
    version: '1.0.3',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GameSnapshot> _snapshotWithMoney(double money) async {
    final state = GameState();
    state.initialize();
    await state.startNewGame('test-snapshot-money');
    state.playerManager.updateMoney(money);
    final snapshot = state.toSnapshot();
    state.dispose();
    return snapshot;
  }

  group('GamePersistenceOrchestrator', () {
    late _InMemorySaveGameManager saveManager;

    setUp(() {
      saveManager = _InMemorySaveGameManager();
      SaveManagerAdapter.setSaveManagerForTesting(saveManager);
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    tearDown(() {
      SaveManagerAdapter.resetForTesting();
      GamePersistenceOrchestrator.instance.resetForTesting();
    });

    test('saveGame throw SaveError si GameState non initialisé', () async {
      final state = _UninitializedGameState();

      await expectLater(
        GamePersistenceOrchestrator.instance.saveGame(state, 'test-save'),
        throwsA(isA<SaveError>()),
      );

      state.dispose();
    });

    test('saveGame puis loadGame fonctionne (roundtrip minimal)', () async {
      final original = GameState();
      original.initialize();

      // État non-trivial
      original.playerManager.updateMoney(123.0);
      original.playerManager.updateMetal(10.0);
      original.playerManager.updatePaperclips(50);

      const name = 'orchestrator-roundtrip';

      await GamePersistenceOrchestrator.instance.saveGame(original, name);

      final restored = GameState();
      restored.initialize();

      await GamePersistenceOrchestrator.instance.loadGame(restored, name);

      expect(restored.playerManager.money, closeTo(123.0, 0.001));
      expect(restored.playerManager.metal, closeTo(10.0, 0.001));
      expect(restored.playerManager.paperclips, closeTo(50.0, 0.001));

      original.dispose();
      restored.dispose();
    });

    test('requestLifecycleSave enfile un save lifecycle + un backup (1er appel)', () async {
      final state = GameState();
      state.initialize();
      const gameName = 'lifecycle-orchestrator-first';
      await state.startNewGame(gameName);

      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        state,
        reason: 'test_lifecycle',
      );

      final saves = await SaveManagerAdapter.listSaves();
      final backups = saves
          .where((s) => s.isBackup && s.name.startsWith('$gameName${GameConstants.BACKUP_DELIMITER}'))
          .toList();
      final regular = saves.where((s) => !s.isBackup && s.name == gameName).toList();

      expect(regular.map((s) => s.name), contains(gameName));
      expect(backups.length, 1);
      expect(backups.first.name, startsWith(gameName));

      state.dispose();
    });

    test('requestLifecycleSave respecte le cooldown backup (pas de 2e backup immédiat)', () async {
      final state = GameState();
      state.initialize();
      const gameName = 'lifecycle-orchestrator-cooldown';
      await state.startNewGame(gameName);

      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        state,
        reason: 'test_lifecycle_1',
      );
      await GamePersistenceOrchestrator.instance.requestLifecycleSave(
        state,
        reason: 'test_lifecycle_2',
      );

      final saves = await SaveManagerAdapter.listSaves();
      final backups = saves
          .where((s) => s.isBackup && s.name.startsWith('$gameName${GameConstants.BACKUP_DELIMITER}'))
          .toList();

      expect(backups.length, 1);

      state.dispose();
    });

    test('checkAndRestoreLastSaveFromBackupIfNeeded: save invalide => restore depuis le backup le plus récent',
        () async {
      const baseName = 'restore-me';
      final backupOld = '$baseName${GameConstants.BACKUP_DELIMITER}111';
      final backupNew = '$baseName${GameConstants.BACKUP_DELIMITER}222';

      // 1) Insérer une sauvegarde principale invalide: snapshot manquant.
      await saveManager.saveGame(_makeSave(baseName, <String, dynamic>{}, id: 'base-invalid'));
      await saveManager.updateSaveMetadata(
        'base-invalid',
        SaveMetadata(
          id: 'base-invalid',
          name: baseName,
          creationDate: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 10),
          version: '1.0.3',
          gameMode: GameMode.INFINITE,
          isRestored: false,
        ),
      );

      // 2) Insérer deux backups valides (snapshot-only), dont un plus récent.
      await saveManager.saveGame(
        _makeSave(
          backupOld,
          <String, dynamic>{
            LocalGamePersistenceService.snapshotKey: (await _snapshotWithMoney(10.0)).toJson(),
          },
          id: 'backup-old',
        ),
      );
      await saveManager.updateSaveMetadata(
        'backup-old',
        SaveMetadata(
          id: 'backup-old',
          name: backupOld,
          creationDate: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 2),
          version: '1.0.3',
          gameMode: GameMode.INFINITE,
          isRestored: false,
        ),
      );

      await saveManager.saveGame(
        _makeSave(
          backupNew,
          <String, dynamic>{
            LocalGamePersistenceService.snapshotKey: (await _snapshotWithMoney(42.0)).toJson(),
          },
          id: 'backup-new',
        ),
      );
      await saveManager.updateSaveMetadata(
        'backup-new',
        SaveMetadata(
          id: 'backup-new',
          name: backupNew,
          creationDate: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 3),
          version: '1.0.3',
          gameMode: GameMode.INFINITE,
          isRestored: false,
        ),
      );

      await GamePersistenceOrchestrator.instance.checkAndRestoreLastSaveFromBackupIfNeeded();

      // La restauration ré-écrit une sauvegarde "baseName" avec les données du backup le plus récent.
      final restored = await SaveManagerAdapter.loadGame(baseName);
      final restoredRaw = restored.gameData[LocalGamePersistenceService.snapshotKey];
      expect(restoredRaw, isNotNull);
      final restoredSnapshot = switch (restoredRaw) {
        final Map<String, dynamic> map => GameSnapshot.fromJson(map),
        final Map map => GameSnapshot.fromJson(Map<String, dynamic>.from(map)),
        _ => throw StateError(
            'Snapshot restauré: format inattendu (${restoredRaw.runtimeType})',
          ),
      };
      expect(restoredSnapshot.core['playerManager']['money'], 42.0);
    });

    test('checkAndRestoreLastSaveFromBackupIfNeeded: save invalide mais aucun backup => no-op', () async {
      const baseName = 'restore-me-no-backup';

      // Snapshot manquant -> invalide.
      await saveManager.saveGame(_makeSave(baseName, <String, dynamic>{}, id: 'base-invalid'));
      await saveManager.updateSaveMetadata(
        'base-invalid',
        SaveMetadata(
          id: 'base-invalid',
          name: baseName,
          creationDate: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 10),
          version: '1.0.3',
          gameMode: GameMode.INFINITE,
          isRestored: false,
        ),
      );

      await GamePersistenceOrchestrator.instance.checkAndRestoreLastSaveFromBackupIfNeeded();

      // Il n'y a pas de backup, donc aucun nouveau save "restauré" n'est créé.
      // On vérifie juste que la sauvegarde reste "invalid" (loadGame retombe en fallback vide en cas d'erreur).
      final loaded = await SaveManagerAdapter.loadGame(baseName);
      expect(loaded.name, baseName);
    });

    test('loadGame: snapshot invalide et backup dispo => restaure puis charge; sinon throw',
        () async {
      final state = GameState();
      state.initialize();

      const baseName = 'load-restore';
      final backupName = '$baseName${GameConstants.BACKUP_DELIMITER}999';

      // Sauvegarde principale invalide: snapshot illisible.
      await saveManager.saveGame(
        _makeSave(
          baseName,
          <String, dynamic>{
            LocalGamePersistenceService.snapshotKey: 123,
          },
          id: 'base-invalid',
        ),
      );

      // Backup valide.
      await saveManager.saveGame(
        _makeSave(
          backupName,
          <String, dynamic>{
            LocalGamePersistenceService.snapshotKey: (await _snapshotWithMoney(77.0)).toJson(),
          },
          id: 'backup-valid',
        ),
      );
      await saveManager.updateSaveMetadata(
        'backup-valid',
        SaveMetadata(
          id: 'backup-valid',
          name: backupName,
          creationDate: DateTime(2025, 1, 1),
          lastModified: DateTime(2025, 1, 3),
          version: '1.0.3',
          gameMode: GameMode.INFINITE,
          isRestored: false,
        ),
      );

      await GamePersistenceOrchestrator.instance.loadGame(state, baseName);
      expect(state.playerManager.money, closeTo(77.0, 0.001));

      // Cas sans backup -> throw.
      const baseNameNoBackup = 'load-restore-no-backup';
      await saveManager.saveGame(
        _makeSave(
          baseNameNoBackup,
          <String, dynamic>{
            LocalGamePersistenceService.snapshotKey: 123,
          },
          id: 'base-invalid-2',
        ),
      );

      await expectLater(
        GamePersistenceOrchestrator.instance.loadGame(state, baseNameNoBackup),
        throwsA(isA<FormatException>()),
      );

      state.dispose();
    });
  });
}
