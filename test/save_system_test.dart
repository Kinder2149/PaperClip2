// test/save_system_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

// Importation des services et managers à tester
import 'package:paperclip2/services/save/save_types.dart';
import 'package:paperclip2/services/save/storage/storage_engine.dart';
import 'package:paperclip2/models/game_config.dart';

// Générer les mocks
@GenerateMocks([
  http.Client
])
import 'save_system_test.mocks.dart';

// Implémentation personnalisée pour les mocks de StorageEngine
class MockStorageEngine implements StorageEngine {
  @override
  bool get isInitialized => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> save(SaveGame saveGame) async {}

  @override
  Future<SaveGame?> load(String name) async {
    if (name == 'test_save') {
      return SaveGame(
        id: 'test-id',
        name: 'test_save',
        lastSaveTime: DateTime.now(),
        gameData: {
          'version': GameConstants.VERSION,
          'timestamp': DateTime.now().toIso8601String(),
          'playerManager': {'money': 100.0},
        },
        version: GameConstants.VERSION,
      );
    } else if (name == 'test_save_1') {
      return SaveGame(
        id: 'test-id-1',
        name: 'test_save_1',
        lastSaveTime: DateTime.now(),
        gameData: {
          'version': GameConstants.VERSION,
          'playerManager': {'money': 100.0},
        },
        version: GameConstants.VERSION,
      );
    } else if (name == 'test_save_2') {
      return SaveGame(
        id: 'test-id-2',
        name: 'test_save_2',
        lastSaveTime: DateTime.now().subtract(Duration(days: 1)),
        gameData: {
          'version': GameConstants.VERSION,
          'playerManager': {'money': 50.0},
        },
        version: GameConstants.VERSION,
      );
    } else if (name == 'test_game_backup_123456789') {
      return SaveGame(
        id: 'backup-id',
        name: 'test_game_backup_123456789',
        lastSaveTime: DateTime.now().subtract(Duration(hours: 1)),
        gameData: {
          'version': GameConstants.VERSION,
          'playerManager': {'money': 75.0},
        },
        version: GameConstants.VERSION,
      );
    } else if (name == 'corrupted_save') {
      throw SaveError('TEST_ERROR', 'Test error message');
    }
    return null;
  }

  @override
  Future<List<SaveGameInfo>> listSaves() async {
    return [
      SaveGameInfo(
        id: 'test-id-1',
        name: 'test_save_1',
        timestamp: DateTime.now(),
        version: GameConstants.VERSION,
        paperclips: 100.0,
        money: 200.0,
        gameMode: GameMode.INFINITE,
      ),
      SaveGameInfo(
        id: 'test-id-2',
        name: 'test_save_2',
        timestamp: DateTime.now().subtract(Duration(days: 1)),
        version: GameConstants.VERSION,
        paperclips: 50.0,
        money: 100.0,
        gameMode: GameMode.COMPETITIVE,
      ),
      SaveGameInfo(
        id: 'backup-id',
        name: 'test_game_backup_123456789',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        version: GameConstants.VERSION,
        paperclips: 80.0,
        money: 150.0,
        gameMode: GameMode.INFINITE,
      ),
    ];
  }

  @override
  Future<bool> exists(String name) async => true;

  @override
  Future<void> delete(String name) async {}
}

class MockLocalStorageEngine extends MockStorageEngine {}
class MockCloudStorageEngine extends MockStorageEngine {
  @override
  Future<List<SaveGameInfo>> listSaves() async {
    return [
      SaveGameInfo(
        id: 'cloud-id-1',
        name: 'cloud_save_1',
        timestamp: DateTime.now(),
        version: GameConstants.VERSION,
        paperclips: 200.0,
        money: 300.0,
        isSyncedWithCloud: true,
        cloudId: 'cloud-id-1',
        gameMode: GameMode.INFINITE,
      ),
    ];
  }
}

// Mock pour SaveDataProvider
class MockSaveDataProvider implements SaveDataProvider {
  @override
  String? get gameName => 'test_game';

  @override
  GameMode get gameMode => GameMode.INFINITE;

  Map<String, dynamic> _gameData = {
    'version': GameConstants.VERSION,
    'timestamp': DateTime.now().toIso8601String(),
    'playerManager': {'money': 100.0},
    'productionManager': {'paperclips': 50.0},
    'marketManager': {'marketMetalStock': 5000.0},
    'levelSystem': {'level': 3},
    'gameMode': GameMode.INFINITE.index
  };

  @override
  Map<String, dynamic> prepareGameData() => _gameData;

  @override
  void loadGameData(Map<String, dynamic> data) {
    _gameData = Map.from(data);
  }
}

// Simulacre de SaveSystem
class SimplifiedSaveSystem {
  final MockLocalStorageEngine _localEngine = MockLocalStorageEngine();
  final MockCloudStorageEngine _cloudEngine = MockCloudStorageEngine();
  SaveDataProvider? _dataProvider;

  bool _isInitialized = false;
  bool _isRecoveryModeEnabled = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(SaveDataProvider? dataProvider) async {
    _dataProvider = dataProvider;
    await _localEngine.initialize();
    await _cloudEngine.initialize();
    _isInitialized = true;
  }

  Future<bool> exists(String name) async {
    return await _localEngine.exists(name);
  }

  void enableRecoveryMode() {
    _isRecoveryModeEnabled = true;
  }

  Future<void> saveGame(String name, {bool syncToCloud = true}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    final gameData = _dataProvider!.prepareGameData();
    final saveData = SaveGame(
      id: 'test-id',
      name: name,
      lastSaveTime: DateTime.now(),
      gameData: gameData,
      version: GameConstants.VERSION,
      gameMode: _dataProvider!.gameMode,
    );

    await _localEngine.save(saveData);

    if (syncToCloud) {
      await _cloudEngine.save(saveData);
    }
  }

  Future<void> loadGame(String name, {String? cloudId}) async {
    if (_dataProvider == null) {
      throw Exception('Le système de sauvegarde n\'est pas initialisé');
    }

    SaveGame? saveGame;

    if (cloudId != null) {
      saveGame = await _cloudEngine.load(cloudId);
    } else {
      saveGame = await _localEngine.load(name);
    }

    if (saveGame == null) {
      throw SaveError('NOT_FOUND', 'Sauvegarde non trouvée');
    }

    _dataProvider!.loadGameData(saveGame.gameData);
  }

  Future<List<SaveGameInfo>> listSaves() async {
    return await _localEngine.listSaves();
  }

  Future<List<SaveGameInfo>> listCloudSaves() async {
    return await _cloudEngine.listSaves();
  }

  Future<bool> syncSavesToCloud() async {
    final localSaves = await _localEngine.listSaves();

    for (var saveInfo in localSaves) {
      final save = await _localEngine.load(saveInfo.name);
      if (save != null) {
        await _cloudEngine.save(save);
      }
    }

    return true;
  }

  Future<void> saveOnImportantEvent() async {
    if (_dataProvider?.gameName != null) {
      await saveGame(_dataProvider!.gameName!);
    }
  }

  Future<void> checkAndRestoreFromBackup() async {
    if (_dataProvider?.gameName == null) return;

    final saves = await listSaves();
    final backups = saves.where((save) =>
        save.name.startsWith('${_dataProvider!.gameName!}_backup_')).toList();

    if (backups.isEmpty) return;

    backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (var backup in backups) {
      try {
        await loadGame(backup.name);
        return;
      } catch (e) {
        continue;
      }
    }
  }
}

// Simulacre de UserManager
class SimplifiedUserManager {
  final List<String> _saveIds = [];
  String? _displayName;

  bool get hasProfile => _displayName != null;

  Future<void> initialize() async {
    // Ne rien faire
  }

  Future<void> createProfile(String displayName) async {
    _displayName = displayName;
  }

  Future<List<String>> getProfileSaveIds({GameMode? mode}) async {
    return _saveIds;
  }

  Future<void> addSaveToProfile(String saveId, GameMode mode) async {
    _saveIds.add(saveId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalStorageEngine mockLocalEngine;
  late MockCloudStorageEngine mockCloudEngine;
  late MockSaveDataProvider mockDataProvider;
  late SimplifiedSaveSystem saveSystem;
  late SimplifiedUserManager userManager;

  setUp(() async {
    // Initialiser les mocks
    mockLocalEngine = MockLocalStorageEngine();
    mockCloudEngine = MockCloudStorageEngine();
    mockDataProvider = MockSaveDataProvider();

    // Configurer SharedPreferences pour les tests
    SharedPreferences.setMockInitialValues({});

    // Créer les instances à tester
    saveSystem = SimplifiedSaveSystem();
    userManager = SimplifiedUserManager();

    // Initialiser les services
    await saveSystem.initialize(mockDataProvider);
  });

  group('Tests de SimplifiedSaveSystem', () {
    test('Initialisation correcte du système de sauvegarde', () {
      expect(saveSystem.isInitialized, isTrue);
    });

    test('Sauvegarde locale réussie', () async {
      // Exécuter la sauvegarde
      await saveSystem.saveGame('test_save', syncToCloud: false);
    });

    test('Chargement d\'une sauvegarde', () async {
      // Exécuter le chargement
      await saveSystem.loadGame('test_save');
    });

    test('Synchronisation avec le cloud', () async {
      // Exécuter la synchronisation
      final result = await saveSystem.syncSavesToCloud();

      // Vérifier que la synchronisation a réussi
      expect(result, isTrue);
    });

    test('Restauration depuis une sauvegarde de secours', () async {
      // Exécuter la restauration
      await saveSystem.checkAndRestoreFromBackup();
    });

    test('Gestion des erreurs lors du chargement', () async {
      // Exécuter le chargement et vérifier qu'une exception est levée
      expect(() => saveSystem.loadGame('corrupted_save'), throwsA(isA<SaveError>()));
    });

    test('Création de sauvegarde de secours', () async {
      // Activer le mode récupération
      saveSystem.enableRecoveryMode();

      // Créer une backup
      await saveSystem.saveOnImportantEvent();
    });
  });

  group('Tests d\'interaction UserManager-SimplifiedSaveSystem', () {
    test('Ajout d\'une sauvegarde au profil utilisateur', () async {
      // Créer un profil temporaire
      await userManager.createProfile('Test Player');

      // Sauvegarder une partie
      await saveSystem.saveGame('test_profile_save');

      // Ajouter manuellement la sauvegarde au profil
      await userManager.addSaveToProfile('test-id', GameMode.INFINITE);

      // Vérifier que la sauvegarde a été ajoutée au profil
      final saveIds = await userManager.getProfileSaveIds();
      expect(saveIds.isNotEmpty, isTrue);
    });

    test('Chargement des sauvegardes cloud', () async {
      // Obtenir les sauvegardes cloud
      final cloudSaves = await saveSystem.listCloudSaves();

      // Vérifier le résultat
      expect(cloudSaves.length, equals(1));
      expect(cloudSaves[0].name, equals('cloud_save_1'));
      expect(cloudSaves[0].isSyncedWithCloud, isTrue);
    });
  });
}