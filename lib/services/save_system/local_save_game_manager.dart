// lib/services/save_system/local_save_game_manager.dart
// Gestionnaire de sauvegardes locales

import 'dart:async'; // Pour StreamController, Future et TimeoutException
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'noop_shared_preferences.dart'; // Notre fallback pour SharedPreferences
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/persistence/game_data_compat.dart';
import 'package:paperclip2/constants/storage_keys.dart';
// Toutes les constantes de stockage sont maintenant dans game_config.dart
import 'package:paperclip2/models/save_metadata.dart';
import 'package:paperclip2/models/save_game.dart';
import 'package:paperclip2/services/save_system/save_game_manager.dart';
import 'package:paperclip2/services/save_system/data_sanitizer.dart';
import 'package:paperclip2/services/save_system/save_validator.dart';

/// Implémentation du gestionnaire de sauvegardes pour les sauvegardes locales.
/// 
/// Cette classe gère le stockage, le chargement et la gestion des sauvegardes
/// locales sur l'appareil de l'utilisateur.
class LocalSaveGameManager implements SaveGameManager {
  static const String _metadataPrefix = StorageKeys.saveMetadataPrefix;
  static const String _saveDataPrefix = StorageKeys.saveDataPrefix;
  
  // Constantes pour la persistance des sauvegardes
  static const int _maxSaveAge = 365; // Durée maximale en jours avant archivage
  static const int _backupExpiration = 30; // Durée en jours avant suppression des backups
  static const int _cleanupInterval = 7; // Nettoyage automatique tous les 7 jours
  static const String _lastCleanupKey = 'last_saves_cleanup_timestamp'; // Clé pour stocker la dernière date de nettoyage
  
  // Log des préfixes au démarrage pour le debug
  static bool _prefixesLogged = false;
  static void _logPrefixes() {
    if (!_prefixesLogged && kDebugMode) {
      print('DIAGNOSTIC - PREFIXES: metadata="$_metadataPrefix", data="$_saveDataPrefix"');
      _prefixesLogged = true;
    }
  }
  
  /// Logger pour les opérations de sauvegarde
  late Logger _logger;
  
  /// Instance de SharedPreferences pour le stockage
  late SharedPreferences _prefs;
  
  /// Timer pour l'auto-sauvegarde
  Timer? _autoSaveTimer;
  
  /// ID de la sauvegarde active (actuellement chargée)
  String? _activeSaveId;
  
  /// Cache des métadonnées pour améliorer les performances
  final Map<String, SaveMetadata> _metadataCache = {};
  
  /// Indique si le manager a été initialisé
  bool _initialized = false;
  
  /// Constructeur privé pour le modèle Singleton
  LocalSaveGameManager._();
  
  /// Instance unique (Singleton)
  static LocalSaveGameManager? _instance;
  
  /// Récupère l'instance unique du gestionnaire de sauvegardes locales
  static Future<LocalSaveGameManager> getInstance() async {
    try {
      if (kDebugMode) {
        print('LocalSaveGameManager.getInstance: Démarrage...');
      }
      
      if (_instance == null) {
        if (kDebugMode) {
          print('LocalSaveGameManager.getInstance: Création nouvelle instance...');
        }
        _instance = LocalSaveGameManager._();
        
        if (kDebugMode) {
          print('LocalSaveGameManager.getInstance: Appel _initialize()...');
        }
        await _instance!._initialize().timeout(
          const Duration(seconds: 10), 
          onTimeout: () {
            if (kDebugMode) {
              print('LocalSaveGameManager.getInstance: TIMEOUT _initialize() après 10 secondes!');
            }
            throw TimeoutException('Initialisation du gestionnaire de sauvegarde a expiré après 10 secondes');
          }
        );
      }
      
      if (kDebugMode) {
        print('LocalSaveGameManager.getInstance: Retour instance complète');
      }
      
      return _instance!;
    } catch (e) {
      if (kDebugMode) {
        print('LocalSaveGameManager.getInstance: ERREUR CRITIQUE: $e');
      }
      // En cas d'erreur grave, initialiser une instance minimale
      if (_instance == null) {
        _instance = LocalSaveGameManager._();
        _instance!._initialized = true; // Force l'initialisation pour éviter le blocage
      }
      
      if (kDebugMode) {
        print('LocalSaveGameManager.getInstance: Retour instance de secours');
      }
      
      return _instance!;
    }
  }
  
  /// Initialise le gestionnaire de sauvegardes
  Future<void> _initialize() async {
    if (_initialized) return;
    
    // Marquer comme initialisé immédiatement pour éviter les boucles d'initialisation
    // lorsque des méthodes appelées pendant l'initialisation réutilisent _ensureInitialized()
    _initialized = true;
    
    try {
      _logger = Logger('LocalSaveGameManager');
      _logger.info('Initialisation du gestionnaire de sauvegarde local');
      if (kDebugMode) {
        print('_initialize: Demande de SharedPreferences.getInstance()');
      }
      
      // Protection spéciale pour l'appel à SharedPreferences.getInstance()
      // en cas d'exception non gérée
      SharedPreferences? tempPrefs;
      try {
        // Utiliser une variable temporaire pour éviter les problèmes de null safety
        tempPrefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            if (kDebugMode) {
              print('_initialize: TIMEOUT SharedPreferences.getInstance() après 5 secondes!');
            }
            throw TimeoutException('Obtention de SharedPreferences a expiré après 5 secondes');
          },
        );
        
        if (kDebugMode) {
          print('_initialize: SharedPreferences obtenues avec succès (type: ${tempPrefs.runtimeType})');
        }
        
        // Vérifier si l'instance est bien du type attendu (pas NoopSharedPreferences)
        if (tempPrefs is NoopSharedPreferences) {
          if (kDebugMode) {
            print('⚠️ ATTENTION: SharedPreferences.getInstance() a retourné une instance NoopSharedPreferences!');
            print('⚠️ Les sauvegardes ne seront PAS PERSISTANTES entre les sessions!');
          }
          _logger.severe('SharedPreferences.getInstance() a retourné une instance NoopSharedPreferences');
        }
      } catch (prefError) {
        if (kDebugMode) {
          print('_initialize: ERREUR pendant SharedPreferences.getInstance(): $prefError');
          print('_initialize: Stacktrace: ${StackTrace.current}');
        }
        
        // Créer une instance vide de SharedPreferences en mode de récupération
        // Initialisation minimale pour permettre à l'application de continuer
        try {
          tempPrefs = await _createEmptyPreferences();
          if (kDebugMode) {
            print('_initialize: Création d\'une instance vide de SharedPreferences pour récupération');
          }
        } catch (fallbackError) {
          if (kDebugMode) {
            print('_initialize: ERREUR CRITIQUE même avec fallback: $fallbackError');
          }
          // Même en cas d'erreur du fallback, on crée une instance en mémoire simple
          tempPrefs = NoopSharedPreferences();
        }
      }
      
      // Assigner l'instance uniquement après tout le traitement des erreurs
      _prefs = tempPrefs!;
      
      // Tester la persistance pour s'assurer du bon fonctionnement
      await _testPersistence();
      
      // Précharger le cache des métadonnées
      if (kDebugMode) {
        print('_initialize: Début du chargement du cache des métadonnées');
      }
      
      try {
        await _loadMetadataCache();
        if (kDebugMode) {
          print('_initialize: Cache des métadonnées chargé avec succès');
        }
      } catch (cacheError) {
        if (kDebugMode) {
          print('_initialize: Erreur lors du chargement du cache des métadonnées: $cacheError');
          print('_initialize: Poursuite de l\'initialisation avec un cache vide');
        }
        // Le cache reste vide mais l'initialisation continue
      }
      
      // Vérifier si un nettoyage automatique est nécessaire
      if (kDebugMode) {
        print('_initialize: Vérification du nettoyage périodique des sauvegardes');
      }
      try {
        await _checkAndRunPeriodicCleanup();
      } catch (cleanupError) {
        if (kDebugMode) {
          print('_initialize: Erreur lors du nettoyage périodique: $cleanupError');
          print('_initialize: Poursuite de l\'initialisation sans nettoyage');
        }
        // L'initialisation continue même si le nettoyage échoue
      }
      
      _logger.info('Gestionnaire de sauvegardes initialisé avec succès');
      if (kDebugMode) {
        print('_initialize: Initialisation terminée avec succès');
      }
    } catch (e, stackTrace) {
      _logger.severe('Erreur lors de l\'initialisation du gestionnaire de sauvegardes: $e');
      if (kDebugMode) {
        print('_initialize: ERREUR CRITIQUE: $e');
        print('_initialize: Stack trace: $stackTrace');
      }
      // Déjà marqué comme initialisé au début de la méthode
    }  
  }
  
  /// Charge le cache des métadonnées depuis SharedPreferences
  /// 
  /// Si [forceReload] est true, le cache sera rechargé même s'il contient déjà des données
  Future<void> _loadMetadataCache({bool forceReload = false}) async {
    // Logger les préfixes pour le diagnostic
    _logPrefixes();
    
    _metadataCache.clear();
    
    try {
      // Limiter les logs pour éviter la saturation mémoire
      final allKeys = _prefs.getKeys();
      if (kDebugMode) {
        print('LocalSaveGameManager._loadMetadataCache: Total des clés trouvées: ${allKeys.length}');
        // Ne pas loguer toutes les clés pour éviter de saturer la mémoire
        // print('LocalSaveGameManager._loadMetadataCache: Clés disponibles: ${allKeys.join(", ")}');
      }
      
      // Filtrer les clés avec le préfixe de métadonnées
      final metadataKeys = allKeys.where((key) => key.startsWith(_metadataPrefix)).toList();
      
      if (kDebugMode) {
        print('LocalSaveGameManager._loadMetadataCache: Clés de métadonnées trouvées: ${metadataKeys.length}');
      }
      
      // Limiter le nombre de clés à traiter si trop nombreuses (protection contre les bugs mémoire)
      final keysToProcess = metadataKeys.length > 50 ? metadataKeys.sublist(0, 50) : metadataKeys;
      
      if (keysToProcess.length < metadataKeys.length) {
        _logger.warning('Trop de sauvegardes, traitement limité à ${keysToProcess.length} sauvegardes sur ${metadataKeys.length}');
        if (kDebugMode) {
          print('⚠️ ATTENTION: Limitation du traitement à ${keysToProcess.length} sauvegardes sur ${metadataKeys.length} pour éviter le crash mémoire');
        }
      }
      
      // Traiter chaque clé de métadonnées
      for (final key in keysToProcess) {
        try {
          final String? jsonData = _prefs.getString(key);
          if (jsonData != null) {
            // Vérifier la taille des données pour éviter de traiter des données trop volumineuses
            if (jsonData.length > 100000) { // Limite arbitraire de 100Ko
              _logger.warning('Données trop volumineuses pour $key (${jsonData.length} bytes) - ignorées');
              continue;
            }
            
            final Map<String, dynamic> data = jsonDecode(jsonData);
            final saveId = key.substring(_metadataPrefix.length);
            final metadata = SaveMetadata.fromJson(data);
            _metadataCache[saveId] = metadata;
            
            // Log seulement pour les 5 premières entrées pour éviter la saturation
            if (kDebugMode && _metadataCache.length <= 5) {
              print('LocalSaveGameManager._loadMetadataCache: Métadonnées ajoutées pour $saveId (nom: ${metadata.name})');
            }
          }
        } catch (e) {
          _logger.warning('Erreur lors du chargement des métadonnées pour $key: $e');
          if (kDebugMode) {
            print('LocalSaveGameManager._loadMetadataCache: ERREUR pour $key: $e');
          }
          // Continuer avec les autres entrées
        }
      }
      
      _logger.info('${_metadataCache.length} entrées de métadonnées chargées dans le cache');
      if (kDebugMode) {
        print('LocalSaveGameManager._loadMetadataCache: ${_metadataCache.length} entrées chargées au total');
        // Limiter l'affichage à maximum 5 entrées pour éviter de saturer le log
        final entriesToShow = _metadataCache.entries.take(5).toList();
        for (var entry in entriesToShow) {
          print('  - Cache: ${entry.key} => "${entry.value.name}" (${entry.value.lastModified})');
        }
        if (_metadataCache.length > 5) {
          print('  - ... et ${_metadataCache.length - 5} autres entrées non affichées');
        }
      }
    } catch (e) {
      // Capture globale pour éviter le crash complet
      _logger.severe('Erreur critique lors du chargement du cache de métadonnées: $e');
      if (kDebugMode) {
        print('⚠️ ERREUR CRITIQUE dans _loadMetadataCache: $e');
      }
      // Ne pas faire rethrow ici pour permettre à l'application de continuer
      // Le cache reste vide mais l'app peut continuer
    }
  }
  
  @override
  String? get activeSaveId => _activeSaveId;
  
  @override
  set activeSaveId(String? id) {
    _activeSaveId = id;
    _logger.info('Sauvegarde active définie: $id');
  }
  
  @override
  Future<List<SaveMetadata>> listSaves() async {
    await _ensureInitialized();
    
    try {
      // Logger les préfixes pour le diagnostic
      _logPrefixes();
      
      if (kDebugMode) {
        print('LocalSaveGameManager.listSaves: Début de la récupération des sauvegardes');
        print('DIAGNOSTIC: SharedPreferences initialisées: ${_prefs != null}');
      }
      
      // Vérifier les clés disponibles dans SharedPreferences
      final allKeys = _prefs.getKeys();
      if (kDebugMode) {
        print('DIAGNOSTIC: Nombre total de clés dans SharedPreferences: ${allKeys.length}');
        if (allKeys.length < 30) { // Afficher les clés seulement si leur nombre est raisonnable
          print('DIAGNOSTIC: Toutes les clés SharedPreferences: ${allKeys.join(", ")}');
        }
        
        // Vérifier spécifiquement les clés de métadonnées
        final metaKeysInPrefs = allKeys.where((k) => k.startsWith(_metadataPrefix)).toList();
        print('DIAGNOSTIC: Clés de métadonnées dans SharedPreferences: ${metaKeysInPrefs.length}');
        if (metaKeysInPrefs.isNotEmpty) {
          print('DIAGNOSTIC: Clés de métadonnées trouvées: ${metaKeysInPrefs.join(", ")}');
        } else {
          print('DIAGNOSTIC: AUCUNE clé de métadonnées trouvée! (préfixe utilisé: "$_metadataPrefix")');
        }
        
        // Vérifier les clés de données de sauvegarde
        final dataKeysInPrefs = allKeys.where((k) => k.startsWith(_saveDataPrefix)).toList();
        print('DIAGNOSTIC: Clés de données de sauvegarde dans SharedPreferences: ${dataKeysInPrefs.length}');
        if (dataKeysInPrefs.isNotEmpty) {
          print('DIAGNOSTIC: Clés de données trouvées: ${dataKeysInPrefs.join(", ")}');
        } else {
          print('DIAGNOSTIC: AUCUNE clé de données trouvée! (préfixe utilisé: "$_saveDataPrefix")');
        }
      }
      
      // Si le cache est vide, le recharger
      if (_metadataCache.isEmpty) {
        if (kDebugMode) {
          print('LocalSaveGameManager.listSaves: Cache vide, rechargement...');
        }
        await _loadMetadataCache();
        if (kDebugMode) {
          print('DIAGNOSTIC: Après rechargement, le cache contient ${_metadataCache.length} entrées');
        }
      } else {
        if (kDebugMode) {
          print('LocalSaveGameManager.listSaves: Cache contient déjà ${_metadataCache.length} entrées');
        }
      }
      
      // Trier par date de modification décroissante (la plus récente en premier)
      final sortedMetadata = _metadataCache.values.toList()
        ..sort((a, b) => b.lastModified.compareTo(a.lastModified));
      
      if (kDebugMode) {
        print('LocalSaveGameManager.listSaves: ${sortedMetadata.length} sauvegardes retournées');
        if (sortedMetadata.isEmpty) {
          print('DIAGNOSTIC: AUCUNE sauvegarde retournée après tri!');
        } else {
          print('DIAGNOSTIC: Première sauvegarde: ID=${sortedMetadata.first.id}, nom=${sortedMetadata.first.name}');
        }
      }
      
      return sortedMetadata;
    } catch (e) {
      _logger.severe('Erreur lors de la récupération de la liste des sauvegardes: $e');
      if (kDebugMode) {
        print('LocalSaveGameManager.listSaves: ERREUR: $e');
        print('DIAGNOSTIC: Stack trace: $e\n${StackTrace.current}');
      }
      return [];
    }
  }
  
  @override
  Future<SaveGame?> loadSave(String saveId) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Chargement de la sauvegarde: $saveId');
      
      final String? jsonData = _prefs.getString('$_saveDataPrefix$saveId');
      if (jsonData == null) {
        _logger.warning('Sauvegarde non trouvée: $saveId');
        return null;
      }
      
      final Map<String, dynamic> data = jsonDecode(jsonData);
      
      // Valider les données avant de créer l'objet SaveGame
      final validationResult = SaveValidator.quickValidate(data);
      if (!validationResult.isValid) {
        _logger.warning('Validation échouée pour la sauvegarde $saveId: ${validationResult.errors.join(', ')}');
        
        // Si les erreurs sont critiques, abandonner le chargement
        if (validationResult.severity == ValidationSeverity.critical) {
          _logger.severe('Erreurs critiques détectées, abandon du chargement');
          return null;
        }
        
        // Sinon, utiliser les données validées/corrigées si disponibles
        if (validationResult.validatedData != null) {
          _logger.info('Utilisation des données corrigées pour la sauvegarde $saveId');
          data.clear();
          data.addAll(validationResult.validatedData!);
        }
      }
      
      // Mettre à jour les métadonnées pour refléter le chargement
      await _updateSaveMetadataLastAccess(saveId);
      
      // Désactiver cette sauvegarde comme active
      _activeSaveId = saveId;
      
      // Extraire les propriétés pour créer l'objet SaveGame
      final String version = data['version'] as String? ?? '2.0';
      final DateTime lastModifiedTime = DateTime.parse(data['timestamp'] as String? ?? data['lastModified'] as String? ?? DateTime.now().toIso8601String());
      
      // Extraire gameMode
      GameMode gameMode = GameMode.INFINITE;
      try {
        if (data.containsKey('gameMode') && data['gameMode'] is int) {
          final int modeIndex = data['gameMode'] as int;
          gameMode = GameMode.values[modeIndex];
        } else if (data.containsKey('gameData') && 
                   data['gameData'] is Map && 
                   (data['gameData'] as Map).containsKey('gameMode') &&
                   data['gameData']['gameMode'] is int) {
          final int modeIndex = data['gameData']['gameMode'] as int;
          gameMode = GameMode.values[modeIndex];
        }
      } catch (e) {
        _logger.warning('Erreur lors de l\'extraction du mode de jeu: $e');
      }
      
      // Extraire gameData
      Map<String, dynamic> gameData;
      if (data.containsKey('gameData') && data['gameData'] is Map) {
        gameData = Map<String, dynamic>.from(data['gameData'] as Map);
      } else {
        // Ancienne structure où les données de jeu sont directement à la racine
        gameData = Map<String, dynamic>.from(data);
        // Exclure les métadonnées qui ne font pas partie des données de jeu
        gameData.remove('id');
        gameData.remove('version');
        gameData.remove('timestamp');
      }
      
      // Récupérer les métadonnées associées
      final SaveMetadata? metadata = await getSaveMetadata(saveId);
      final String name = metadata?.name ?? 'Sauvegarde sans nom';
      
      _logger.info('Sauvegarde $saveId chargée avec succès (version $version)');
      
      return SaveGame(
        id: saveId,
        name: name,
        lastSaveTime: lastModifiedTime,
        gameData: gameData,
        version: version,
        gameMode: gameMode,
      );
    } catch (e) {
      _logger.severe('Erreur lors du chargement de la sauvegarde $saveId: $e');
      return null;
    }
  }

  @override
  Future<bool> saveGame(SaveGame save) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Sauvegarde du jeu: ${save.id} (${save.name})');
      
      // Sanitiser les données pour garantir la compatibilité JSON
      final sanitizedGameData = DataSanitizer.sanitizeData(save.gameData);
      if (sanitizedGameData == null) {
        _logger.severe('Échec de la sanitisation des données de jeu');
        return false;
      }
      
      // Créer la structure complète des données de sauvegarde
      final Map<String, dynamic> saveData = {
        'id': save.id,
        'version': save.version,
        'timestamp': save.lastSaveTime.toIso8601String(),
        'gameMode': save.gameMode.index,
        'gameData': sanitizedGameData,
      };
      
      // Valider les données avant de sauvegarder
      final validationResult = SaveValidator.quickValidate(saveData);
      if (!validationResult.isValid && validationResult.severity == ValidationSeverity.critical) {
        _logger.severe('Validation critique échouée pour la sauvegarde ${save.id}: ${validationResult.errors.join(", ")}');
        return false;
      }
      
      // Convertir en JSON
      final String jsonData = jsonEncode(saveData);
      
      // Sauvegarder les données
      final saveSuccess = await _prefs.setString('$_saveDataPrefix${save.id}', jsonData);
      if (!saveSuccess) {
        _logger.warning('Échec de l\'écriture des données de sauvegarde pour ${save.id}');
        return false;
      }
      
      // Mettre à jour ou créer les métadonnées
      final metadata = SaveMetadata(
        id: save.id,
        name: save.name,
        description: null, // Pourrait être ajouté via une mise à jour ultérieure
        creationDate: await _getOrCreateSaveCreationDate(save.id),
        lastModified: DateTime.now(),
        version: save.version,
        gameMode: save.gameMode,
        displayData: _extractDisplayDataFromGameData(sanitizedGameData as Map<String, dynamic>),
      );
      
      // Sauvegarder les métadonnées
      final metadataSuccess = await updateSaveMetadata(save.id, metadata);
      if (!metadataSuccess) {
        _logger.warning('Échec de la mise à jour des métadonnées pour ${save.id}');
        // On continue malgré tout car les données principales ont été sauvegardées
      }
      
      // Désactiver cette sauvegarde comme active si ce n'est pas déjà le cas
      _activeSaveId ??= save.id;
      
      _logger.info('Sauvegarde ${save.id} enregistrée avec succès');
      return true;
    } catch (e) {
      _logger.severe('Erreur lors de la sauvegarde du jeu ${save.id}: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteSave(String saveId) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Suppression de la sauvegarde: $saveId');
      
      // Supprimer les données
      final dataSuccess = await _prefs.remove('$_saveDataPrefix$saveId');
      
      // Supprimer les métadonnées
      final metadataSuccess = await _prefs.remove('$_metadataPrefix$saveId');
      
      // Supprimer du cache
      _metadataCache.remove(saveId);
      
      // Si c'était la sauvegarde active, la désactiver
      if (_activeSaveId == saveId) {
        _activeSaveId = null;
      }
      
      _logger.info('Sauvegarde $saveId supprimée avec succès (données: $dataSuccess, métadonnées: $metadataSuccess)');
      return dataSuccess && metadataSuccess;
    } catch (e) {
      _logger.severe('Erreur lors de la suppression de la sauvegarde $saveId: $e');
      return false;
    }
  }

  @override
  Future<bool> exportSave(String saveId, String path) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Export de la sauvegarde: $saveId');
      
      // Charger la sauvegarde
      final save = await loadSave(saveId);
      if (save == null) {
        _logger.warning('Sauvegarde non trouvée pour export: $saveId');
        return false;
      }
      
      // Charger les métadonnées
      final metadata = await getSaveMetadata(saveId);
      if (metadata == null) {
        _logger.warning('Métadonnées non trouvées pour export: $saveId');
        // Continuer sans métadonnées
      }
      
      // Préparer la structure d'export
      final Map<String, dynamic> exportData = {
        'id': save.id,
        'name': save.name,
        'version': save.version,
        'gameMode': save.gameMode.index,
        'timestamp': save.lastSaveTime.toIso8601String(),
        'exportDate': DateTime.now().toIso8601String(),
        'gameData': save.gameData,
        'metadata': metadata?.toJson(),
      };
      
      // Enregistrer dans le fichier spécifié
      final file = File(path);
      await file.writeAsString(jsonEncode(exportData));
      _logger.info('Sauvegarde exportée vers fichier: $path');
      
      return true;
    } catch (e) {
      _logger.severe('Erreur lors de l\'export de la sauvegarde $saveId: $e');
      return false;
    }
  }

  @override
  Future<SaveGame?> importSave(dynamic sourceData, {String? newName, bool overwriteIfExists = false}) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Import d\'une sauvegarde');
      
      // Traiter les différents formats de données source
      Map<String, dynamic> importData;
      
      if (sourceData is String) {
        // C'est une chaîne JSON ou un chemin de fichier
        if (sourceData.startsWith('{') || sourceData.startsWith('[')) {
          // C'est probablement une chaîne JSON
          importData = jsonDecode(sourceData);
        } else {
          // C'est probablement un chemin de fichier
          final file = File(sourceData);
          if (!await file.exists()) {
            _logger.warning('Fichier d\'import non trouvé: $sourceData');
            return null;
          }
          final content = await file.readAsString();
          importData = jsonDecode(content);
        }
      } else if (sourceData is Map<String, dynamic>) {
        // C'est déjà un objet Map
        importData = sourceData;
      } else {
        _logger.warning('Format de données source non reconnu pour l\'import');
        return null;
      }
      
      // Valider les données importées
      final validationResult = await SaveValidator.validate(importData);
      if (!validationResult.isValid && validationResult.severity == ValidationSeverity.critical) {
        _logger.severe('Validation critique échouée pour l\'import: ${validationResult.errors.join(", ")}');
        return null;
      }
      
      // Extraire l'ID et vérifier s'il existe déjà
      String saveId = importData['id'] as String? ?? const Uuid().v4();
      
      final exists = await saveExists(saveId);
      if (exists && !overwriteIfExists) {
        // Générer un nouvel ID si une sauvegarde avec cet ID existe déjà
        saveId = const Uuid().v4();
      }
      
      // Extraire ou créer les propriétés nécessaires
      final String saveName = newName ?? importData['name'] as String? ?? 'Sauvegarde importée';
      final String version = importData['version'] as String? ?? '2.0';
      final DateTime timestamp = DateTime.parse(
        importData['timestamp'] as String? ?? DateTime.now().toIso8601String()
      );
      
      // Extraire le mode de jeu
      GameMode gameMode = GameMode.INFINITE;
      try {
        if (importData.containsKey('gameMode') && importData['gameMode'] is int) {
          final int modeIndex = importData['gameMode'] as int;
          gameMode = GameMode.values[modeIndex];
        } else if (importData.containsKey('gameData') && 
                  importData['gameData'] is Map && 
                  (importData['gameData'] as Map).containsKey('gameMode') &&
                  importData['gameData']['gameMode'] is int) {
          final int modeIndex = importData['gameData']['gameMode'] as int;
          gameMode = GameMode.values[modeIndex];
        }
      } catch (e) {
        _logger.warning('Erreur lors de l\'extraction du mode de jeu: $e');
      }
      
      // Extraire les données de jeu
      Map<String, dynamic> gameData;
      if (importData.containsKey('gameData') && importData['gameData'] is Map) {
        gameData = Map<String, dynamic>.from(importData['gameData'] as Map);
      } else {
        // Ancienne structure où les données de jeu sont directement à la racine
        gameData = Map<String, dynamic>.from(importData);
        // Exclure les métadonnées qui ne font pas partie des données de jeu
        gameData.remove('id');
        gameData.remove('name');
        gameData.remove('version');
        gameData.remove('timestamp');
        gameData.remove('exportDate');
        gameData.remove('metadata');
      }
      
      // Créer l'objet SaveGame
      final SaveGame importedSave = SaveGame(
        id: saveId,
        name: saveName,
        lastSaveTime: timestamp,
        gameData: gameData,
        version: version,
        gameMode: gameMode,
      );
      
      // Sauvegarder la sauvegarde importée
      final saveSuccess = await saveGame(importedSave);
      if (!saveSuccess) {
        _logger.severe('Échec de la sauvegarde de l\'import');
        return null;
      }
      
      // Créer les métadonnées si elles existent dans les données importées
      SaveMetadata? metadata;
      if (importData.containsKey('metadata') && importData['metadata'] != null) {
        try {
          final metadataMap = Map<String, dynamic>.from(importData['metadata'] as Map);
          metadataMap['id'] = saveId; // S'assurer que l'ID est correct
          metadataMap['name'] = saveName; // S'assurer que le nom est correct
          metadata = SaveMetadata.fromJson(metadataMap);
        } catch (e) {
          _logger.warning('Erreur lors de l\'extraction des métadonnées: $e');
          // Continuer sans métadonnées
        }
      }
      
      // Si aucune métadonnée n'a été importée, en créer une nouvelle
      metadata ??= SaveMetadata.createNew(
        id: saveId,
        name: saveName,
        gameMode: gameMode,
      );
      
      // Sauvegarder les métadonnées
      await updateSaveMetadata(saveId, metadata);
      
      _logger.info('Sauvegarde importée avec succès: $saveId');
      return importedSave;
    } catch (e) {
      _logger.severe('Erreur lors de l\'import d\'une sauvegarde: $e');
      return null;
    }
  }

  @override
  Future<SaveGame> createNewSave({
    String? name,
    GameMode gameMode = GameMode.INFINITE,
    Map<String, dynamic>? initialData,
  }) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Création d\'une nouvelle sauvegarde');
      
      // Générer un ID unique
      final String id = const Uuid().v4();
      
      // Créer un nom par défaut si non spécifié
      final String saveName = name ?? 'Nouvelle partie ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
      
      // Créer des données de jeu initiales ou utiliser celles fournies
      final Map<String, dynamic> gameData = initialData ?? _createDefaultGameData(gameMode);
      
      // Créer l'objet SaveGame
      final SaveGame newSave = SaveGame(
        id: id,
        name: saveName,
        lastSaveTime: DateTime.now(),
        gameData: gameData,
        version: '2.0', // Version actuelle
        gameMode: gameMode,
      );
      
      // Sauvegarder les données
      final saveSuccess = await saveGame(newSave);
      if (!saveSuccess) {
        throw Exception('Échec de la sauvegarde des données initiales');
      }
      
      // Créer et sauvegarder les métadonnées
      final metadata = SaveMetadata.createNew(
        id: id,
        name: saveName,
        gameMode: gameMode,
      );
      
      await updateSaveMetadata(id, metadata);
      
      // Désactiver comme sauvegarde active
      _activeSaveId = id;
      
      _logger.info('Nouvelle sauvegarde créée avec succès: $id ($saveName)');
      return newSave;
    } catch (e) {
      _logger.severe('Erreur lors de la création d\'une nouvelle sauvegarde: $e');
      throw Exception('Impossible de créer une nouvelle sauvegarde: $e');
    }
  }

  @override
  Future<bool> updateSaveMetadata(String saveId, SaveMetadata metadata) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Mise à jour des métadonnées pour $saveId');
      if (kDebugMode) {
        print('LocalSaveGameManager.updateSaveMetadata: Mise à jour des métadonnées pour "$saveId" (nom: "${metadata.name}")');
      }
      
      // Vérifier que l'ID correspond bien
      if (metadata.id != saveId) {
        _logger.warning('ID de métadonnées incohérent: ${metadata.id} vs $saveId');
        if (kDebugMode) {
          print('LocalSaveGameManager.updateSaveMetadata: ERREUR - ID incohérent: ${metadata.id} vs $saveId');
        }
        return false;
      }
      
      // Convertir en JSON
      final Map<String, dynamic> jsonData = metadata.toJson();
      
      // Clé pour SharedPreferences
      final metadataKey = '$_metadataPrefix$saveId';
      if (kDebugMode) {
        print('LocalSaveGameManager.updateSaveMetadata: Sauvegarde avec clé "$metadataKey"');
      }
      
      // Sauvegarder les métadonnées
      final success = await _prefs.setString(metadataKey, jsonEncode(jsonData));
      
      // Mettre à jour le cache
      if (success) {
        _metadataCache[saveId] = metadata;
        if (kDebugMode) {
          print('LocalSaveGameManager.updateSaveMetadata: Métadonnées sauvegardées avec succès et cache mis à jour');
        }
      } else {
        if (kDebugMode) {
          print('LocalSaveGameManager.updateSaveMetadata: ÉCHEC de la sauvegarde des métadonnées');
        }
      }
      
      return success;
    } catch (e) {
      _logger.severe('Erreur lors de la mise à jour des métadonnées pour $saveId: $e');
      if (kDebugMode) {
        print('LocalSaveGameManager.updateSaveMetadata: ERREUR: $e');
      }
      return false;
    }
  }

  @override
  Future<SaveMetadata?> getSaveMetadata(String saveId) async {
    await _ensureInitialized();
    
    try {
      // Vérifier d'abord dans le cache
      if (_metadataCache.containsKey(saveId)) {
        return _metadataCache[saveId];
      }
      
      // Sinon, charger depuis les préférences
      final String? jsonData = _prefs.getString('$_metadataPrefix$saveId');
      if (jsonData == null) {
        return null;
      }
      
      final Map<String, dynamic> data = jsonDecode(jsonData);
      final metadata = SaveMetadata.fromJson(data);
      
      // Mettre à jour le cache
      _metadataCache[saveId] = metadata;
      
      return metadata;
    } catch (e) {
      _logger.warning('Erreur lors de la récupération des métadonnées pour $saveId: $e');
      return null;
    }
  }

  @override
  Future<void> enableAutoSave({
    required Duration interval,
    required String saveId,
  }) async {
    await _ensureInitialized();

    await disableAutoSave();

    _logger.warning(
      "LocalSaveGameManager.enableAutoSave() est désactivé (Option A). "
      "L'auto-save périodique est exclusivement géré par AutoSaveService. "
      "Appel ignoré pour saveId=\"$saveId\", interval=${interval.inSeconds}s.",
    );

    _activeSaveId = saveId;
  }

  @override
  Future<void> disableAutoSave() async {
    if (_autoSaveTimer != null) {
      _logger.info('Désactivation de l\'auto-sauvegarde');
      _autoSaveTimer!.cancel();
      _autoSaveTimer = null;
    }
  }

  /// Crée une instance vide de SharedPreferences pour la récupération en cas d'erreur
  Future<SharedPreferences> _createEmptyPreferences() async {
    if (kDebugMode) {
      print('LocalSaveGameManager._createEmptyPreferences: Création d\'une implémentation vide');
    }
    return NoopSharedPreferences();
  }
  
  /// Test de persistance pour vérifier que SharedPreferences fonctionne correctement
  Future<void> _testPersistence() async {
    const testKey = 'save_system_persistence_test';
    final testValue = 'test_value_${DateTime.now()}';
    
    try {
      // Écriture de la valeur de test
      await _prefs.setString(testKey, testValue);
      
      // Lecture immédiate pour vérifier
      final result = _prefs.getString(testKey);
      
      if (kDebugMode) {
        print('LocalSaveGameManager._testPersistence: Test d\'écriture/lecture - écrit "$testValue", lu "${result ?? 'NULL'}"');
        print('LocalSaveGameManager._testPersistence: Type de SharedPreferences: ${_prefs.runtimeType}');
      }
      
      // Vérifier si la valeur correspond
      if (result != testValue) {
        _logger.warning('Test de persistance ÉCHOUÉ: valeur récupérée différente de la valeur écrite');
        if (kDebugMode) {
          print('⚠️ ATTENTION: Test de persistance ÉCHOUÉ - valeur différente!');
          print('⚠️ Ceci indique que les sauvegardes ne seront probablement pas persistantes!');
        }
      } else {
        if (kDebugMode) {
          print('LocalSaveGameManager._testPersistence: Test de persistance réussi ✓');
        }
      }
      
      // Nettoyage de la clé de test
      await _prefs.remove(testKey);
    } catch (e) {
      _logger.severe('Erreur lors du test de persistance: $e');
      if (kDebugMode) {
        print('⚠️ ERREUR lors du test de persistance: $e');
        print('⚠️ Ceci suggère des problèmes avec SharedPreferences!');
      }
    }
  }

  /// Obtient le chemin complet vers le fichier de sauvegarde pour l'ID spécifié
  /// 
  /// Cette méthode est utilisée pour accéder aux fichiers de sauvegarde sur le disque,
  /// en complément du stockage dans SharedPreferences
  Future<String> _getSaveFilePath(String saveId) async {
    final directory = await getApplicationDocumentsDirectory();
    // Assurons-nous que le dossier 'saves' existe
    final saveDir = Directory('${directory.path}/saves');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }
    return '${directory.path}/saves/$saveId.save';
  }

  @override
  Future<bool> saveExists(String saveId) async {
    await _ensureInitialized();
    final saveFile = await _getSaveFilePath(saveId);
    final file = File(saveFile);
    return file.exists();
  }

  // Cette méthode a été consolidée avec l'implémentation plus haut dans le fichier pour éviter la duplication

  @override
  Future<SaveGame?> duplicateSave(String sourceId, {String? newName}) async {
    await _ensureInitialized();
    
    try {
      _logger.info('Duplication de la sauvegarde $sourceId');
      
      // Charger la sauvegarde source
      final source = await loadSave(sourceId);
      if (source == null) {
        _logger.warning('Sauvegarde source non trouvée: $sourceId');
        return null;
      }
      
      // Générer un nouvel ID
      final String newId = const Uuid().v4();
      
      // Créer un nom pour la copie
      final String duplicateName = newName ?? '${source.name} (Copie)';
      
      // Créer une nouvelle sauvegarde avec les mêmes données
      final SaveGame duplicate = SaveGame(
        id: newId,
        name: duplicateName,
        lastSaveTime: DateTime.now(), // Horodatage actuel pour la copie
        gameData: Map<String, dynamic>.from(source.gameData), // Copie profonde
        version: source.version,
        gameMode: source.gameMode,
      );
      
      // Sauvegarder la copie
      final saveSuccess = await saveGame(duplicate);
      if (!saveSuccess) {
        _logger.warning('Échec de la sauvegarde de la copie');
        return null;
      }
      
      _logger.info('Sauvegarde dupliquée avec succès: $sourceId -> $newId');
      return duplicate;
    } catch (e) {
      _logger.severe('Erreur lors de la duplication de la sauvegarde $sourceId: $e');
      return null;
    }
  }

  /// S'assure que le gestionnaire est initialisé avant d'effectuer des opérations
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  /// Effectue une auto-sauvegarde pour la sauvegarde active
  Future<void> _performAutoSave() async {
    if (_activeSaveId == null) {
      _logger.warning('Auto-sauvegarde annulée: aucune sauvegarde active');
      return;
    }
    
    try {
      _logger.fine('Exécution de l\'auto-sauvegarde pour ${_activeSaveId}');
      
      // Charger la sauvegarde active
      final save = await loadSave(_activeSaveId!);
      if (save == null) {
        _logger.warning('Auto-sauvegarde impossible: sauvegarde active ${_activeSaveId} non trouvée');
        return;
      }
      
      // Mettre à jour l'horodatage
      final updatedSave = SaveGame(
        id: save.id,
        name: save.name,
        lastSaveTime: DateTime.now(),
        gameData: save.gameData,
        version: save.version,
        gameMode: save.gameMode,
      );
      
      // Sauvegarder
      final success = await saveGame(updatedSave);
      if (success) {
        _logger.fine('Auto-sauvegarde réussie pour ${_activeSaveId}');
      } else {
        _logger.warning('Échec de l\'auto-sauvegarde pour ${_activeSaveId}');
      }
    } catch (e) {
      _logger.warning('Erreur lors de l\'auto-sauvegarde: $e');
    }
  }

  /// Met à jour la date de dernier accès pour les métadonnées d'une sauvegarde
  Future<bool> _updateSaveMetadataLastAccess(String saveId) async {
    try {
      final metadata = await getSaveMetadata(saveId);
      if (metadata == null) {
        return false;
      }
      
      final updatedMetadata = metadata.copyWith(lastModified: DateTime.now());
      return await updateSaveMetadata(saveId, updatedMetadata);
    } catch (e) {
      _logger.warning('Erreur lors de la mise à jour de la date d\'accès pour $saveId: $e');
      return false;
    }
  }

  /// Récupère ou crée une date de création pour une sauvegarde
  Future<DateTime> _getOrCreateSaveCreationDate(String saveId) async {
    // Essayer de récupérer les métadonnées existantes
    final metadata = await getSaveMetadata(saveId);
    if (metadata != null) {
      return metadata.creationDate;
    }
    
    // Sinon, utiliser la date courante
    return DateTime.now();
  }

  /// Extrait les données d'affichage à partir des données de jeu
  Map<String, dynamic> _extractDisplayDataFromGameData(Map<String, dynamic> gameData) {
    final Map<String, dynamic> displayData = {};
    final normalizedGameData = GameDataCompat.normalizeLegacyGameData(gameData);
    
    // Extraire des statistiques pertinentes pour l'affichage dans l'interface
    try {
      if (normalizedGameData.containsKey('playerManager') &&
          normalizedGameData['playerManager'] is Map) {
        final playerManager = normalizedGameData['playerManager'] as Map<String, dynamic>;
        
        // Paperclips
        if (playerManager.containsKey('paperclips')) {
          displayData['paperclips'] = playerManager['paperclips'];
        }
        
        // Money
        if (playerManager.containsKey('money')) {
          displayData['money'] = playerManager['money'];
        }
        
        // AutoClippers
        if (playerManager.containsKey('autoClipperCount')) {
          displayData['autoClippers'] = playerManager['autoClipperCount'];
        }
      }
      
      // Niveau
      if (normalizedGameData.containsKey('levelSystem') &&
          normalizedGameData['levelSystem'] is Map) {
        final levelSystem = normalizedGameData['levelSystem'] as Map<String, dynamic>;
        
        if (levelSystem.containsKey('level')) {
          displayData['level'] = levelSystem['level'];
        }
      }
    } catch (e) {
      _logger.warning('Erreur lors de l\'extraction des données d\'affichage: $e');
    }
    
    return displayData;
  }

  /// Crée des données de jeu par défaut pour une nouvelle partie
  Map<String, dynamic> _createDefaultGameData(GameMode gameMode) {
    return {
      'playerManager': {
        'money': 0.0,
        'metal': 100.0,
        'paperclips': 0.0,
        'autoClipperCount': 0,
        'megaClipperCount': 0,
        'sellPrice': 0.25,
        'upgrades': {},
      },
      'marketManager': {
        'marketMetalStock': 1000.0,
        'reputation': 1.0,
        'dynamics': {},
      },
      'levelSystem': {
        'experience': 0.0,
        'level': 1,
        'currentPath': 0,
        'xpMultiplier': 1.0,
      },
      'gameMode': gameMode.index,
    };
  }
  
  /// Compresse des données à l'aide de GZip
  String compressData(String data) {
    final List<int> encoded = utf8.encode(data);
    final List<int> compressed = gzip.encode(encoded);
    return base64Encode(compressed);
  }
  
  /// Décompresse des données précédemment compressées avec GZip
  String decompressData(String compressed) {
    final List<int> decoded = base64Decode(compressed);
    final List<int> decompressed = gzip.decode(decoded);
    return utf8.decode(decompressed);
  }
  
  /// Validation rapide d'une sauvegarde (vérification de l'intégrité)
  Future<bool> quickValidate(String saveId) async {
    try {
      final metadata = await getSaveMetadata(saveId);
      if (metadata == null) {
        return false;
      }
      
      final saveKey = _saveDataPrefix + saveId;
      final saveExists = _prefs.containsKey(saveKey);
      return saveExists;
    } catch (e) {
      _logger.warning('Erreur lors de la validation rapide de la sauvegarde $saveId: $e');
      return false;
    }
  }
  
  /// Vérifie si un nettoyage périodique est nécessaire et l'exécute si c'est le cas
  Future<void> _checkAndRunPeriodicCleanup() async {
    try {
      // Récupérer la date du dernier nettoyage
      final lastCleanupStr = _prefs.getString(_lastCleanupKey);
      
      bool shouldCleanup = false;
      if (lastCleanupStr == null) {
        // Premier démarrage, on fait le nettoyage
        shouldCleanup = true;
        if (kDebugMode) {
          print('LocalSaveGameManager: Premier démarrage détecté, nettoyage initial des sauvegardes');
        }
      } else {
        try {
          final lastCleanupDate = DateTime.parse(lastCleanupStr);
          final daysSinceLastCleanup = DateTime.now().difference(lastCleanupDate).inDays;
          
          // Si le dernier nettoyage remonte à plus de _cleanupInterval jours
          if (daysSinceLastCleanup >= _cleanupInterval) {
            shouldCleanup = true;
            if (kDebugMode) {
              print('LocalSaveGameManager: Dernier nettoyage il y a $daysSinceLastCleanup jours, nettoyage nécessaire');
            }
          } else {
            if (kDebugMode) {
              print('LocalSaveGameManager: Dernier nettoyage il y a $daysSinceLastCleanup jours, nettoyage non nécessaire');
            }
          }
        } catch (e) {
          // Erreur de parsing, on fait le nettoyage par sécurité
          shouldCleanup = true;
          _logger.warning('Erreur de parsing de la date du dernier nettoyage: $e');
        }
      }
      
      if (shouldCleanup) {
        // Exécuter le nettoyage
        final result = await cleanupOrphanedSaves();
        
        // Mettre à jour la date du dernier nettoyage
        await _prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
        
        _logger.info('Nettoyage automatique des sauvegardes terminé: ${result.toString()}');
      }
    } catch (e) {
      // Ne jamais faire échouer l'initialisation à cause du nettoyage
      _logger.warning('Erreur lors de la vérification/exécution du nettoyage périodique: $e');
      if (kDebugMode) {
        print('LocalSaveGameManager: ⚠️ Erreur lors du nettoyage périodique: $e');
      }
    }
  }

  /// Nettoie les sauvegardes orphelines (métadonnées sans données et vice-versa)
  /// 
  /// Cette méthode vérifie la cohérence entre les métadonnées et les fichiers de sauvegarde,
  /// et supprime les métadonnées sans fichier correspondant et les fichiers sans métadonnées.
  /// 
  /// Retourne un rapport sur le nettoyage effectué.
  Future<Map<String, dynamic>> cleanupOrphanedSaves() async {
    await _ensureInitialized();
    
    final report = <String, dynamic>{
      'orphanedMetadata': 0,
      'orphanedSaveData': 0,
      'totalMetadata': 0,
      'totalSaveData': 0,
      'errors': 0,
      'details': <String>[],
    };
    
    try {
      _logger.info('Début du nettoyage des sauvegardes orphelines');
      if (kDebugMode) {
        print('LocalSaveGameManager.cleanupOrphanedSaves: Début du nettoyage des sauvegardes orphelines');
      }
      
      // Charger toutes les clés de SharedPreferences
      final allKeys = _prefs.getKeys();
      
      // Identifier toutes les clés de métadonnées et de données
      final metadataKeys = allKeys.where((key) => key.startsWith(_metadataPrefix)).toList();
      final saveDataKeys = allKeys.where((key) => key.startsWith(_saveDataPrefix)).toList();
      
      report['totalMetadata'] = metadataKeys.length;
      report['totalSaveData'] = saveDataKeys.length;
      
      if (kDebugMode) {
        print('LocalSaveGameManager.cleanupOrphanedSaves: ${metadataKeys.length} métadonnées et ${saveDataKeys.length} fichiers de sauvegarde trouvés');
      }
      
      // Identifier les métadonnées orphelines (sans données correspondantes)
      for (final metadataKey in metadataKeys) {
        final saveId = metadataKey.substring(_metadataPrefix.length);
        final saveDataKey = _saveDataPrefix + saveId;
        
        if (!saveDataKeys.contains(saveDataKey)) {
          // Métadonnée orpheline détectée, supprimer
          try {
            await _prefs.remove(metadataKey);
            _metadataCache.remove(saveId); // Mise à jour du cache
            report['orphanedMetadata'] = (report['orphanedMetadata'] as int) + 1;
            report['details']!.add('Suppression de la métadonnée orpheline: $saveId');
            
            if (kDebugMode) {
              print('LocalSaveGameManager.cleanupOrphanedSaves: Suppression de la métadonnée orpheline pour $saveId');
            }
          } catch (e) {
            _logger.warning('Erreur lors de la suppression de la métadonnée orpheline $saveId: $e');
            report['errors'] = report['errors']! + 1;
            report['details']!.add('Erreur lors de la suppression de la métadonnée orpheline: $saveId - $e');
          }
        }
      }
      
      // Identifier les données orphelines (sans métadonnées correspondantes)
      for (final saveDataKey in saveDataKeys) {
        final saveId = saveDataKey.substring(_saveDataPrefix.length);
        final metadataKey = _metadataPrefix + saveId;
        
        if (!metadataKeys.contains(metadataKey)) {
          // Donnée orpheline détectée, supprimer
          try {
            await _prefs.remove(saveDataKey);
            report['orphanedSaveData'] = report['orphanedSaveData']! + 1;
            report['details']!.add('Suppression des données orphelines: $saveId');
            
            if (kDebugMode) {
              print('LocalSaveGameManager.cleanupOrphanedSaves: Suppression des données orphelines pour $saveId');
            }
          } catch (e) {
            _logger.warning('Erreur lors de la suppression des données orphelines $saveId: $e');
            report['errors'] = report['errors']! + 1;
            report['details']!.add('Erreur lors de la suppression des données orphelines: $saveId - $e');
          }
        }
      }
      
      // Recharger le cache des métadonnées après le nettoyage si nécessaire
      if (report['orphanedMetadata']! > 0) {
        await _loadMetadataCache(forceReload: true);
      }
      
      _logger.info('Nettoyage des sauvegardes orphelines terminé: ${report.toString()}');
      if (kDebugMode) {
        print('LocalSaveGameManager.cleanupOrphanedSaves: Nettoyage terminé:');
        print(' - ${report['orphanedMetadata']} métadonnées orphelines supprimées');
        print(' - ${report['orphanedSaveData']} fichiers de sauvegarde orphelins supprimés');
        print(' - ${report['errors']} erreurs rencontrées');
      }
      
      return report;
    } catch (e) {
      _logger.severe('Erreur lors du nettoyage des sauvegardes orphelines: $e');
      if (kDebugMode) {
        print('LocalSaveGameManager.cleanupOrphanedSaves: ERREUR: $e');
      }
      report['errors'] = report['errors']! + 1;
      report['details']!.add('Erreur globale: $e');
      return report;
    }
  }
  
  /// Force l'exécution immédiate du nettoyage des sauvegardes orphelines
  /// Cette méthode peut être appelée manuellement, par exemple depuis un écran de paramètres
  Future<Map<String, dynamic>> forceCleanupOrphanedSaves() async {
    final result = await cleanupOrphanedSaves();
    await _prefs.setString(_lastCleanupKey, DateTime.now().toIso8601String());
    return result;
  }
  
  /// Force le rechargement du cache des métadonnées
  /// Cette méthode est utilisée par SaveManagerAdapter pour s'assurer d'avoir les données les plus récentes
  Future<void> reloadMetadataCache() async {
    await _loadMetadataCache(forceReload: true);
  }
  
  // Cette méthode a été déplacée plus haut dans le fichier pour éviter la duplication
}
