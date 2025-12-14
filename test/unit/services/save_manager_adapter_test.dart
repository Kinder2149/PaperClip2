// ignore_for_file: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:paperclip2/constants/game_config.dart';
// Import SaveGame uniquement depuis services/save_game.dart pour éviter le conflit
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/services/save_game.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';

class TestLocalSaveGameManager extends Fake implements LocalSaveGameManager {
  Future<void> Function()? onReloadMetadataCache;
  Future<List<SaveMetadata>> Function()? onListSaves;
  Future<SaveGame?> Function(String saveId)? onLoadSave;

  String? _activeSaveId;

  @override
  Future<void> reloadMetadataCache() async {
    if (onReloadMetadataCache != null) {
      await onReloadMetadataCache!();
    }
  }

  @override
  Future<List<SaveMetadata>> listSaves() async {
    if (onListSaves != null) {
      return onListSaves!();
    }
    return <SaveMetadata>[];
  }

  @override
  Future<SaveGame?> loadSave(String saveId) async {
    if (onLoadSave != null) {
      return onLoadSave!(saveId);
    }
    return null;
  }

  @override
  String? get activeSaveId => _activeSaveId;

  @override
  set activeSaveId(String? id) {
    _activeSaveId = id;
  }

  @override
  Future<bool> saveGame(SaveGame save) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteSave(String saveId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exportSave(String saveId, String path) {
    throw UnimplementedError();
  }

  @override
  Future<SaveGame?> importSave(dynamic sourceData, {String? newName, bool overwriteIfExists = false}) {
    throw UnimplementedError();
  }

  @override
  String compressData(String data) => data;

  @override
  String decompressData(String compressed) => compressed;

  @override
  Future<SaveMetadata?> getSaveMetadata(String saveId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> updateSaveMetadata(String saveId, SaveMetadata metadata) {
    throw UnimplementedError();
  }

  @override
  Future<bool> saveExists(String name) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> cleanupOrphanedSaves() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> forceCleanupOrphanedSaves() {
    throw UnimplementedError();
  }

  @override
  Future<SaveGame> createNewSave({
    String? name,
    GameMode gameMode = GameMode.INFINITE,
    Map<String, dynamic>? initialData,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> enableAutoSave({
    required Duration interval,
    required String saveId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> disableAutoSave() {
    throw UnimplementedError();
  }

  @override
  Future<SaveGame?> duplicateSave(String sourceId, {String? newName}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> quickValidate(String saveId) {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    // no-op
  }
}

void main() {
  group('SaveManagerAdapter Tests', () {
    late TestLocalSaveGameManager testManager;
    
    setUp(() {
      testManager = TestLocalSaveGameManager();
      // Remplacer l'instance de LocalSaveGameManager dans SaveManagerAdapter
      SaveManagerAdapter.setSaveManagerForTesting(testManager);
    });
    
    tearDown(() {
      // Nettoyage après les tests
      // Note: Dans une application réelle, il faudrait réinitialiser l'instance
      // mais ici pour les tests, ce n'est pas critique
      SaveManagerAdapter.resetForTesting();
    });
    
    test('listSaves convertit correctement SaveMetadata en SaveGameInfo', () async {
      // Créer des métadonnées de test
      final date1 = DateTime(2023, 1, 15);
      final metadata1 = SaveMetadata(
        id: 'save1',
        name: 'Save 1',
        creationDate: date1,  // Ajout du champ requis
        lastModified: date1,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      final date2 = DateTime(2023, 2, 20);
      final metadata2 = SaveMetadata(
        id: 'save2',
        name: 'Save 2',
        creationDate: date2,  // Ajout du champ requis
        lastModified: date2,
        version: '1.0.0',
        gameMode: GameMode.COMPETITIVE,
        isRestored: true,
      );
      
      // Configurer le stub pour retourner nos métadonnées de test
      testManager.onListSaves = () async => [metadata1, metadata2];
      
      // Configurer le mock pour la première sauvegarde
      final saveGame1 = SaveGame(
        id: metadata1.id,
        name: metadata1.name,
        gameMode: metadata1.gameMode,
        lastSaveTime: metadata1.lastModified,
        version: metadata1.version,
        gameData: {
          'playerManager': {
            'paperclips': 1000,
            'money': 500,
            'totalPaperclipsSold': 2000,
            'autoClipperCount': 5,
          }
        },
      );
      testManager.onLoadSave = (saveId) async {
        if (saveId == 'save1') return saveGame1;
        return null;
      };
      
      // Configurer le mock pour la deuxième sauvegarde
      final saveGame2 = SaveGame(
        id: metadata2.id,
        name: metadata2.name,
        gameMode: metadata2.gameMode,
        lastSaveTime: metadata2.lastModified,
        version: metadata2.version,
        gameData: {
          'playerManager': {
            'paperclips': 2000,
            'money': 1000,
            'totalPaperclipsSold': 5000,
            'autoClipperCount': 10,
          }
        },
      );
      final previousOnLoadSave = testManager.onLoadSave;
      testManager.onLoadSave = (saveId) async {
        if (saveId == 'save2') return saveGame2;
        if (previousOnLoadSave != null) return previousOnLoadSave(saveId);
        return null;
      };
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier les résultats
      expect(saves.length, 2);
      
      // Vérifier la première sauvegarde
      expect(saves[0].id, 'save1');
      expect(saves[0].name, 'Save 1');
      expect(saves[0].lastModified, DateTime(2023, 1, 15));
      expect(saves[0].gameMode, GameMode.INFINITE);
      expect(saves[0].isRestored, false);
      expect(saves[0].isBackup, false);
      expect(saves[0].paperclips, 1000);
      expect(saves[0].money, 500);
      expect(saves[0].totalPaperclipsSold, 2000);
      expect(saves[0].autoClipperCount, 5);
      
      // Vérifier la deuxième sauvegarde
      expect(saves[1].id, 'save2');
      expect(saves[1].name, 'Save 2');
      expect(saves[1].lastModified, DateTime(2023, 2, 20));
      expect(saves[1].gameMode, GameMode.COMPETITIVE);
      expect(saves[1].isRestored, true);
      expect(saves[1].isBackup, false);
      expect(saves[1].paperclips, 2000);
      expect(saves[1].money, 1000);
      expect(saves[1].totalPaperclipsSold, 5000);
      expect(saves[1].autoClipperCount, 10);
    });
    
    test('listSaves gère correctement les erreurs de chargement', () async {
      // Créer une métadonnée de test
      final errorDate = DateTime(2023, 3, 10);
      final metadata = SaveMetadata(
        id: 'error-save',
        name: 'Save with Error',
        creationDate: errorDate,  // Ajout du champ requis
        lastModified: errorDate,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      // Configurer le stub pour retourner notre métadonnée
      testManager.onListSaves = () async => [metadata];
      
      // Simuler une erreur lors du chargement de la sauvegarde
      testManager.onLoadSave = (_) async {
        throw Exception('Test error');
      };
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier que la sauvegarde est retournée avec des valeurs par défaut
      expect(saves.length, 1);
      expect(saves[0].id, 'error-save');
      expect(saves[0].name, 'Save with Error');
      expect(saves[0].lastModified, DateTime(2023, 3, 10));
      expect(saves[0].paperclips, 0); // Valeur par défaut
      expect(saves[0].money, 0); // Valeur par défaut
    });
    
    test('listSaves gère les sauvegardes de type backup', () async {
      // Créer une métadonnée de sauvegarde backup
      final backupName = 'Regular Save${GameConstants.BACKUP_DELIMITER}20230401';
      final backupDate = DateTime(2023, 4, 1);
      final backupMetadata = SaveMetadata(
        id: 'backup1',
        name: backupName,
        creationDate: backupDate,  // Ajout du champ requis
        lastModified: backupDate,
        version: '1.0.0',
        gameMode: GameMode.INFINITE,
        isRestored: false,
      );
      
      // Configurer le stub
      testManager.onListSaves = () async => [backupMetadata];
      
      // Ne pas configurer loadSave car les backups ne chargent pas les données du jeu
      
      // Appeler la méthode à tester
      final saves = await SaveManagerAdapter.listSaves();
      
      // Vérifier les résultats
      expect(saves.length, 1);
      expect(saves[0].name, backupName);
      expect(saves[0].isBackup, true);
      expect(saves[0].paperclips, 0); // Les backups n'ont pas de données de jeu
      expect(saves[0].money, 0);
    });
  });
}
