// lib/services/save_system/save_manager_adapter.dart

import 'dart:async' show Future, FutureOr, Stream, StreamController, Timer, TimeoutException;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/constants/game_config.dart';

import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_game_manager.dart';
import 'package:paperclip2/services/save_system/local_save_game_manager.dart';
import 'package:paperclip2/services/save_game.dart' show SaveGameInfo;

/// Adaptateur qui permet d'utiliser le nouveau système de sauvegarde LocalSaveGameManager
/// avec l'interface du SaveManager existant.
///
/// Cette classe de transition facilite l'intégration du nouveau système de sauvegarde
/// tout en minimisant les changements nécessaires dans le code existant.
@Deprecated('Utiliser GamePersistenceOrchestrator et LocalGamePersistenceService (services/persistence)')
class SaveManagerAdapter {
  static final SaveManagerAdapter _instance = SaveManagerAdapter._internal();
  factory SaveManagerAdapter() => _instance;
  
  /// Instance du gestionnaire de sauvegarde local
  LocalSaveGameManager? _saveManager;
  
  /// Indique si l'initialisation est terminée
  bool _isInitialized = false;
  
  /// Accesseur pour obtenir l'instance du gestionnaire de sauvegarde
  static LocalSaveGameManager get instance {
    if (_instance._saveManager == null) {
      if (kDebugMode) {
        print('SaveManagerAdapter: Attention - saveManager est null! Initialisation incomplète.');
      }
      throw StateError('SaveManagerAdapter n\'est pas initialisé');
    }
    return _instance._saveManager!;
  }

  static void setSaveManagerForTesting(LocalSaveGameManager manager) {
    _instance._saveManager = manager;
    _instance._isInitialized = true;
  }

  static void resetForTesting() {
    _instance._saveManager = null;
    _instance._isInitialized = false;
  }
  
  /// Vérifie que le saveManager est initialisé avant de l'utiliser
  static Future<void> ensureInitialized() async {
    // Éviter les appels redondants si déjà initialisé
    if (_instance._isInitialized && _instance._saveManager != null) return;
    
    if (kDebugMode) {
      print('SaveManagerAdapter: Initialisation...');
    }
    
    try {
      // Utiliser un timeout pour éviter les blocages pendant l'initialisation
      _instance._saveManager = await LocalSaveGameManager.getInstance().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {
            print('SaveManagerAdapter: TIMEOUT LocalSaveGameManager.getInstance() après 10 secondes!');
          }
          // En cas de timeout, marquer comme initialisé quand même pour éviter les blocages
          _instance._isInitialized = true;
          throw TimeoutException('Initialisation du gestionnaire de sauvegarde a expiré après 10 secondes');
        }
      );
      
      // Même si on a une instance, vérifier qu'elle n'est pas null
      if (_instance._saveManager != null) {
        _instance._isInitialized = true;
        
        if (kDebugMode) {
          print('SaveManagerAdapter: Initialisation terminée avec succès');
        }
      } else {
        if (kDebugMode) {
          print('SaveManagerAdapter: ERREUR - Instance nulle après initialisation');
        }
        throw StateError('Échec d\'initialisation: instance nulle');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('SaveManagerAdapter: ERREUR pendant l\'initialisation: $e');
        print('SaveManagerAdapter: Stack trace: $stackTrace');
      }
      
      // En cas d'erreur, on marque quand même comme initialisé
      // mais avec un _saveManager null, ce qui forcera les opérations
      // à échouer proprement avec une exception explicite
      _instance._isInitialized = true;
      
      // Re-lancer l'exception pour que les appelants puissent la gérer
      rethrow;
    }
  }

  SaveManagerAdapter._internal() {
    // Lancer l'initialisation mais ne pas bloquer le constructeur
    // Utiliser Future.microtask pour s'assurer que l'initialisation s'exécute après le constructeur
    Future.microtask(() {
      ensureInitialized().catchError((e) {
        // Capturer et logger les erreurs pendant l'initialisation
        if (kDebugMode) {
          print('SaveManagerAdapter._internal: Erreur pendant l\'initialisation asynchrone: $e');
        }
        // Ne pas propager l'erreur pour éviter un crash de l'application
        // L'instance est déjà marquée comme initialisée dans ensureInitialized()
        // Les opérations échoueront proprement avec des exceptions explicites
      });
    });
  }

  /// Préfixes utilisés pour la rétrocompatibilité avec l'ancien système
  static const String SAVE_PREFIX = 'game_save_';
  static const String SAVE_FORMAT_VERSION = '2.0'; // Version actuelle du format de sauvegarde

  /// Obtient la clé de sauvegarde pour un nom de jeu donné (pour compatibilité)
  static String _getSaveKey(String gameName) {
    return '$SAVE_PREFIX$gameName';
  }

  /// Extrait les données de jeu d'un objet SaveGame ou d'une Map
  static Map<String, dynamic> extractGameData(dynamic saveGameOrData) {
    if (saveGameOrData == null) return {};
    
    // Si c'est déjà une Map, on la retourne directement
    if (saveGameOrData is Map<String, dynamic>) {
      return saveGameOrData;
    }
    // Si c'est un SaveGame, on extrait gameData
    else if (saveGameOrData is SaveGame) {
      return saveGameOrData.gameData;
    }
    
    // Par défaut, retourner une map vide
    return {};
  }

  /// Sauvegarde un jeu
  static Future<bool> saveGame(SaveGame saveGame, {bool compress = true}) async {
    try {
      await ensureInitialized();
      
      if (kDebugMode) {
        print('SaveManagerAdapter.saveGame: Sauvegarde de "${saveGame.name}" (ID: ${saveGame.id})');
      }
      // Invariant: si des métadonnées existent déjà pour cet ID, leur nom fait foi (éviter d'écraser un renommage par erreur)
      try {
        final existingMeta = await instance.getSaveMetadata(saveGame.id);
        if (existingMeta != null && existingMeta.name != saveGame.name) {
          if (kDebugMode) {
            print('SaveManagerAdapter.saveGame: Harmonisation du nom (meta="${existingMeta.name}" vs save="${saveGame.name}")');
          }
          saveGame = saveGame.copyWith(name: existingMeta.name);
        }
      } catch (_) {}

      // Adapter la structure pour la nouvelle implementation
      final metadata = SaveMetadata(
        id: saveGame.id,
        name: saveGame.name,
        creationDate: saveGame.lastSaveTime,
        lastModified: DateTime.now(),
        version: saveGame.version,
        gameMode: saveGame.gameMode,
        displayData: {}, // Sera extrait du gameData
      );
      
      // La méthode saveGame ne prend qu'un seul paramètre SaveGame
      // Le nouveau gestionnaire s'occupe lui-même de la compression
      final result = await instance.saveGame(saveGame);
      
      if (kDebugMode) {
        print('SaveManagerAdapter.saveGame: Sauvegarde ${result ? 'réussie' : 'échouée'} pour "${saveGame.name}"');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('SaveManagerAdapter.saveGame: ERREUR lors de la sauvegarde de "${saveGame.name}": $e');
      }
      return false;
    }
  }

  /// Crée une sauvegarde à partir de l'état du jeu actuel
  static Future<void> saveGameState(GameState gameState, String name) async {
    try {
      // Créer un objet SaveGame pour compatibilité
      Map<String, dynamic> gameData = {
        'playerManager': gameState.playerManager.toJson(),
        'levelSystem': gameState.levelSystem.toJson(),
        'gameMode': gameState.gameMode.index,
        'isInCrisisMode': gameState.isInCrisisMode,
        'crisisTransitionComplete': gameState.isCrisisTransitionComplete,
        'competitiveStartTime': gameState.competitiveStartTime?.toIso8601String(),
        'crisisStartTime': gameState.crisisStartTime?.toIso8601String(),
      };
      
      SaveGame saveGame = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: gameState.gameMode,
      );

      await SaveManagerAdapter.saveGame(saveGame);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la sauvegarde de l\'état du jeu: $e');
      }
      rethrow;
    }
  }

  /// Crée une sauvegarde de secours
  static Future<bool> createBackup(GameState gameState) async {
    try {
      final currentTime = DateTime.now();
      final baseKey = gameState.partieId ?? (gameState.gameName ?? 'default');
      final backupName = '$baseKey${GameConstants.BACKUP_DELIMITER}${currentTime.millisecondsSinceEpoch}';

      // Créer un objet SaveGame pour compatibilité
      Map<String, dynamic> gameData = {
        'playerManager': gameState.playerManager.toJson(),
        'levelSystem': gameState.levelSystem.toJson(),
        'gameMode': gameState.gameMode.index,
        'isInCrisisMode': gameState.isInCrisisMode,
        'crisisTransitionComplete': gameState.isCrisisTransitionComplete,
        'competitiveStartTime': gameState.competitiveStartTime?.toIso8601String(),
        'crisisStartTime': gameState.crisisStartTime?.toIso8601String(),
      };
      
      SaveGame saveGame = SaveGame(
        name: backupName,
        lastSaveTime: currentTime,
        gameData: gameData,
        version: GameConstants.VERSION,
        gameMode: gameState.gameMode,
      );

      final success = await SaveManagerAdapter.saveGame(saveGame);
      
      if (success) {
        // Nettoyer les anciennes sauvegardes si nécessaire
        // Limite le nombre de backups à MAX_BACKUPS dans GameConstants
        await _cleanupOldBackups(baseKey, GameConstants.MAX_BACKUPS);
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création de la sauvegarde de secours: $e');
      }
      return false;
    }
  }

  /// Vérifie si une sauvegarde existe
  static Future<bool> saveExists(String name) async {
    try {
      final saves = await instance.listSaves();
      return saves.any((save) => save.name == name);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de l\'existence de la sauvegarde: $e');
      }
      return false;
    }
  }

  /// Récupère la dernière sauvegarde
  static Future<SaveGame?> getLastSave() async {
    try {
      // S'assurer que le SaveManagerAdapter est initialisé
      await ensureInitialized();
      
      if (kDebugMode) {
        print('SaveManagerAdapter.getLastSave: Récupération de la dernière sauvegarde...');
      }
      
      final saves = await instance.listSaves();
      if (saves.isEmpty) {
        if (kDebugMode) {
          print('SaveManagerAdapter.getLastSave: Aucune sauvegarde trouvée');
        }
        return null;
      }

      if (kDebugMode) {
        print('SaveManagerAdapter.getLastSave: ${saves.length} sauvegardes trouvées avant filtrage');
      }

      // Trier par date de dernière modification (plus récent en premier)
      saves.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
      // Exclure les backups
      final regularSaves = saves.where(
        (save) => !save.name.contains(GameConstants.BACKUP_DELIMITER)
      ).toList();
      
      if (regularSaves.isEmpty) {
        if (kDebugMode) {
          print('SaveManagerAdapter.getLastSave: Aucune sauvegarde régulière trouvée après filtrage');
        }
        return null;
      }

      if (kDebugMode) {
        print('SaveManagerAdapter.getLastSave: ${regularSaves.length} sauvegardes régulières trouvées');
        print('SaveManagerAdapter.getLastSave: Dernière sauvegarde: "${regularSaves.first.name}" (ID: ${regularSaves.first.id})');
      }

      // Charger la sauvegarde la plus récente en utilisant son ID
      final lastSaveMetadata = regularSaves.first;
      final saveGame = await instance.loadSave(lastSaveMetadata.id);

      // Si la sauvegarde n'existe pas, retourner null
      if (saveGame == null) {
        if (kDebugMode) {
          print('SaveManagerAdapter.getLastSave: Échec du chargement de la sauvegarde ${lastSaveMetadata.id}');
        }
        return null;
      }

      if (kDebugMode) {
        print('SaveManagerAdapter.getLastSave: Sauvegarde chargée avec succès');
      }

      // Créer un nouvel objet SaveGame pour compatibilité
      return SaveGame(
        id: lastSaveMetadata.id,
        name: lastSaveMetadata.name,
        lastSaveTime: lastSaveMetadata.lastModified,
        gameData: saveGame.gameData,
        version: lastSaveMetadata.version,
        gameMode: lastSaveMetadata.gameMode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SaveManagerAdapter.getLastSave: ERREUR: $e');
      }
      return null;
    }
  }

  /// Charge une sauvegarde
  /// Charge une sauvegarde à partir de son nom
  static Future<SaveGame> loadGame(String name) async {
    if (kDebugMode) {
      print('SaveManagerAdapter.loadGame: Tentative de chargement de la sauvegarde "$name"');
    }
    try {
      // Récupérer toutes les métadonnées pour trouver l'ID correspondant au nom
      final allMetadatas = await instance.listSaves();
      final matchingMetadata = allMetadatas.where((m) => m.name == name).toList();
      
      if (matchingMetadata.isEmpty) {
        if (kDebugMode) {
          print('SaveManagerAdapter.loadGame: Aucune sauvegarde trouvée avec le nom "$name"');
        }
        throw SaveError('load_error', 'Sauvegarde introuvable');
      }

      // Si plusieurs entrées ont le même nom, prendre la plus récente.
      matchingMetadata.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
      // Utiliser l'ID pour charger les données
      final saveId = matchingMetadata.first.id;
      if (kDebugMode) {
        print('SaveManagerAdapter.loadGame: Sauvegarde trouvée avec ID "$saveId"');
      }
      
      // Charger les données de sauvegarde et les métadonnées avec l'ID
      final gameData = await instance.loadSave(saveId);
      final metadata = matchingMetadata.first;

      if (metadata == null) {
        throw SaveError('load_error', 'Métadonnées de sauvegarde non trouvées');
      }

      // Créer un objet SaveGame pour compatibilité
      // Initialiser avec un objet vide par défaut pour éviter les problèmes de null
      final Map<String, dynamic> extractedGameData = {};
      
      // Si gameData est non-null, traiter selon son type
      if (gameData != null) {
        // Si gameData est déjà un SaveGame, extraire ses données
        if (gameData is SaveGame) {
          // Copier les données une par une pour éviter les problèmes de type
          final gameDataMap = gameData.gameData;
          if (gameDataMap != null) {
            for (var entry in gameDataMap.entries) {
              extractedGameData[entry.key] = entry.value;
            }
          }
        } 
        // Sinon si c'est déjà une Map, l'utiliser
        else if (gameData is Map<String, dynamic>) {
          // Cast explicite et copie de chaque entrée
          final Map<String, dynamic> mapData = gameData as Map<String, dynamic>;
          for (var entry in mapData.entries) {
            extractedGameData[entry.key] = entry.value;
          }
        }
        // Pour tout autre type, on affiche un message de debug
        else {
          if (kDebugMode) {
            print('Type de gameData non reconnu: ${gameData.runtimeType}');
          }
        }
      }
      
      return SaveGame(
        id: metadata.id,
        name: metadata.name,
        lastSaveTime: metadata.lastModified,
        gameData: extractedGameData,
        version: metadata.version,
        gameMode: metadata.gameMode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement de la sauvegarde: $e');
      }
      
      // En cas d'erreur, créer une nouvelle sauvegarde vide
      // (comportement compatible avec l'ancien système)
      return SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: {},
        version: GameConstants.VERSION,
        gameMode: GameMode.INFINITE,
      );
    }
  }

  /// Charge une sauvegarde à partir de son identifiant unique
  static Future<SaveGame?> loadGameById(String id) async {
    try {
      await ensureInitialized();
      final game = await instance.loadSave(id);
      if (game == null) return null;

      final meta = await instance.getSaveMetadata(id);
      if (meta == null) {
        return SaveGame(
          id: id,
          name: game.name,
          lastSaveTime: DateTime.now(),
          gameData: game.gameData,
          version: GameConstants.VERSION,
          gameMode: game.gameMode,
        );
      }

      return SaveGame(
        id: id,
        name: meta.name,
        lastSaveTime: meta.lastModified,
        gameData: game.gameData,
        version: meta.version,
        gameMode: meta.gameMode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SaveManagerAdapter.loadGameById: ERREUR: $e');
      }
      return null;
    }
  }
  /// Restaure une sauvegarde à partir d'un backup
  static Future<bool> restoreFromBackup(String backupName, GameState gameState) async {
    try {
      await ensureInitialized();

      // Résoudre backupName -> backupId
      final allMetadatas = await instance.listSaves();
      final matchingBackup = allMetadatas.where((m) => m.name == backupName).toList();
      if (matchingBackup.isEmpty) {
        return false;
      }

      matchingBackup.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final backupMeta = matchingBackup.first;
      final backupId = backupMeta.id;

      // Extraire le nom de la sauvegarde originale
      final originalName = backupName.split(GameConstants.BACKUP_DELIMITER).first;
      
      // Extraire les données du jeu de la sauvegarde de backup
      final backupSave = await instance.loadSave(backupId);
      if (backupSave == null) return false;
      
      // Utilisez une assertion non-null pour gameData, car backupSave n'est pas null
      final Map<String, dynamic> extractedGameData = backupSave.gameData;

      // Tenter de restaurer dans l'ID de la sauvegarde originale si elle existe.
      String? originalId;
      final matchingOriginal = allMetadatas.where((m) => m.name == originalName).toList();
      if (matchingOriginal.isNotEmpty) {
        matchingOriginal.sort((a, b) => b.lastModified.compareTo(a.lastModified));
        originalId = matchingOriginal.first.id;
      }
      
      // Créer une nouvelle sauvegarde avec les données du backup
      SaveGame newSave = SaveGame(
        id: originalId,
        name: originalName,
        lastSaveTime: DateTime.now(),
        gameData: extractedGameData,
        version: backupMeta.version,
        gameMode: backupMeta.gameMode,
        isRestored: true,
      );
      
      // Sauvegarder
      return await saveGame(newSave);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la restauration depuis le backup: $e');
      }
      return false;
    }
  }

  /// Liste toutes les sauvegardes disponibles
  static Future<List<SaveGameInfo>> listSaves() async {
    if (kDebugMode) {
      print('SaveManagerAdapter.listSaves: Récupération des sauvegardes');
    }
    try {
      // Forcer un rechargement du cache des métadonnées depuis SharedPreferences
      try {
        // Pour être sûr que les métadonnées sont à jour, forçons LocalSaveGameManager à recharger son cache
        await instance.reloadMetadataCache();
        if (kDebugMode) {
          print('DIAGNOSTIC ADAPTER: Cache des métadonnées rechargé avec succès');
        }
      } catch (e) {
        // Si cette méthode échoue, continuons avec le cache existant
        if (kDebugMode) {
          print('DIAGNOSTIC ADAPTER: Impossible de forcer le rechargement du cache: $e');
          print('Continuons avec le cache existant');
        }
      }
      
      final metadataList = await instance.listSaves();
      
      if (kDebugMode) {
        print('DIAGNOSTIC ADAPTER: ${metadataList.length} sauvegardes trouvées dans le cache');
        for (var meta in metadataList) {
          print('  - Sauvegarde: ${meta.id}, nom: "${meta.name}", date: ${meta.lastModified}');
        }
      }
      
      // Liste pour stocker les résultats de la conversion
      final List<SaveGameInfo> results = [];
      
      // Convertir les métadonnées en SaveGameInfo un par un pour mieux gérer les erreurs
      for (var metadata in metadataList) {
        try {
          // Déterminer si c'est un backup
          final isBackup = metadata.name.contains(GameConstants.BACKUP_DELIMITER);
          
          if (kDebugMode) {
            print('DIAGNOSTIC ADAPTER: Conversion SaveMetadata → SaveGameInfo pour ${metadata.id} (${metadata.name})');
            print('  - lastModified: ${metadata.lastModified}');
            print('  - version: ${metadata.version}');
            print('  - gameMode: ${metadata.gameMode}');
            print('  - isBackup: $isBackup');
          }
          
          // Créer un objet SaveGameInfo de base même sans données de jeu
          // Cela garantit qu'au moins la sauvegarde apparaîtra dans l'interface
          SaveGameInfo saveInfo = SaveGameInfo(
            id: metadata.id,
            name: metadata.name,
            timestamp: metadata.lastModified,
            version: metadata.version,
            paperclips: 0, // Valeur par défaut
            money: 0, // Valeur par défaut
            gameMode: metadata.gameMode,
            totalPaperclipsSold: 0,
            autoClipperCount: 0,
            isBackup: isBackup,
            isRestored: metadata.isRestored,
          );
          
          // Ensuite, essayons d'enrichir avec les données de jeu si possible
          try {
            if (!isBackup) {
              // Utiliser l'ID pour charger la sauvegarde, pas le nom
              final saveGame = await instance.loadSave(metadata.id);
              if (saveGame != null) {
                final gameData = saveGame.gameData;
                if (kDebugMode) {
                  print('  - Données de jeu chargées avec succès');
                  if (gameData.containsKey('playerManager')) {
                    print('    - playerManager trouvé: ${gameData['playerManager'] != null}');
                  } else {
                    print('    - playerManager NON TROUVÉ dans les données de jeu');
                  }
                }
                
                // Mise à jour des valeurs si playerManager existe
                try {
                  Map<String, dynamic>? playerMap;
                  // 1) Format legacy: playerManager à la racine
                  if (gameData.containsKey('playerManager') && gameData['playerManager'] is Map) {
                    playerMap = Map<String, dynamic>.from(gameData['playerManager'] as Map);
                  }
                  // 2) Nouveau format snapshot-only: gameSnapshot.core.playerManager
                  else if (gameData.containsKey('gameSnapshot')) {
                    final snap = gameData['gameSnapshot'];
                    if (snap is Map) {
                      final core = (snap['core'] is Map) ? Map<String, dynamic>.from(snap['core'] as Map) : null;
                      if (core != null && core['playerManager'] is Map) {
                        playerMap = Map<String, dynamic>.from(core['playerManager'] as Map);
                      }
                    }
                  }

                  if (playerMap != null) {
                    saveInfo = SaveGameInfo(
                      id: metadata.id,
                      name: metadata.name,
                      timestamp: metadata.lastModified,
                      version: metadata.version,
                      paperclips: (playerMap['paperclips'] as num?)?.toDouble() ?? 0,
                      money: (playerMap['money'] as num?)?.toDouble() ?? 0,
                      gameMode: metadata.gameMode,
                      totalPaperclipsSold: (playerMap['totalPaperclipsSold'] as num?)?.toDouble() ?? 0,
                      autoClipperCount: (playerMap['autoClipperCount'] as num?)?.toInt() ?? 0,
                      isBackup: isBackup,
                      isRestored: metadata.isRestored,
                    );
                  } else if (gameData.containsKey('gameSnapshot') && gameData['gameSnapshot'] is Map) {
                    // Fallback: extraire depuis snapshot core/stats (nouveau format sans playerManager)
                    final snap = Map<String, dynamic>.from(gameData['gameSnapshot'] as Map);
                    final core = (snap['core'] is Map) ? Map<String, dynamic>.from(snap['core'] as Map) : const <String, dynamic>{};
                    final stats = (snap['stats'] is Map) ? Map<String, dynamic>.from(snap['stats'] as Map) : const <String, dynamic>{};
                    final money = (core['money'] as num?)?.toDouble() ?? 0.0;
                    final clips = (stats['paperclips'] as num?)?.toDouble() ?? 0.0;
                    final sold = (stats['totalPaperclipsSold'] as num?)?.toDouble() ?? 0.0;
                    final auto = (core['autoClipperCount'] as num?)?.toInt() ?? 0;
                    saveInfo = SaveGameInfo(
                      id: metadata.id,
                      name: metadata.name,
                      timestamp: metadata.lastModified,
                      version: metadata.version,
                      paperclips: clips,
                      money: money,
                      gameMode: metadata.gameMode,
                      totalPaperclipsSold: sold,
                      autoClipperCount: auto,
                      isBackup: isBackup,
                      isRestored: metadata.isRestored,
                    );
                  }
                } catch (e) {
                  // En cas d'erreur, on garde les valeurs par défaut déjà définies
                  if (kDebugMode) {
                    print('  - Erreur lors de l\'extraction des données du joueur: $e');
                    print('  - Conservation des valeurs par défaut');
                  }
                }
              } else if (kDebugMode) {
                print('Attention: Sauvegarde ${metadata.id} (${metadata.name}) non trouvée, mais continuons avec les métadonnées');
              }
            }
          } catch (e) {
            // En cas d'erreur, on continue avec l'objet SaveGameInfo basique
            if (kDebugMode) {
              print('Erreur lors du chargement des données pour la sauvegarde ${metadata.id} (${metadata.name}): $e');
              print('Continuons avec les métadonnées de base');
            }
          }
          
          if (kDebugMode) {
            print('  - SaveGameInfo créé avec succès: ${saveInfo.toString()}');
            print('    - Attributs: money=${saveInfo.money}, paperclips=${saveInfo.paperclips}');
          }
          
          // Ajouter à la liste des résultats
          results.add(saveInfo);
        } catch (e) {
          // Log d'erreur mais continuons avec les autres sauvegardes
          if (kDebugMode) {
            print('Erreur lors du traitement de la sauvegarde ${metadata.id}: $e');
            print('Cette sauvegarde sera ignorée, mais les autres seront traitées');
          }
        }
      }
      
      if (kDebugMode) {
        print('DIAGNOSTIC ADAPTER: ${results.length}/${metadataList.length} sauvegardes converties avec succès');
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur critique lors de la liste des sauvegardes: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      return [];
    }
  }

  /// Supprime une sauvegarde
  static Future<void> deleteSave(String name) async {
    try {
      // deleteSave() du manager attend un ID; ici l'API publique expose un name.
      await deleteSaveByName(name);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression: $e');
      }
      rethrow;
    }
  }

  /// Supprime une sauvegarde à partir de son nom (name) plutôt que de son id.
  ///
  /// Utile pour les écrans UI où le concept manipulé est le nom de sauvegarde.
  static Future<void> deleteSaveByName(String name) async {
    try {
      await ensureInitialized();

      final metadatas = await instance.listSaves();
      final matching = metadatas.where((m) => m.name == name).toList();
      if (matching.isEmpty) {
        throw SaveError('delete_error', 'Sauvegarde introuvable');
      }

      // Si plusieurs entrées ont le même nom, on supprime la plus récente.
      matching.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final id = matching.first.id;

      await instance.deleteSave(id);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression (par name): $e');
      }
      rethrow;
    }
  }

  /// Compresse les données de sauvegarde (pour compatibilité)
  static Future<String> compressSaveData(Map<String, dynamic> data) async {
    // Convertir d'abord Map en JSON string
    final jsonString = jsonEncode(data);
    return instance.compressData(jsonString);
  }

  /// Décompresse les données de sauvegarde (pour compatibilité)
  static String decompressSaveData(String compressed) {
    return instance.decompressData(compressed);
  }

  /// Supprime une sauvegarde par identifiant unique
  static Future<void> deleteSaveById(String id) async {
    try {
      await ensureInitialized();
      await instance.deleteSave(id);
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la suppression (par id): $e');
      }
      rethrow;
    }
  }

  /// Récupère les métadonnées d'une sauvegarde par identifiant
  static Future<SaveMetadata?> getSaveMetadataById(String id) async {
    try {
      await ensureInitialized();
      return await instance.getSaveMetadata(id);
    } catch (e) {
      if (kDebugMode) {
        print('SaveManagerAdapter.getSaveMetadataById: ERREUR: $e');
      }
      return null;
    }
  }

  /// Met à jour les métadonnées d'une sauvegarde par identifiant
  static Future<bool> updateSaveMetadataById(String id, SaveMetadata metadata) async {
    try {
      await ensureInitialized();
      return await instance.updateSaveMetadata(id, metadata);
    } catch (e) {
      if (kDebugMode) {
        print('SaveManagerAdapter.updateSaveMetadataById: ERREUR: $e');
      }
      return false;
    }
  }

  /// Nettoie les anciennes sauvegardes automatiques
  static Future<void> _cleanupOldBackups(String gameName, int maxBackups) async {
    try {
      // Récupérer la liste des sauvegardes
      final allSaves = await listSaves();
      
      // Filtrer pour ne garder que les backups correspondant au nom du jeu
      final relatedBackups = allSaves.where(
        (save) => save.name.startsWith('$gameName${GameConstants.BACKUP_DELIMITER}')
      ).toList();
      
      // Trier par date (plus récent en premier)
      relatedBackups.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Utilisation de timestamp pour compatibilité avec SaveGameInfo
      
      // Supprimer les backups excédentaires
      if (relatedBackups.length > maxBackups) {
        for (var i = maxBackups; i < relatedBackups.length; i++) {
          await deleteSave(relatedBackups[i].name);
          if (kDebugMode) {
            print('Backup supprimé: ${relatedBackups[i].name}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du nettoyage des backups: $e');
      }
    }
  }

  /// Affiche les données de débogage d'une sauvegarde
  static Future<void> debugSaveData(String gameName) async {
    try {
      final data = await instance.loadSave(gameName);
      final metadata = await instance.getSaveMetadata(gameName);
      
      if (kDebugMode) {
        print('Debug - Save data for $gameName:');
        print('Metadata: $metadata');
        print('Data: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug - Error reading save: $e');
      }
    }
  }
}

/// Exception spécifique pour les erreurs de sauvegarde (pour compatibilité)
class SaveError implements Exception {
  final String code;
  final String message;
  
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
}
