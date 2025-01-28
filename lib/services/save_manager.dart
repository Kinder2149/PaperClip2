// lib/services/save_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';
import '../models/game_config.dart';
import '../models/event_system.dart';


class SaveValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final Map<String, dynamic>? validatedData;

  SaveValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.validatedData,
  });
}
class SaveError implements Exception {
  final String code;
  final String message;
  final dynamic originalError;

  SaveError(this.code, this.message, {this.originalError});

  @override
  String toString() {
    if (originalError != null) {
      return '$code: $message (Cause: $originalError)';
    }
    return '$code: $message';
  }
}
class SaveGame {
  final String name;
  final DateTime lastSaveTime;
  final Map<String, dynamic> gameData;
  final String version;

  SaveGame({
    required this.name,
    required this.lastSaveTime,
    required this.gameData,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp': lastSaveTime.toIso8601String(),
      'version': version,
      'gameData': gameData,
      ...gameData, // Ajoute aussi les données à la racine pour rétrocompatibilité
    };
  }

  factory SaveGame.fromJson(Map<String, dynamic> json) {
    try {
      Map<String, dynamic> gameData = json['gameData'] as Map<String, dynamic>? ?? {};

      // Rétrocompatibilité : fusion des données racine si présentes
      for (final key in ['playerManager', 'marketManager', 'levelSystem']) {
        if (json.containsKey(key)) {
          gameData[key] = json[key];
        }
      }

      return SaveGame(
        name: json['name'] as String,
        lastSaveTime: DateTime.parse(json['timestamp'] as String),
        gameData: gameData,
        version: json['version'] as String? ?? GameConstants.VERSION,
      );
    } catch (e) {
      print('Error creating SaveGame from JSON: $e');
      throw SaveError('PARSE_ERROR', 'Erreur lors du chargement de la sauvegarde: $e');
    }
  }
}


class SaveDataValidator {
  static const Map<String, Map<String, dynamic>> _validationRules = {
    'playerManager': {
      'money': {'type': 'double', 'min': 0.0},
      'metal': {'type': 'double', 'min': 0.0},
      'paperclips': {'type': 'double', 'min': 0.0},
      'autoclippers': {'type': 'int', 'min': 0},
      'sellPrice': {'type': 'double', 'min': 0.01, 'max': 1.0},
      'maxMetalStorage': {'type': 'double', 'min': 0.0},
      'maintenanceCosts': {'type': 'double', 'min': 0.0},
      'lastMaintenanceTime': {'type': 'datetime'},
      'upgrades': {'type': 'map'},
    },
    'marketManager': {
      'marketMetalStock': {'type': 'double', 'min': 0.0},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0},
      'lastPriceUpdate': {'type': 'datetime'},
      'marketSaturation': {'type': 'double', 'min': 0.0, 'max': 100.0},
      'dynamics': {'type': 'map'},
    },
    'levelSystem': {
      'experience': {'type': 'double', 'min': 0.0},
      'level': {'type': 'int', 'min': 1},
      'currentPath': {'type': 'int', 'min': 0},
      'unlockedFeatures': {'type': 'list'},
      'xpMultiplier': {'type': 'double', 'min': 1.0},
    },
  };
  static void _validateVersion(String savedVersion, List<String> warnings) {
    if (savedVersion != GameConstants.VERSION) {
      warnings.add(
          'Version différente détectée: $savedVersion (actuelle: ${GameConstants
              .VERSION})');
    }
  }

  static SaveValidationResult validate(Map<String, dynamic> data) {
    List<String> errors = [];
    List<String> warnings = [];

    // Vérification de base
    if (!data.containsKey('version') || !data.containsKey('timestamp')) {
      errors.add('Données de base manquantes (version ou timestamp)');
      return SaveValidationResult(isValid: false, errors: errors);
    }

    // Vérification des sections obligatoires
    if (!_validateMandatorySections(data, errors)) {
      return SaveValidationResult(isValid: false, errors: errors);
    }

    // Vérification des règles pour chaque section
    for (var sectionName in _validationRules.keys) {
      if (!data.containsKey(sectionName)) {
        errors.add('Section manquante: $sectionName');
        continue;
      }

      var sectionData = data[sectionName] as Map<String, dynamic>?;
      if (sectionData == null) {
        errors.add('Section invalide: $sectionName');
        continue;
      }

      // Vérifier chaque champ de la section
      var rules = _validationRules[sectionName]!;
      for (var fieldName in rules.keys) {
        if (!sectionData.containsKey(fieldName)) {
          errors.add('Champ manquant dans $sectionName: $fieldName');
          continue;
        }

        var value = sectionData[fieldName];
        var rule = rules[fieldName];

        if (!_validateField(value, rule as Map<String, dynamic>, errors, '$sectionName.$fieldName')) {
          continue;
        }
      }
    }

    // Vérification de la cohérence des données si pas d'erreurs
    if (errors.isEmpty) {
      _validateDataConsistency(data, warnings);
    }

    return SaveValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      validatedData: errors.isEmpty ? data : null,
    );
  }
  static void _validateDataConsistency(Map<String, dynamic> data, List<String> warnings) {
    final playerData = data['playerManager'] as Map<String, dynamic>;
    final marketData = data['marketManager'] as Map<String, dynamic>;

    // Vérifier les limites de stockage
    if (playerData['metal'] > GameConstants.INITIAL_STORAGE_CAPACITY) {
      warnings.add('Le stock de métal dépasse la capacité maximale initiale');
    }

    // Vérifier la cohérence des prix
    if (playerData['sellPrice'] < GameConstants.MIN_PRICE ||
        playerData['sellPrice'] > GameConstants.MAX_PRICE) {
      warnings.add('Prix de vente hors limites normales');
    }
  }



  static bool _validateMandatorySections(Map<String, dynamic> data, List<String> errors) {
    if (!data.containsKey('playerManager')) {
      errors.add('Section manquante: playerManager');
      return false;
    }

    final playerData = data['playerManager'] as Map<String, dynamic>?;
    if (playerData == null) {
      errors.add('Données du joueur invalides');
      return false;
    }

    final requiredFields = ['paperclips', 'money', 'metal'];
    for (var field in requiredFields) {
      if (!playerData.containsKey(field)) {
        errors.add('Champ manquant dans playerManager: $field');
        return false;
      }
    }

    return true;
  }

  static bool _validateField(dynamic value, Map<String, dynamic> rule, List<String> errors, String fieldPath) {
    // Vérification du type
    if (rule['type'] == 'datetime') {
      if (value == null) {
        value = DateTime.now().toIso8601String();
        return true;
      }
    }

    if (!_validateType(value, rule['type'] as String)) {
      errors.add('Type invalide pour $fieldPath');
      return false;
    }

    // Vérification des limites pour les nombres
    if (value is num) {
      if (rule.containsKey('min') && value < rule['min']) {
        errors.add('Valeur trop petite pour $fieldPath');
        return false;
      }
      if (rule.containsKey('max') && value > rule['max']) {
        errors.add('Valeur trop grande pour $fieldPath');
        return false;
      }
    }

    return true;
  }

  static bool _validateType(dynamic value, String expectedType) {
    switch (expectedType) {
      case 'double':
        return value is num;
      case 'int':
        return value is int;
      case 'map':
        return value is Map;
      case 'list':
        return value is List;
      case 'datetime':
        if (value is String) {
          try {
            DateTime.parse(value);
            return true;
          } catch (_) {
            return false;
          }
        }
        return false;
      default:
        return false;
    }
  }
}









class SaveManager {
  static const String SAVE_PREFIX = 'paperclip_save_';
  static const String BACKUP_PREFIX = 'paperclip_backup_';
  static const String DEFAULT_VERSION = "1.0.0";
  static const int MAX_BACKUPS = 3;
  static final DateTime CURRENT_DATE = DateTime(2025, 1, 23, 15, 15, 49);
  static const String CURRENT_USER = 'Kinder2149';
  static const String CURRENT_VERSION = '1.0.0';


  // Obtenir la clé de sauvegarde unique pour une partie
  static String _getSaveKey(String gameName) {
    // Nettoyage du nom pour éviter les problèmes de formatage
    final cleanName = gameName.trim().replaceAll(RegExp(r'[^\w\s-]'), '');
    final key = '$SAVE_PREFIX$cleanName';
    print('Génération clé de sauvegarde pour "$gameName": $key');
    return key;
  }
  static String _getBackupKey(String gameName, int index) => '${BACKUP_PREFIX}${gameName}_$index';



  // Sauvegarder une partie
  static Future<void> saveGame(GameState gameState, String name) async {
    try {
      if (name.isEmpty) {
        throw SaveError('INVALID_NAME', 'Le nom de la sauvegarde ne peut pas être vide');
      }

      // Créer une sauvegarde de backup si ce n'est pas une nouvelle partie
      if (await saveExists(name)) {
        await _createBackup(name);
      }

      final gameData = gameState.prepareGameData();
      // Utiliser SaveDataValidator au lieu de _validateSaveData
      final validationResult = SaveDataValidator.validate(gameData);

      if (!validationResult.isValid) {
        throw SaveError(
            'VALIDATION_ERROR',
            'Données invalides:\n${validationResult.errors.join('\n')}'
        );
      }

      if (validationResult.warnings.isNotEmpty) {
        EventManager.instance.addEvent(
            EventType.INFO,
            'Avertissements de sauvegarde',
            description: validationResult.warnings.join('\n'),
            importance: EventImportance.MEDIUM
        );
      }

      final saveData = SaveGame(
        name: name,
        lastSaveTime: DateTime.now(),
        gameData: validationResult.validatedData!,
        version: GameConstants.VERSION,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_getSaveKey(name), jsonEncode(saveData.toJson()));

    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      rethrow;
    }
  }

  static Future<SaveGameInfo?> getLastSave() async {
    final saves = await listSaves();
    return saves.isNotEmpty ? saves.first : null;
  }

  static Future<bool> saveExists(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_getSaveKey(name));
  }


  static Future<Map<String, dynamic>?> debugSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(name);
      final savedData = prefs.getString(saveKey);

      print('=== Debug Save Data ===');
      print('Save Key: $saveKey');

      if (savedData == null) {
        print('Aucune sauvegarde trouvée pour: $name');
        return null;
      }

      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;
      print('Version: ${jsonData['version']}');
      print('Timestamp: ${jsonData['timestamp']}');
      print('Contains playerManager: ${jsonData.containsKey('playerManager')}');
      print('Contains gameData: ${jsonData.containsKey('gameData')}');

      if (jsonData.containsKey('playerManager')) {
        print('PlayerManager data structure:');
        final playerData = jsonData['playerManager'] as Map<String, dynamic>;
        playerData.forEach((key, value) {
          print('  $key: $value');
        });
      }

      print('=====================');
      return jsonData;
    } catch (e) {
      print('Error debugging save: $e');
      print(e.toString());
      return null;
    }
  }
  static Future<void> debugListAllSaves() async {
    final prefs = await SharedPreferences.getInstance();
    print('\n=== DEBUG: Toutes les sauvegardes ===');
    for (String key in prefs.getKeys()) {
      if (key.startsWith(SAVE_PREFIX) || key.startsWith(BACKUP_PREFIX)) {
        print('Clé: $key');
        try {
          final data = jsonDecode(prefs.getString(key) ?? '{}');
          print('- Version: ${data['version']}');
          print('- Timestamp: ${data['timestamp']}');
          print('- Nom: ${data['name']}');
        } catch (e) {
          print('- Erreur de lecture: $e');
        }
      }
    }
    print('===================================\n');
  }
  static Future<SaveGame?> loadGame(String name) async {
    try {
      await debugListAllSaves();
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(name);

      print('Tentative de chargement de la sauvegarde: $saveKey');
      final savedData = prefs.getString(saveKey);

      if (savedData == null) {
        print('Sauvegarde non trouvée, recherche de backup...');
        return await _tryLoadBackup(name);
      }

      print('Sauvegarde trouvée, décodage des données...');
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(savedData);
      } catch (e) {
        print('Erreur de décodage JSON, tentative de restauration backup...');
        return await _tryLoadBackup(name);
      }

      // Vérifie si les données sont dans l'ancien format
      if (!jsonData.containsKey('gameData')) {
        print('Ancien format détecté, migration des données...');
        jsonData = {
          'name': name,
          'version': jsonData['version'] ?? DEFAULT_VERSION,
          'timestamp': jsonData['timestamp'] ?? DateTime.now().toIso8601String(),
          'gameData': {
            'playerManager': jsonData['playerManager'] ?? {},
            'marketManager': jsonData['marketManager'] ?? {},
            'levelSystem': jsonData['levelSystem'] ?? {},
          }
        };
      }

      // Migration si nécessaire
      if (SaveVersion.needsMigration(jsonData['version'] as String?)) {
        print('Migration nécessaire vers ${SaveVersion.CURRENT}...');
        jsonData = SaveMigration.migrateData(jsonData);

        // Sauvegarde des données migrées
        await prefs.setString(saveKey, jsonEncode(jsonData));
        print('Migration terminée et sauvegardée');
      }

      return SaveGame.fromJson(jsonData);
    } catch (e) {
      print('Erreur détaillée lors du chargement: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  static Future<void> cleanupCorruptedSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveKey = _getSaveKey(name);

      if (await _hasBackup(name)) {
        // Restaurer depuis le backup
        final backup = await _getLatestBackup(name);
        if (backup != null) {
          await prefs.setString(saveKey, jsonEncode(backup.toJson()));
          print('Sauvegarde restaurée depuis backup');
        }
      } else {
        // Supprimer la sauvegarde corrompue
        await deleteSave(name);
        print('Sauvegarde corrompue supprimée');
      }
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }
  static Future<bool> doesSaveExist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSaveKey(name);
    final exists = prefs.containsKey(key);
    print('Vérification existence sauvegarde "$name" (clé: $key): ${exists ? "existe" : "n'existe pas"}');
    return exists;
  }


  static Future<SaveGame?> _tryLoadBackup(String name) async {
    final backup = await _getLatestBackup(name);
    if (backup != null) {
      EventManager.instance.addEvent(
          EventType.INFO,
          'Restauration depuis backup',
          description: 'La sauvegarde principale était corrompue',
          importance: EventImportance.HIGH
      );
    }
    return backup;
  }
  static Future<SaveMigrationStatus> checkSaveStatus(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString(_getSaveKey(name));
      if (savedData == null) {
        return SaveMigrationStatus(exists: false);
      }

      final jsonData = jsonDecode(savedData) as Map<String, dynamic>;
      final needsMigration = SaveVersion.needsMigration(jsonData['version'] as String?);

      return SaveMigrationStatus(
        exists: true,
        currentVersion: jsonData['version'] as String?,
        needsMigration: needsMigration,
        hasBackup: await _hasBackup(name),
      );
    } catch (e) {
      return SaveMigrationStatus(exists: false, error: e.toString());
    }
  }
  static Future<bool> _hasBackup(String name) async {
    final prefs = await SharedPreferences.getInstance();
    for (var i = 0; i < MAX_BACKUPS; i++) {
      if (prefs.containsKey(_getBackupKey(name, i))) {
        return true;
      }
    }
    return false;
  }
  static Future<void> _createBackup(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentSave = prefs.getString(_getSaveKey(name));
      if (currentSave != null) {
        final backupIndex = DateTime.now().millisecondsSinceEpoch % MAX_BACKUPS;
        await prefs.setString(_getBackupKey(name, backupIndex), currentSave);
      }
    } catch (e) {
      print('Erreur lors de la création du backup: $e');
    }
  }
  static Future<SaveGame?> _getLatestBackup(String name) async {
    final prefs = await SharedPreferences.getInstance();
    SaveGame? latestBackup;
    DateTime? latestTime;

    for (var i = 0; i < MAX_BACKUPS; i++) {
      final backupData = prefs.getString(_getBackupKey(name, i));
      if (backupData != null) {
        try {
          final backup = SaveGame.fromJson(jsonDecode(backupData));
          if (latestTime == null || backup.lastSaveTime.isAfter(latestTime)) {
            latestTime = backup.lastSaveTime;
            latestBackup = backup;
          }
        } catch (e) {
          print('Backup invalide: $e');
        }
      }
    }
    return latestBackup;
  }
  // Validation d'une section spécifique
  static void _validateSection(
      String section,
      Map<String, dynamic> data,
      List<String> errors,
      List<String> warnings,
      ) {
    switch (section) {
      case 'playerManager':
        _validatePlayerManager(data, errors, warnings);
        break;
      case 'marketManager':
        _validateMarketManager(data, errors, warnings);
        break;
      case 'levelSystem':
        _validateLevelSystem(data, errors, warnings);
        break;
    }
  }

  // Validation des données du joueur
  static void _validatePlayerManager(
      Map<String, dynamic> data,
      List<String> errors,
      List<String> warnings,
      ) {
    final requiredFields = {
      'money': 0.0,
      'metal': 0.0,
      'paperclips': 0.0,
      'autoclippers': 0,
      'sellPrice': GameConstants.MIN_PRICE,
    };

    requiredFields.forEach((field, defaultValue) {
      if (!data.containsKey(field)) {
        warnings.add('Champ manquant dans playerManager: $field (utilisation valeur par défaut)');
        data[field] = defaultValue;
      }
    });
  }

  // Validation des données du marché
  static void _validateMarketManager(
      Map<String, dynamic> data,
      List<String> errors,
      List<String> warnings,
      ) {
    if (!data.containsKey('marketMetalStock')) {
      errors.add('Stock de métal du marché manquant');
    }
  }

  // Validation du système de niveau
  static void _validateLevelSystem(
      Map<String, dynamic> data,
      List<String> errors,
      List<String> warnings,
      ) {
    if (!data.containsKey('level') || !data.containsKey('experience')) {
      errors.add('Données de progression manquantes');
    }
  }

  // Validation de la cohérence des données
  static void _validateDataConsistency(Map<String, dynamic> data, List<String> warnings) {
    final playerData = data['playerManager'] as Map<String, dynamic>;
    final marketData = data['marketManager'] as Map<String, dynamic>;
    final levelData = data['levelSystem'] as Map<String, dynamic>;

    // Vérification des limites de stockage
    if (playerData['metal'] > playerData['maxMetalStorage']) {
      warnings.add('Le stock de métal dépasse la capacité maximale');
    }

    // Vérification de la cohérence des coûts de maintenance
    if (playerData['autoclippers'] > 0 && playerData['maintenanceCosts'] <= 0) {
      warnings.add('Coûts de maintenance invalides pour le nombre d\'autoclippers');
    }

    // Vérification de la cohérence du marché
    if (marketData['marketMetalStock'] < 0) {
      warnings.add('Stock de métal du marché négatif');
    }

    // Vérification de la progression
    if (levelData['level'] > 1 && levelData['unlockedFeatures'].isEmpty) {
      warnings.add('Niveau supérieur à 1 sans fonctionnalités débloquées');
    }
  }






  // Récupérer la dernière sauvegarde

  static Future<List<SaveGameInfo>> listSaves() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saves = <SaveGameInfo>[];

      for (final key in prefs.getKeys()) {
        if (key.startsWith(SAVE_PREFIX)) {
          try {
            final data = jsonDecode(prefs.getString(key) ?? '{}');
            saves.add(SaveGameInfo(
              name: key.substring(SAVE_PREFIX.length),
              timestamp: DateTime.parse(data['timestamp'] ?? ''),
              version: data['version'] ?? '',
              paperclips: data['gameData']?['playerManager']?['paperclips'] ?? 0,
              money: data['gameData']?['playerManager']?['money'] ?? 0,
            ));
          } catch (e) {
            print('Erreur lors du chargement de la sauvegarde $key: $e');
          }
        }
      }

      saves.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return saves;
    } catch (e) {
      print('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }



  // Supprimer une sauvegarde
  static Future<void> deleteSave(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Supprimer la sauvegarde principale
      await prefs.remove(_getSaveKey(name));
      // Supprimer les backups
      for (var i = 0; i < MAX_BACKUPS; i++) {
        await prefs.remove(_getBackupKey(name, i));
      }
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      rethrow;
    }
  }
}

class SaveVersion {
  static const String INITIAL = "1.0.0";
  static const String CURRENT = GameConstants.VERSION;

  static bool needsMigration(String? version) {
    if (version == null || version.isEmpty) return true;
    if (version == CURRENT) return false;

    try {
      final currentParts = CURRENT.split('.').map(int.parse).toList();
      final versionParts = version.split('.').map(int.parse).toList();

      // Compare les numéros de version
      for (var i = 0; i < 3; i++) {
        if (currentParts[i] > versionParts[i]) return true;
        if (currentParts[i] < versionParts[i]) return false;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la comparaison des versions: $e');
      return true;
    }
  }
}


class SaveMigration {
  static const _defaultValues = {
    'playerManager': {
      'maxMetalStorage': GameConstants.INITIAL_STORAGE_CAPACITY,
      'maintenanceCosts': 0.0,
      'lastMaintenanceTime': null, // Sera généré au moment de la migration
      'upgrades': {
        'efficiency': {'id': 'efficiency', 'level': 0},
        'marketing': {'id': 'marketing', 'level': 0},
        'bulk': {'id': 'bulk', 'level': 0},
        'speed': {'id': 'speed', 'level': 0},
        'storage': {'id': 'storage', 'level': 0},
        'automation': {'id': 'automation', 'level': 0},
        'quality': {'id': 'quality', 'level': 0},
      },
    },
    'marketManager': {
      'marketSaturation': GameConstants.DEFAULT_MARKET_SATURATION,
      'lastPriceUpdate': null, // Sera généré au moment de la migration
      'marketMetalStock': GameConstants.INITIAL_MARKET_METAL,
      'reputation': 1.0,
    },
    'levelSystem': {
      'unlockedFeatures': ['MANUAL_PRODUCTION'],
      'xpMultiplier': 1.0,
      'experience': 0.0,
      'level': 1,
      'currentPath': 0,
    },
  };

  static Map<String, dynamic> migrateData(Map<String, dynamic> oldData) {
    final now = DateTime.now().toIso8601String();
    var newData = Map<String, dynamic>.from(oldData);

    // Migrer chaque section
    _migrateSection(newData, 'playerManager', now);
    _migrateSection(newData, 'marketManager', now);
    _migrateSection(newData, 'levelSystem', now);

    // Mettre à jour la version et le timestamp
    newData['version'] = SaveVersion.CURRENT;
    newData['timestamp'] = now;

    return newData;
  }

  static void _migrateSection(Map<String, dynamic> data, String section, String timestamp) {
    var sectionData = data[section] as Map<String, dynamic>? ?? {};
    var defaultSection = _defaultValues[section] as Map<String, dynamic>;

    // Copier les valeurs par défaut manquantes
    defaultSection.forEach((key, defaultValue) {
      if (!sectionData.containsKey(key)) {
        var value = defaultValue;
        // Gérer les timestamps
        if (value == null && (key == 'lastMaintenanceTime' || key == 'lastPriceUpdate')) {
          value = timestamp;
        }
        // Gérer les structures imbriquées
        else if (value is Map) {
          value = Map<String, dynamic>.from(value);
        }
        sectionData[key] = value;
      }
    });

    // S'assurer que les upgrades ont tous les champs nécessaires
    if (section == 'playerManager' && sectionData.containsKey('upgrades')) {
      var upgrades = sectionData['upgrades'] as Map<String, dynamic>;
      var defaultUpgrades = defaultSection['upgrades'] as Map<String, dynamic>;
      defaultUpgrades.forEach((key, defaultValue) {
        if (!upgrades.containsKey(key)) {
          upgrades[key] = defaultValue;
        }
      });
    }

    data[section] = sectionData;
  }
}
class SaveMigrationStatus {
  final bool exists;
  final String? currentVersion;
  final bool needsMigration;
  final bool hasBackup;
  final String? error;

  SaveMigrationStatus({
    required this.exists,
    this.currentVersion,
    this.needsMigration = false,
    this.hasBackup = false,
    this.error,
  });
}

class SaveGameInfo {
  final String name;
  final DateTime timestamp;
  final String version;
  final double paperclips;
  final double money;

  SaveGameInfo({
    required this.name,
    required this.timestamp,
    required this.version,
    required this.paperclips,
    required this.money,
  });
}