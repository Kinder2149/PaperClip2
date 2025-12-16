/// lib/services/save_migration_service.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/constants/storage_keys.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/persistence/local_game_persistence.dart';
import 'package:paperclip2/services/save_system/save_manager_adapter.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Structure de résultat de migration pour un suivi précis
class MigrationResult {
  final int successCount;
  final int failureCount;
  final List<String> successNames;
  final Map<String, String> failures;
  final int scannedCount;
  final Duration duration;
  
  const MigrationResult({
    required this.successCount,
    required this.failureCount,
    required this.successNames,
    required this.failures,
    this.scannedCount = 0,
    this.duration = Duration.zero,
  });
  
  @override
  String toString() => 'Migrations réussies: $successCount, Échecs: $failureCount';
}

/// Service permettant la migration des sauvegardes d'une version à une autre
class SaveMigrationService {
  // Logger pour les opérations de migration
  static final Logger _logger = Logger('SaveMigrationService');
  
  // Préfixe utilisé par l'ancien système de sauvegarde
  static const String OLD_SAVE_PREFIX = StorageKeys.legacySavePrefix;
  
  // Versions du format de sauvegarde
  static const String CURRENT_SAVE_FORMAT_VERSION = '2.0';
  static const List<String> SUPPORTED_VERSIONS = ['1.0', '1.5', '2.0'];

  static const String _legacyPreMigrationBackupSuffix = '_backup_pre_migration';
  static const String _legacyPreMigrationBackupTimestampedMarker = '_backup_pre_migration_';

  static const String _compactionFlagKey = 'save_compaction_v1_done';
  
  /// Journal des migrations effectuées (pour debugging)
  static final List<String> _migrationLogs = [];
  
  /// Historique des chemins de migration supportés
  static final Map<String, List<String>> _migrationPaths = {
    '1.0': ['1.0', '1.5', '2.0'],
    '1.5': ['1.5', '2.0'],
    '2.0': ['2.0'],
  };
  
  /// Récupérer les logs de migration
  static List<String> getMigrationLogs() => List.unmodifiable(_migrationLogs);
  
  /// Effacer les logs de migration
  static void clearMigrationLogs() => _migrationLogs.clear();
  
  /// Ajouter une entrée de log
  static void _log(String message) {
    _logger.info(message);
    
    // Conserver dans le journal interne pour debuggage
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = "[$timestamp] $message";
    _migrationLogs.add(logEntry);
    
    if (kDebugMode) {
      print("[SaveMigrationService] $message");
    }

    // Limiter le nombre de logs conservés en mémoire
    if (_migrationLogs.length > 100) {
      _migrationLogs.removeRange(0, 50);
    }
  }

  static String _stablePreMigrationBackupKey(String legacySaveKey) {
    return '$legacySaveKey$_legacyPreMigrationBackupSuffix';
  }

  static Future<void> _cleanupLegacyTimestampedBackups(SharedPreferences prefs) async {
    try {
      final allKeys = prefs.getKeys();
      final keysToDelete = allKeys.where((key) =>
          key.startsWith(OLD_SAVE_PREFIX) &&
          key.contains(_legacyPreMigrationBackupTimestampedMarker));

      for (final key in keysToDelete) {
        await prefs.remove(key);
      }
    } catch (e) {
      _log('Nettoyage des backups legacy timestampés ignoré: $e');
    }
  }

  /// Migration lazy: migre au maximum [maxToMigrate] sauvegardes legacy (ancien système)
  /// vers le nouveau format, puis s'arrête.
  ///
  /// Objectif: éviter de bloquer le boot; la migration se fait à l'ouverture de l'écran de sauvegardes.
  ///
  /// - Les backups pré-migration sont idempotents: une seule copie stable par sauvegarde.
  /// - Les anciens backups timestampés (historique d'anciennes exécutions) sont purgés.
  static Future<MigrationResult> migrateLegacySavesIfNeeded({
    int maxToMigrate = 5,
    void Function(int migrated, int total)? onProgress,
  }) async {
    final sw = Stopwatch()..start();

    final List<String> successNames = [];
    final Map<String, String> failures = {};

    int scanned = 0;

    try {
      final prefs = await SharedPreferences.getInstance();

      await _cleanupLegacyTimestampedBackups(prefs);
      await SaveManagerAdapter.ensureInitialized();

      final allKeys = prefs.getKeys();
      final legacySaveKeys = allKeys
          .where((key) =>
              key.startsWith(OLD_SAVE_PREFIX) &&
              !key.contains(StorageKeys.backupDelimiter) &&
              !key.endsWith(_legacyPreMigrationBackupSuffix) &&
              !key.contains(_legacyPreMigrationBackupTimestampedMarker))
          .toList();

      // Rien à faire.
      if (legacySaveKeys.isEmpty) {
        sw.stop();
        return MigrationResult(
          successCount: 0,
          failureCount: 0,
          successNames: const [],
          failures: const {},
          scannedCount: 0,
          duration: sw.elapsed,
        );
      }

      final total = legacySaveKeys.length;
      final limit = maxToMigrate < 0 ? total : maxToMigrate;

      for (final saveKey in legacySaveKeys) {
        if (successNames.length + failures.length >= limit) {
          break;
        }

        scanned++;
        final saveName = saveKey.substring(OLD_SAVE_PREFIX.length);
        final savedData = prefs.getString(saveKey);
        if (savedData == null) {
          continue;
        }

        try {
          // Backup stable (idempotent) avant toute tentative.
          final stableBackupKey = _stablePreMigrationBackupKey(saveKey);
          if (!prefs.containsKey(stableBackupKey)) {
            await prefs.setString(stableBackupKey, savedData);
          }

          Map<String, dynamic> data;
          final decoded = jsonDecode(savedData);
          if (decoded is! Map<String, dynamic>) {
            throw FormatException('Format de données invalide, Map<String, dynamic> attendu');
          }
          data = decoded;

          String version = '1.0';
          if (data.containsKey('version') && data['version'] is String) {
            version = data['version'] as String;
          }

          if (version == CURRENT_SAVE_FORMAT_VERSION) {
            // Déjà compatible: on peut retirer la clé legacy.
            // (elle a déjà un backup stable si nécessaire)
            await prefs.remove(saveKey);
            await prefs.remove(stableBackupKey);
            successNames.add(saveName);
            onProgress?.call(successNames.length, total);
            continue;
          }

          if (!_migrationPaths.containsKey(version)) {
            throw UnsupportedError('Version non supportée pour la migration: $version');
          }

          final migratedData = await migrateData(data, version, CURRENT_SAVE_FORMAT_VERSION);
          final validationResult = SaveValidator.validate(migratedData);
          if (!validationResult.isValid) {
            throw FormatException(
                'Les données migrées ne passent pas la validation d\'intégrité: ${validationResult.errors.join(", ")}');
          }

          final String uuid = data['id'] as String? ?? const Uuid().v4();
          final saveGame = _createSaveGameFromMigratedData(migratedData, saveName, uuid);
          await SaveManagerAdapter.instance.saveGame(saveGame);

          await prefs.remove(saveKey);
          await prefs.remove(stableBackupKey);

          successNames.add(saveName);
          onProgress?.call(successNames.length, total);
        } catch (e) {
          failures[saveName] = e.toString();
          onProgress?.call(successNames.length, total);
        }
      }

      sw.stop();
      return MigrationResult(
        successCount: successNames.length,
        failureCount: failures.length,
        successNames: successNames,
        failures: failures,
        scannedCount: scanned,
        duration: sw.elapsed,
      );
    } catch (e) {
      sw.stop();
      failures['GENERAL'] = e.toString();
      return MigrationResult(
        successCount: successNames.length,
        failureCount: failures.length,
        successNames: successNames,
        failures: failures,
        scannedCount: scanned,
        duration: sw.elapsed,
      );
    }
  }

  static Future<void> compactAllSaves({bool includeBackups = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_compactionFlagKey) ?? false;
    if (alreadyDone) {
      return;
    }

    await SaveManagerAdapter.ensureInitialized();

    final metadatas = await SaveManagerAdapter.instance.listSaves();
    for (final meta in metadatas) {
      if (!includeBackups && meta.name.contains(GameConstants.BACKUP_DELIMITER)) {
        continue;
      }

      try {
        final loaded = await SaveManagerAdapter.instance.loadSave(meta.id);
        if (loaded == null) {
          continue;
        }

        final updatedGameData = Map<String, dynamic>.from(loaded.gameData);

        updatedGameData.remove('totalTimePlayedInSeconds');
        updatedGameData.remove('totalPaperclipsProduced');

        final snapshotKey = LocalGamePersistenceService.snapshotKey;
        if (updatedGameData.containsKey(snapshotKey)) {
          final rawSnapshot = updatedGameData[snapshotKey];

          if (rawSnapshot is Map) {
            final snapMap = Map<String, dynamic>.from(rawSnapshot as Map);
            final metaMapRaw = snapMap['metadata'];
            if (metaMapRaw is Map) {
              final snapMeta = Map<String, dynamic>.from(metaMapRaw as Map);
              snapMeta.remove('totalTimePlayedInSeconds');
              snapMeta.remove('totalPaperclipsProduced');
              snapMap['metadata'] = snapMeta;
            }
            updatedGameData[snapshotKey] = snapMap;
          } else if (rawSnapshot is String) {
            try {
              final decoded = jsonDecode(rawSnapshot);
              if (decoded is Map<String, dynamic>) {
                final snapMap = Map<String, dynamic>.from(decoded);
                final metaMapRaw = snapMap['metadata'];
                if (metaMapRaw is Map) {
                  final snapMeta = Map<String, dynamic>.from(metaMapRaw as Map);
                  snapMeta.remove('totalTimePlayedInSeconds');
                  snapMeta.remove('totalPaperclipsProduced');
                  snapMap['metadata'] = snapMeta;
                }
                updatedGameData[snapshotKey] = jsonEncode(snapMap);
              }
            } catch (_) {
              // Ignorer si le snapshot n'est pas un JSON valide.
            }
          }
        }

        final updated = SaveGame(
          id: meta.id,
          name: meta.name,
          lastSaveTime: DateTime.now(),
          gameData: updatedGameData,
          version: meta.version,
          gameMode: meta.gameMode,
          isRestored: meta.isRestored,
        );

        await SaveManagerAdapter.saveGame(updated);
      } catch (e) {
        _log('Compaction ignorée pour ${meta.name} (${meta.id}): $e');
      }
    }

    await prefs.setBool(_compactionFlagKey, true);
  }
  
  /// Migre toutes les sauvegardes existantes vers le nouveau format
  /// Retourne un rapport détaillé des migrations réussies et échouées
  static Future<MigrationResult> migrateAllSaves() async {
    _log('Début de la migration des sauvegardes vers la version $CURRENT_SAVE_FORMAT_VERSION');
    
    final List<String> successNames = [];
    final Map<String, String> failures = {};
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Créer une sauvegarde de toutes les données avant migration
      final migrationBackup = <String, String>{};
      final allKeys = prefs.getKeys();
      final savesToMigrate = allKeys.where((key) => 
          key.startsWith(OLD_SAVE_PREFIX) && !key.contains(GameConstants.BACKUP_DELIMITER));
      
      _log('Nombre de sauvegardes à migrer: ${savesToMigrate.length}');
      
      // Créer des backups avant migration
      for (final saveKey in savesToMigrate) {
        final savedData = prefs.getString(saveKey);
        if (savedData != null) {
          final backupKey = '${saveKey}_backup_pre_migration_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString(backupKey, savedData);
          migrationBackup[saveKey] = backupKey;
          _log('Backup créé pour $saveKey -> $backupKey');
        }
      }
      
      // Migrer chaque sauvegarde
      for (final saveKey in savesToMigrate) {
        final saveName = saveKey.substring(OLD_SAVE_PREFIX.length);
        final savedData = prefs.getString(saveKey);
        
        if (savedData == null) {
          _log('Aucune donnée trouvée pour $saveKey, ignoré');
          continue;
        }
        
        try {
          _log('Traitement de la sauvegarde: $saveName');
          
          // Décoder les données de sauvegarde avec validation
          Map<String, dynamic> data;
          try {
            final decoded = jsonDecode(savedData);
            if (decoded is! Map<String, dynamic>) {
              throw FormatException('Format de données invalide, Map<String, dynamic> attendu');
            }
            data = decoded;
          } catch (e) {
            throw FormatException('Erreur de décodage JSON: $e');
          }
          
          // Vérifier la version avec validation
          String version = '1.0'; // Version par défaut
          try {
            if (data.containsKey('version') && data['version'] is String) {
              version = data['version'] as String;
            }
          } catch (e) {
            _log('Erreur lors de l\'extraction de la version, utilisation de la version par défaut 1.0: $e');
          }
          
          _log('Version détectée: $version');
          
          // Vérifier si la migration est nécessaire
          if (version == CURRENT_SAVE_FORMAT_VERSION) {
            _log('Sauvegarde $saveName déjà en version $CURRENT_SAVE_FORMAT_VERSION, ignorée');
            continue;
          }
          
          // Vérifier si un chemin de migration existe
          if (!_migrationPaths.containsKey(version)) {
            throw UnsupportedError('Version non supportée pour la migration: $version');
          }
          
          // Migrer les données étape par étape
          _log('Début de la migration: $version -> $CURRENT_SAVE_FORMAT_VERSION');
          final migratedData = await migrateData(data, version, CURRENT_SAVE_FORMAT_VERSION);
          
          // Vérifier l'intégrité des données migrées
          final validationResult = SaveValidator.validate(migratedData);
          if (!validationResult.isValid) {
            throw FormatException('Les données migrées ne passent pas la validation d\'intégrité: ${validationResult.errors.join(", ")}');
          }
          
          // Créer un SaveGame avec UUID
          final String uuid = data['id'] as String? ?? const Uuid().v4();
          _log('ID de sauvegarde: $uuid');
          
          // Sauvegarder les données migrées via l'adaptateur (SaveManagerAdapter)
          final saveGame = _createSaveGameFromMigratedData(migratedData, saveName, uuid);
          await SaveManagerAdapter.instance.saveGame(saveGame);  // Utilisation de l'instance de SaveManagerAdapter
          
          // Supprimer l'ancienne sauvegarde uniquement après migration réussie
          await prefs.remove(saveKey);
          _log('Ancienne sauvegarde supprimée: $saveKey');
          
          // Supprimer le backup pré-migration si tout s'est bien passé
          if (migrationBackup.containsKey(saveKey)) {
            await prefs.remove(migrationBackup[saveKey]!);
            _log('Backup supprimé après migration réussie: ${migrationBackup[saveKey]}');
          }
          
          // Enregistrer le succès
          successNames.add(saveName);
          _log('Migration réussie pour $saveName');
        } catch (e) {
          // Enregistrer l'échec
          failures[saveName] = e.toString();
          _log('ECHEC Migration pour $saveName: $e');
        }
      }
      
      // Résultat final
      _log('Migration terminée: ${successNames.length} réussies, ${failures.length} échouées');
      
      return MigrationResult(
        successCount: successNames.length,
        failureCount: failures.length,
        successNames: successNames,
        failures: failures,
        scannedCount: savesToMigrate.length,
      );
    } catch (e) {
      _log('ERREUR CRITIQUE lors de la migration: $e');
      return MigrationResult(
        successCount: successNames.length,
        failureCount: failures.length + 1, // +1 pour l'erreur générale
        successNames: successNames,
        failures: {...failures, 'GENERAL': e.toString()},
        duration: Duration.zero,
      );
    }
  }
  
  /// Migre les données d'une version à une autre
  /// Applique une stratégie de migration séquentielle entre versions intermédiaires
  static Future<Map<String, dynamic>> migrateData(
    Map<String, dynamic> oldData,
    String fromVersion,
    String toVersion
  ) async {
    _log('Début de migration: $fromVersion -> $toVersion');
    
    // Vérifier la disponibilité des chemins de migration
    if (!_migrationPaths.containsKey(fromVersion)) {
      throw UnsupportedError('Version source non supportée: $fromVersion');
    }
    
    final List<String> path = _migrationPaths[fromVersion] ?? [];
    if (!path.contains(toVersion)) {
      throw UnsupportedError('Pas de chemin de migration disponible de $fromVersion vers $toVersion');
    }
    
    // Migration séquentielle étape par étape
    Map<String, dynamic> currentData = Map<String, dynamic>.from(oldData);
    String currentVersion = fromVersion;
    
    // Trouver la position de la version source et cible dans le chemin
    final int startIndex = path.indexOf(fromVersion);
    final int endIndex = path.indexOf(toVersion);
    
    if (startIndex >= endIndex) {
      // Déjà dans une version plus récente ou égale, pas besoin de migrer
      _log('Déjà dans la version cible ou plus récente');
      return currentData;
    }
    
    // Parcourir le chemin de migration par étapes
    for (int i = startIndex; i < endIndex; i++) {
      final String nextVersion = path[i + 1];
      _log('Migration étape: ${path[i]} -> $nextVersion');
      
      // Appliquer la migration spécifique pour cette étape
      currentData = await _applyMigrationStep(currentData, path[i], nextVersion);
      currentVersion = nextVersion;
      
      _log('Migration étape terminée: version actuelle = $currentVersion');
    }
    
    // Vérifier que la migration a réussi
    if (currentVersion != toVersion) {
      throw Exception('Migration échouée: version finale $currentVersion ne correspond pas à la cible $toVersion');
    }
    
    _log('Migration terminée avec succès: $fromVersion -> $toVersion');
    return currentData;
  }
  
  /// Applique une étape spécifique de migration entre deux versions adjacentes
  static Future<Map<String, dynamic>> _applyMigrationStep(
    Map<String, dynamic> data,
    String fromVersion,
    String nextVersion
  ) async {
    // Sélectionner la fonction de migration appropriée
    if (fromVersion == '1.0' && nextVersion == '1.5') {
      return _migrateFrom1To1_5(data);
    } else if (fromVersion == '1.5' && nextVersion == '2.0') {
      return _migrateFrom1_5To2(data);
    } else if (fromVersion == '1.0' && nextVersion == '2.0') {
      // Migration directe possible également
      return _migrateFrom1To2(data);
    } else {
      // Si aucune migration spécifique n'est définie, mettre à jour la version
      _log('Aucune migration spécifique définie pour $fromVersion -> $nextVersion, mise à jour de la version uniquement');
      final result = Map<String, dynamic>.from(data);
      result['version'] = nextVersion;
      return result;
    }
  }

  /// Migration spécifique de la version 1.0 à 1.5 (format intermédiaire)
  static Future<Map<String, dynamic>> _migrateFrom1To1_5(Map<String, dynamic> data) async {
    _log('Application migration 1.0 -> 1.5');
    final Map<String, dynamic> migratedData = Map<String, dynamic>.from(data);
    
    // Ajouter l'identifiant unique s'il n'existe pas
    if (!migratedData.containsKey('id') || migratedData['id'] == null) {
      migratedData['id'] = const Uuid().v4();
      _log('UUID généré: ${migratedData['id']}');
    }
    
    // Ajouter ou mettre à jour le timestamp si nécessaire
    if (!migratedData.containsKey('timestamp') || migratedData['timestamp'] == null) {
      migratedData['timestamp'] = DateTime.now().toIso8601String();
      _log('Timestamp ajouté: ${migratedData['timestamp']}');
    }
    
    // Conversion Wire -> Metal (rétro-compatibilité)
    if (migratedData.containsKey('playerManager')) {
      final playerData = migratedData['playerManager'] as Map<String, dynamic>? ?? {};
      
      // Vérifier et convertir wire en metal
      if (playerData.containsKey('wire') && !playerData.containsKey('metal')) {
        final double wireValue = (playerData['wire'] as num?)?.toDouble() ?? 0.0;
        playerData['metal'] = wireValue;
        _log('Conversion wire -> metal: $wireValue');
      }
    }
    
    // Mettre à jour la version
    migratedData['version'] = '1.5';
    _log('Version mise à jour: 1.5');
    
    return migratedData;
  }
  
  /// Migration spécifique de la version 1.5 à 2.0
  static Future<Map<String, dynamic>> _migrateFrom1_5To2(Map<String, dynamic> data) async {
    _log('Application migration 1.5 -> 2.0');
    final Map<String, dynamic> migratedData = Map<String, dynamic>.from(data);
    
    // Restructurer les données dans gameData si nécessaire
    if (!migratedData.containsKey('gameData')) {
      final Map<String, dynamic> gameData = {};
      _log('Création de la structure gameData');
      
      // Déplacer les données du jeu dans un sous-objet gameData
      final keysToMove = ['playerManager', 'marketManager', 'levelSystem', 
                         'productionManager', 'statistics', 'resourceManager'];
      
      for (final key in keysToMove) {
        if (migratedData.containsKey(key)) {
          gameData[key] = migratedData.remove(key);
          _log('Déplacé $key dans gameData');
        }
      }
      
      // Ajouter le mode de jeu
      if (migratedData.containsKey('gameMode')) {
        gameData['gameMode'] = migratedData['gameMode'];
        _log('Mode de jeu déplacé dans gameData');
      } else {
        // Par défaut: mode infini
        gameData['gameMode'] = GameMode.INFINITE.index;
        _log('Mode de jeu par défaut ajouté: INFINITE');
      }
      
      // Conserver temps de jeu
      if (migratedData.containsKey('totalTimePlayedInSeconds')) {
        gameData['totalTimePlayedInSeconds'] = migratedData['totalTimePlayedInSeconds'];
        _log('Temps de jeu déplacé dans gameData');
      }
      
      migratedData['gameData'] = gameData;
    }
    
    // Ajouter la version du format
    migratedData['version'] = CURRENT_SAVE_FORMAT_VERSION;
    _log('Version mise à jour: $CURRENT_SAVE_FORMAT_VERSION');
    
    return migratedData;
  }

  /// Migration spécifique de la version 1.0 à 2.0 (directe)
  static Future<Map<String, dynamic>> _migrateFrom1To2(Map<String, dynamic> data) async {
    _log('Application migration directe 1.0 -> 2.0');
    
    // Pour la migration directe, nous appliquons séquentiellement les deux étapes
    final intermediate = await _migrateFrom1To1_5(data);
    return _migrateFrom1_5To2(intermediate);
  }

  /// Crée un objet SaveGame à partir des données migrées
  static SaveGame _createSaveGameFromMigratedData(Map<String, dynamic> data, String saveName, [String? uuid]) {
    _log('Création de l\'objet SaveGame pour: $saveName');
    
    try {
      // Utiliser l'UUID existant ou en générer un nouveau
      final String id = uuid ?? data['id'] as String? ?? const Uuid().v4();
      _log('UUID utilisé: $id');
      
      // Extraire le timestamp avec validation
      DateTime timestamp;
      try {
        if (data['timestamp'] != null) {
          timestamp = DateTime.parse(data['timestamp'].toString());
        } else {
          timestamp = DateTime.now();
          _log('Aucun timestamp trouvé, utilisation de la date actuelle');
        }
      } catch (e) {
        _log('Erreur lors du parsing du timestamp: $e');
        timestamp = DateTime.now();
      }
      
      // Extraire la version avec validation
      final String version = data['version'] as String? ?? CURRENT_SAVE_FORMAT_VERSION;
      
      // Extraire le mode de jeu avec validation
      GameMode gameMode = GameMode.INFINITE;
      try {
        if (data['gameMode'] != null && data['gameMode'] is int) {
          final int modeIndex = data['gameMode'] as int;
          if (modeIndex >= 0 && modeIndex < GameMode.values.length) {
            gameMode = GameMode.values[modeIndex];
          }
        } else if (data['gameData']?['gameMode'] != null && data['gameData']['gameMode'] is int) {
          final int modeIndex = data['gameData']['gameMode'] as int;
          if (modeIndex >= 0 && modeIndex < GameMode.values.length) {
            gameMode = GameMode.values[modeIndex];
          }
        } else {
          _log('Mode de jeu non trouvé ou invalide, utilisation du mode par défaut: INFINITE');
        }
      } catch (e) {
        _log('Erreur lors de l\'extraction du mode de jeu: $e');
      }
      
      // Vérifier que gameData existe et est valide
      if (!data.containsKey('gameData') || data['gameData'] is! Map<String, dynamic>) {
        _log('gameData manquant ou invalide, création d\'une structure vide');
        data['gameData'] = <String, dynamic>{};
      }
      
      // Créer l'objet SaveGame
      return SaveGame(
        id: id,
        name: saveName,
        lastSaveTime: timestamp,
        gameData: data['gameData'] as Map<String, dynamic>,
        version: version,
        gameMode: gameMode,
      );
    } catch (e) {
      _log('ERREUR lors de la création du SaveGame: $e');
      
      // Créer un objet SaveGame minimal en cas d'échec
      return SaveGame(
        id: uuid ?? const Uuid().v4(),
        name: saveName,
        lastSaveTime: DateTime.now(),
        gameData: <String, dynamic>{},
        version: CURRENT_SAVE_FORMAT_VERSION,
        gameMode: GameMode.INFINITE,
      );
    }
  }
}
