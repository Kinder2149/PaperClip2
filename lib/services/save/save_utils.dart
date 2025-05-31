// lib/services/save/save_utils.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../models/game_config.dart';
import '../../main.dart' show serviceLocator;
import 'validation_result.dart';

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<String, dynamic>? validatedData;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.validatedData,
  });
}

class SaveUtils {
  // Validation des données de sauvegarde
  static ValidationResult validateSaveData(Map<String, dynamic> data) {
    final errors = <String>[];

    // Vérification de base
    if (!data.containsKey('version') || !data.containsKey('timestamp')) {
      errors.add('Données de base manquantes (version ou timestamp)');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Vérification des sections obligatoires
    if (!_validateMandatorySections(data, errors)) {
      return ValidationResult(isValid: false, errors: errors);
    }

    // Si tout est valide
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      validatedData: data,
    );
  }

  // Validation rapide (pour performances)
  static Future<bool> quickValidate(Map<String, dynamic> data) async {
    try {
      // Vérifier les champs minimaux
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        return false;
      }

      if (!data.containsKey('playerManager')) {
        return false;
      }

      // Vérifier les données essentielles
      bool paperclipsFound = false;
      bool moneyFound = false;
      bool metalFound = false;

      final playerData = data['playerManager'] as Map<String, dynamic>?;

      // Vérifier paperclips
      if (playerData?.containsKey('paperclips') == true) {
        paperclipsFound = true;
      } else if (data.containsKey('productionManager')) {
        final productionData = data['productionManager'] as Map<String, dynamic>?;
        if (productionData?.containsKey('paperclips') == true) {
          paperclipsFound = true;
        }
      }

      // Vérifier money
      moneyFound = playerData?.containsKey('money') == true;

      // Vérifier metal
      if (playerData?.containsKey('metal') == true) {
        metalFound = true;
      } else if (data.containsKey('metalManager')) {
        final metalData = data['metalManager'] as Map<String, dynamic>?;
        if (metalData?.containsKey('metal') == true) {
          metalFound = true;
        }
      }

      return paperclipsFound && moneyFound && metalFound;
    } catch (e) {
      debugPrint('Erreur validation rapide: $e');
      return false;
    }
  }

  // Migration des données entre versions
  static Map<String, dynamic> migrateIfNeeded(Map<String, dynamic> data) {
    try {
      // Déterminer la version actuelle
      final version = data['version'] as String? ?? '1.0.0';

      // Si version identique, pas besoin de migration
      if (version == GameConstants.VERSION) {
        return data;
      }

      // Appliquer les migrations séquentielles
      final migratedData = _migrateFromVersion(data, version);

      // Mettre à jour la version
      migratedData['version'] = GameConstants.VERSION;

      return migratedData;
    } catch (e) {
      debugPrint('Erreur pendant la migration: $e');
      return data;  // Retourner les données originales en cas d'erreur
    }
  }

  // Récupération de sauvegardes corrompues
  static Future<Map<String, dynamic>?> attemptRecovery(String rawData, String saveName) async {
    try {
      // Tentative de décodage standard
      final data = jsonDecode(rawData) as Map<String, dynamic>;

      // Appliquer migrations
      final migratedData = migrateIfNeeded(data);

      // Réparer les données manquantes
      final repairedData = _repairSaveData(migratedData);

      debugPrint('Sauvegarde récupérée: $saveName');
      return repairedData;
    } catch (e, stack) {
      debugPrint('Échec de la récupération pour $saveName: $e');
      serviceLocator.analyticsService?.recordError(e, stack, reason: 'Save recovery failed');

      // Tentative de récupération partielle
      return _attemptPartialRecovery(rawData, saveName);
    }
  }

  // Méthodes privées

  static Map<String, dynamic> _migrateFromVersion(Map<String, dynamic> data, String version) {
    // Appliquer les migrations dans l'ordre
    if (_isOlderVersion(version, '1.0.1')) {
      data = _migrateV1_0_0_to_V1_0_1(data);
    }

    if (_isOlderVersion(version, '1.0.2')) {
      data = _migrateV1_0_1_to_V1_0_2(data);
    }

    if (_isOlderVersion(version, '1.0.3')) {
      data = _migrateV1_0_2_to_V1_0_3(data);
    }

    return data;
  }

  static bool _isOlderVersion(String currentVersion, String targetVersion) {
    final currentParts = currentVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    final targetParts = targetVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    // Assurer une longueur minimale
    while (currentParts.length < 3) currentParts.add(0);
    while (targetParts.length < 3) targetParts.add(0);

    // Comparer les parties
    for (var i = 0; i < currentParts.length && i < targetParts.length; i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }

    return currentParts.length < targetParts.length;
  }

  static Map<String, dynamic> _migrateV1_0_0_to_V1_0_1(Map<String, dynamic> data) {
    data['totalTimePlayedInSeconds'] = data['totalTimePlayedInSeconds'] ?? 0;
    data['achievementsUnlocked'] = data['achievementsUnlocked'] ?? [];
    return data;
  }

  static Map<String, dynamic> _migrateV1_0_1_to_V1_0_2(Map<String, dynamic> data) {
    // Conversion des données statistiques en double
    if (data['statistics'] != null) {
      var stats = data['statistics'] as Map<String, dynamic>;
      stats['totalMetalUsed'] = _toDouble(stats['totalMetalUsed']) ?? 0.0;
      stats['totalMetalSaved'] = _toDouble(stats['totalMetalSaved']) ?? 0.0;
      stats['currentEfficiency'] = _toDouble(stats['currentEfficiency']) ?? 0.0;
    }

    return data;
  }

  static Map<String, dynamic> _migrateV1_0_2_to_V1_0_3(Map<String, dynamic> data) {
    // Créer ProductionManager si absent mais PlayerManager contient paperclips
    if (!data.containsKey('productionManager') && data.containsKey('playerManager')) {
      final playerData = data['playerManager'] as Map<String, dynamic>;

      if (playerData.containsKey('paperclips')) {
        // Conversion sécurisée des types
        double paperclips = _toDouble(playerData['paperclips']) ?? 0.0;
        int autoclippers = _toInt(playerData['autoclippers']) ?? 0;
        int totalProduced = _toInt(data['totalPaperclipsProduced']) ??
            _toInt(playerData['paperclips']) ?? 0;

        // Créer productionManager avec les données de paperclips
        data['productionManager'] = {
          'paperclips': paperclips,
          'autoclippers': autoclippers,
          'totalPaperclipsProduced': totalProduced,
        };
      }
    } else if (data.containsKey('productionManager')) {
      // S'assurer que les types sont corrects dans productionManager existant
      final prodData = data['productionManager'] as Map<String, dynamic>;
      if (prodData.containsKey('paperclips')) {
        prodData['paperclips'] = _toDouble(prodData['paperclips']);
      }
      if (prodData.containsKey('autoclippers')) {
        prodData['autoclippers'] = _toInt(prodData['autoclippers']);
      }
      if (prodData.containsKey('totalPaperclipsProduced')) {
        prodData['totalPaperclipsProduced'] = _toInt(prodData['totalPaperclipsProduced']);
      }
    }

    return data;
  }

  static bool _validateMandatorySections(Map<String, dynamic> data, List<String> errors) {
    try {
      // Vérifier que playerManager existe
      if (!data.containsKey('playerManager')) {
        errors.add('Section manquante: playerManager');
        return false;
      }

      final playerData = _getTypeSafeSectionData(data, 'playerManager');
      if (playerData == null) {
        errors.add('Données du joueur invalides ou de type incorrect');
        return false;
      }

      // Vérifier que les sections importantes existent et sont de bon type
      final mandatorySections = {
        'marketManager': 'Gestionnaire de marché',
        'levelSystem': 'Système de niveau',
        'statistics': 'Statistiques',
      };

      for (var entry in mandatorySections.entries) {
        if (!data.containsKey(entry.key)) {
          // Section manquante mais non-bloquante
          debugPrint('Avertissement: Section ${entry.value} (${entry.key}) manquante');
        } else {
          final sectionData = _getTypeSafeSectionData(data, entry.key);
          if (sectionData == null) {
            debugPrint('Avertissement: Section ${entry.value} (${entry.key}) de type incorrect');
          }
        }
      }

      // Vérifier la présence de paperclips
      bool paperclipsFound = false;
      if (playerData.containsKey('paperclips')) {
        paperclipsFound = true;
      } else if (data.containsKey('productionManager')) {
        final productionData = _getTypeSafeSectionData(data, 'productionManager');
        if (productionData != null && productionData.containsKey('paperclips')) {
          paperclipsFound = true;
        }
      }

      if (!paperclipsFound) {
        errors.add('Champ paperclips introuvable dans playerManager ou productionManager');
        return false;
      }

      // Vérifier les autres champs essentiels
      final requiredFields = ['money', 'metal'];
      for (var field in requiredFields) {
        if (!playerData.containsKey(field)) {
          // Vérifier dans d'autres managers
          if (field == 'metal' && data.containsKey('metalManager')) {
            final metalData = _getTypeSafeSectionData(data, 'metalManager');
            if (metalData != null && metalData.containsKey('metal')) {
              continue;
            }
          }
          errors.add('Champ manquant dans playerManager: $field');
          return false;
        }
      }

      return true;
    } catch (e) {
      errors.add('Erreur lors de la validation: $e');
      return false;
    }
  }

  // Méthode sécurisée pour obtenir une section en tant que Map<String, dynamic>
  static Map<String, dynamic>? _getTypeSafeSectionData(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key)) return null;

    final value = data[key];
    if (value is Map<String, dynamic>) {
      return value;
    } else if (value is Map<dynamic, dynamic>) {
      // Conversion sécurisée de Map<dynamic, dynamic> à Map<String, dynamic>
      return value.map((k, v) => MapEntry(k.toString(), v));
    }

    return null;
  }

  static Map<String, dynamic>? _attemptPartialRecovery(String rawData, String saveName) {
    try {
      // Tenter de nettoyer le JSON
      final cleanedJson = _cleanJsonString(rawData);

      Map<String, dynamic> data;
      try {
        data = jsonDecode(cleanedJson) as Map<String, dynamic>;
      } catch (e) {
        // Si le casting direct échoue, tentative de conversion
        final dynamicData = jsonDecode(cleanedJson);
        if (dynamicData is Map) {
          // Conversion de Map<dynamic, dynamic> à Map<String, dynamic>
          data = {};
          dynamicData.forEach((key, value) {
            data[key.toString()] = value;
          });
        } else {
          throw FormatException('Les données décodées ne sont pas un objet Map');
        }
      }

      // Construire une structure minimale
      return _buildMinimalSaveData(data, saveName);
    } catch (e) {
      debugPrint('Échec de la récupération partielle: $e');
      return null;
    }
  }

  static String _cleanJsonString(String rawJson) {
    // Remplacer les valeurs NaN, Infinity, -Infinity
    String cleaned = rawJson
        .replaceAll('NaN', '0')
        .replaceAll('Infinity', '999999')
        .replaceAll('-Infinity', '-999999');

    // Supprimer les caractères non-UTF8
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');

    // Correction des accolades/crochets mal fermés
    int openBraces = 0, openBrackets = 0;
    for (int i = 0; i < cleaned.length; i++) {
      if (cleaned[i] == '{') openBraces++;
      else if (cleaned[i] == '}') openBraces--;
      else if (cleaned[i] == '[') openBrackets++;
      else if (cleaned[i] == ']') openBrackets--;
    }

    // Ajouter les accolades/crochets manquants
    while (openBraces > 0) {
      cleaned += '}';
      openBraces--;
    }
    while (openBrackets > 0) {
      cleaned += ']';
      openBrackets--;
    }

    return cleaned;
  }

  static Map<String, dynamic> _buildMinimalSaveData(Map<String, dynamic> partialData, String saveName) {
    // Créer un squelette minimal fonctionnel
    final minimalData = {
      'version': GameConstants.VERSION,
      'timestamp': DateTime.now().toIso8601String(),
      'playerManager': {
        'money': 0.0,
        'metal': GameConstants.INITIAL_METAL,
        'sellPrice': GameConstants.INITIAL_PRICE,
        'upgrades': {},
      },
      'productionManager': {
        'paperclips': 0.0,
        'autoclippers': 0,
        'totalPaperclipsProduced': 0,
      },
      'marketManager': {
        'marketMetalStock': GameConstants.INITIAL_MARKET_METAL,
        'reputation': 1.0,
        'currentMetalPrice': GameConstants.MIN_METAL_PRICE,
        'competitionPrice': GameConstants.INITIAL_PRICE,
        'marketSaturation': 100.0,
        'dynamics': {
          'marketVolatility': 1.0,
          'marketTrend': 0.0,
          'competitorPressure': 1.0,
        },
        'salesHistory': [],
      },
      'levelSystem': {
        'experience': 0.0,
        'level': 1,
        'currentPath': 0,
        'xpMultiplier': 1.0,
      },
      'metalManager': {
        'metal': GameConstants.INITIAL_METAL,
        'maxMetalStorage': GameConstants.INITIAL_STORAGE_CAPACITY,
      },
      'statistics': {
        'totalMetalUsed': 0.0,
        'totalMoneyEarned': 0.0,
        'totalSales': 0,
      },
      'gameMode': 0, // INFINITE par défaut
    };

    // Copier les données récupérables si disponibles
    _copyIfValid(partialData, minimalData, 'version');
    _copyIfValid(partialData, minimalData, 'timestamp');
    _copyIfValid(partialData, minimalData, 'gameMode');

    // Tenter de copier des structures plus complexes
    if (partialData.containsKey('playerManager')) {
      final playerDataSource = _getTypeSafeSectionData(partialData, 'playerManager');
      if (playerDataSource != null) {
        _copyValidDataRecursively(
            playerDataSource,
            minimalData['playerManager'] as Map<String, dynamic>
        );
      }
    }

    if (partialData.containsKey('productionManager')) {
      final prodDataSource = _getTypeSafeSectionData(partialData, 'productionManager');
      if (prodDataSource != null) {
        _copyValidDataRecursively(
            prodDataSource,
            minimalData['productionManager'] as Map<String, dynamic>
        );
      }
    }

    // Si productionManager est absent mais playerManager contient paperclips
    if (!partialData.containsKey('productionManager') &&
        partialData.containsKey('playerManager')) {
      final playerData = _getTypeSafeSectionData(partialData, 'playerManager');
      if (playerData != null && playerData.containsKey('paperclips')) {
        final prodData = minimalData['productionManager'] as Map<String, dynamic>;
        prodData['paperclips'] = _toDouble(playerData['paperclips']) ?? 0.0;

        if (playerData.containsKey('autoclippers')) {
          prodData['autoclippers'] = _toInt(playerData['autoclippers']) ?? 0;
        }
      }
    }

    return minimalData;
  }

  static void _copyIfValid(Map<String, dynamic> source, Map<String, dynamic> target, String key) {
    if (source.containsKey(key) && source[key] != null) {
      target[key] = source[key];
    }
  }

  static void _copyValidDataRecursively(
      Map<String, dynamic> source, Map<String, dynamic> target) {
    for (final key in target.keys) {
      if (source.containsKey(key) && source[key] != null) {
        if (source[key] is Map && target[key] is Map) {
          // Conversion sécurisée pour les sous-maps
          Map<String, dynamic> sourceSubMap;
          if (source[key] is Map<String, dynamic>) {
            sourceSubMap = source[key] as Map<String, dynamic>;
          } else if (source[key] is Map<dynamic, dynamic>) {
            final dynamicMap = source[key] as Map<dynamic, dynamic>;
            sourceSubMap = dynamicMap.map((k, v) => MapEntry(k.toString(), v));
          } else {
            continue; // Type incompatible, ignorer
          }

          _copyValidDataRecursively(
              sourceSubMap,
              target[key] as Map<String, dynamic>
          );
        } else {
          // Copier la valeur avec conversion de type si nécessaire
          if (target[key] is double) {
            target[key] = _toDouble(source[key]) ?? target[key];
          } else if (target[key] is int) {
            target[key] = _toInt(source[key]) ?? target[key];
          } else if (target[key] is bool) {
            target[key] = source[key] is bool ? source[key] : target[key];
          } else if (target[key] is String) {
            target[key] = source[key].toString();
          } else {
            // Pour les autres types, copier directement
            target[key] = source[key];
          }
        }
      }
    }
  }

  static Map<String, dynamic> _repairSaveData(Map<String, dynamic> data) {
    // S'assurer que toutes les sections principales existent
    if (!data.containsKey('playerManager')) {
      data['playerManager'] = {
        'money': 0.0,
        'metal': GameConstants.INITIAL_METAL,
        'sellPrice': GameConstants.INITIAL_PRICE,
        'upgrades': {},
      };
    }

    if (!data.containsKey('productionManager')) {
      // Tenter de récupérer paperclips depuis playerManager
      double paperclips = 0.0;
      int autoclippers = 0;
      if (data.containsKey('playerManager')) {
        final playerData = _getTypeSafeSectionData(data, 'playerManager');
        if (playerData != null) {
          if (playerData.containsKey('paperclips')) {
            paperclips = _toDouble(playerData['paperclips']) ?? 0.0;
          }
          if (playerData.containsKey('autoclippers')) {
            autoclippers = _toInt(playerData['autoclippers']) ?? 0;
          }
        }
      }

      data['productionManager'] = {
        'paperclips': paperclips,
        'autoclippers': autoclippers,
        'totalPaperclipsProduced': paperclips,
      };
    }

    if (!data.containsKey('marketManager')) {
      data['marketManager'] = {
        'marketMetalStock': GameConstants.INITIAL_MARKET_METAL,
        'reputation': 1.0,
        'currentMetalPrice': GameConstants.MIN_METAL_PRICE,
        'competitionPrice': GameConstants.INITIAL_PRICE,
        'marketSaturation': 100.0,
        'dynamics': {
          'marketVolatility': 1.0,
          'marketTrend': 0.0,
          'competitorPressure': 1.0,
        },
        'salesHistory': [],
      };
    }

    if (!data.containsKey('levelSystem')) {
      data['levelSystem'] = {
        'experience': 0.0,
        'level': 1,
        'currentPath': 0,
        'xpMultiplier': 1.0,
      };
    }

    if (!data.containsKey('metalManager')) {
      data['metalManager'] = {
        'metal': GameConstants.INITIAL_METAL,
        'maxMetalStorage': GameConstants.INITIAL_STORAGE_CAPACITY,
      };
    }

    if (!data.containsKey('statistics')) {
      data['statistics'] = {
        'totalMetalUsed': 0.0,
        'totalMoneyEarned': 0.0,
        'totalSales': 0,
        'playTime': 0,
      };
    }

    // S'assurer que les clés nécessaires sont présentes dans playerManager
    final playerData = _getTypeSafeSectionData(data, 'playerManager');
    if (playerData != null) {
      if (!playerData.containsKey('money')) playerData['money'] = 0.0;
      if (!playerData.containsKey('metal')) playerData['metal'] = GameConstants.INITIAL_METAL;
      if (!playerData.containsKey('sellPrice')) playerData['sellPrice'] = GameConstants.INITIAL_PRICE;
      if (!playerData.containsKey('upgrades')) playerData['upgrades'] = {};
    }

    return data;
  }

  // Utilitaires de conversion
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}