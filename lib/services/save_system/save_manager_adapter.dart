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

  /// Liste les backups pour un `partieId` donné (ID-first): nom commence par '<partieId>|'.
  static Future<List<SaveGameInfo>> listBackupsForPartie(String partieId) async {
    final all = await listSaves();
    final prefix = '$partieId${GameConstants.BACKUP_DELIMITER}';
    final backups = all.where((s) => s.isBackup && s.name.startsWith(prefix)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return backups;
  }

  /// Applique la politique de rétention pour un `partieId` donné: garde au plus N récents et supprime ceux plus vieux que TTL.
  static Future<int> applyBackupRetention({
    required String partieId,
    int? max,
    Duration? ttl,
  }) async {
    await ensureInitialized();
    final maxKeep = max ?? GameConstants.BACKUP_RETENTION_MAX;
    final ttlDur = ttl ?? GameConstants.BACKUP_RETENTION_TTL;
    final now = DateTime.now();
    final backups = await listBackupsForPartie(partieId);

    int deleted = 0;

    // 1) Supprimer par TTL
    for (final b in backups) {
      final age = now.difference(b.timestamp);
      if (age > ttlDur) {
        await instance.deleteSave(b.id);
        deleted++;
      }
    }

    // Recharger après TTL purge
    final remaining = (await listBackupsForPartie(partieId));
    if (remaining.length > maxKeep) {
      // Supprimer les plus anciens au-delà du quota
      final toDelete = remaining.sublist(maxKeep); // déjà triés desc
      for (final b in toDelete) {
        await instance.deleteSave(b.id);
        deleted++;
      }
    }

    return deleted;
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

  // Méthode legacy saveGameState(name) supprimée (ID-first uniquement)

  /// Crée une sauvegarde de secours
  static Future<bool> createBackup(GameState gameState) async {
    try {
      final currentTime = DateTime.now();
      // Mission 5: Backups internes indexés uniquement par partieId; refuser si absent
      final baseKey = gameState.partieId;
      if (baseKey == null || baseKey.isEmpty) {
        if (kDebugMode) {
          print('SaveManagerAdapter.createBackup: partieId manquant – backup refusé');
        }
        return false;
      }
      final backupName = '$baseKey${GameConstants.BACKUP_DELIMITER}${currentTime.millisecondsSinceEpoch}';
      // Backups snapshot-only: stocker strictement le GameSnapshot sérialisé
      final snapshotJson = gameState.toSnapshot().toJson();
      Map<String, dynamic> gameData = {
        'gameSnapshot': snapshotJson,
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
        // Ancien nettoyage (compat): limite legacy locale
        await _cleanupOldBackups(baseKey, GameConstants.MAX_BACKUPS);
        // Nouvelle rétention Phase 4: N=10 et TTL=30j par identifiant de partie (ID-first)
        try {
          await applyBackupRetention(partieId: baseKey);
        } catch (e) {
          if (kDebugMode) {
            print('Rétention backups (Phase 4) échouée pour $baseKey: $e');
          }
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la création de la sauvegarde de secours: $e');
      }
      return false;
    }
  }

  // Méthode legacy saveExists(name) supprimée (ID-first uniquement)

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

  // Méthode legacy loadGame(name) supprimée (ID-first uniquement)

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

      // Extraire les données du jeu de la sauvegarde de backup
      final backupSave = await instance.loadSave(backupId);
      if (backupSave == null) return false;
      
      // Utilisez une assertion non-null pour gameData, car backupSave n'est pas null
      final Map<String, dynamic> extractedGameData = backupSave.gameData;

      // Mission 5: Restore sans création – on exige un partieId cible existant
      final targetId = gameState.partieId;
      if (targetId == null || targetId.isEmpty) {
        if (kDebugMode) {
          print('SaveManagerAdapter.restoreFromBackup: partieId manquant – restauration refusée');
        }
        return false;
      }
      // Récupérer les métadonnées de la sauvegarde cible (ID-first)
      final targetMeta = await instance.getSaveMetadata(targetId);
      if (targetMeta == null) {
        // Pas de création implicite: on refuse la restauration si la cible n'existe pas
        if (kDebugMode) {
          print('SaveManagerAdapter.restoreFromBackup: cible introuvable pour ID=$targetId – aucune création');
        }
        return false;
      }

      // Construire une sauvegarde avec l'ID cible et conserver le nom existant de la cible
      final SaveGame newSave = SaveGame(
        id: targetId,
        name: targetMeta.name,
        lastSaveTime: DateTime.now(),
        gameData: extractedGameData,
        version: backupMeta.version,
        gameMode: backupMeta.gameMode,
        isRestored: true,
      );

      // Sauvegarder (overwrite strict de l'ID cible)
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

  // Méthode legacy deleteSave(name) supprimée (ID-first uniquement)

  // Méthode legacy deleteSaveByName(name) supprimée (ID-first uniquement)

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
          await deleteSaveById(relatedBackups[i].id);
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
