import 'dart:convert';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../../models/game_config.dart';
import 'save_migration_service.dart';

class SaveRecoveryService {
  /// Tente de récupérer une sauvegarde corrompue
  static Future<Map<String, dynamic>?> attemptRecovery(String rawData, String saveName) async {
    try {
      // Tentative de décodage standard
      final data = jsonDecode(rawData) as Map<String, dynamic>;

      // Appliquer migrations
      final migratedData = SaveMigrationService.migrateIfNeeded(data);

      // Réparer les données manquantes
      final repairedData = _repairSaveData(migratedData);

      print('Sauvegarde récupérée: $saveName');
      return repairedData;
    } catch (e, stack) {
      print('Échec de la récupération pour $saveName: $e');
      FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Save recovery failed');

      // Tentative de récupération partielle
      return _attemptPartialRecovery(rawData, saveName);
    }
  }

  /// Tente de récupérer partiellement une sauvegarde sévèrement corrompue
  static Map<String, dynamic>? _attemptPartialRecovery(String rawData, String saveName) {
    try {
      // Tenter de nettoyer le JSON
      final cleanedJson = _cleanJsonString(rawData);
      final data = jsonDecode(cleanedJson) as Map<String, dynamic>;

      // Construire une structure minimale
      return _buildMinimalSaveData(data, saveName);
    } catch (e) {
      print('Échec de la récupération partielle: $e');
      return null;
    }
  }

  /// Nettoie une chaîne JSON potentiellement corrompue
  static String _cleanJsonString(String rawJson) {
    // Remplacer les valeurs NaN, Infinity, -Infinity
    String cleaned = rawJson
        .replaceAll('NaN', '0')
        .replaceAll('Infinity', '999999')
        .replaceAll('-Infinity', '-999999');

    // Supprimer les caractères non-UTF8
    cleaned = cleaned.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');

    return cleaned;
  }

  /// Construit une structure minimale fonctionnelle
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
    };

    // Copier les données récupérables si disponibles
    _copyIfValid(partialData, minimalData, 'version');
    _copyIfValid(partialData, minimalData, 'timestamp');

    // Tenter de copier des structures plus complexes
    if (partialData.containsKey('playerManager')) {
      _copyValidDataRecursively(
          partialData['playerManager'] as Map<String, dynamic>,
          minimalData['playerManager'] as Map<String, dynamic>
      );
    }

    if (partialData.containsKey('productionManager')) {
      _copyValidDataRecursively(
          partialData['productionManager'] as Map<String, dynamic>,
          minimalData['productionManager'] as Map<String, dynamic>
      );
    }

    // Si productionManager est absent mais playerManager contient paperclips
    if (!partialData.containsKey('productionManager') &&
        partialData.containsKey('playerManager')) {
      final playerData = partialData['playerManager'] as Map<String, dynamic>?;
      if (playerData != null && playerData.containsKey('paperclips')) {
        (minimalData['productionManager'] as Map<String, dynamic>)['paperclips'] =
        playerData['paperclips'];
      }
    }

    return minimalData;
  }

  /// Copie une propriété si elle est valide
  static void _copyIfValid(Map<String, dynamic> source, Map<String, dynamic> target, String key) {
    if (source.containsKey(key) && source[key] != null) {
      target[key] = source[key];
    }
  }

  /// Copie récursivement des données valides
  static void _copyValidDataRecursively(
      Map<String, dynamic> source, Map<String, dynamic> target) {
    for (final key in target.keys) {
      if (source.containsKey(key) && source[key] != null) {
        if (source[key] is Map && target[key] is Map) {
          _copyValidDataRecursively(
              source[key] as Map<String, dynamic>,
              target[key] as Map<String, dynamic>
          );
        } else {
          target[key] = source[key];
        }
      }
    }
  }

  /// Répare les données en ajoutant des valeurs par défaut si nécessaire
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
        final playerData = data['playerManager'] as Map<String, dynamic>;
        if (playerData.containsKey('paperclips')) {
          paperclips = _toDouble(playerData['paperclips']) ?? 0.0;
        }
        if (playerData.containsKey('autoclippers')) {
          autoclippers = _toInt(playerData['autoclippers']) ?? 0;
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

    // S'assurer que les clés nécessaires sont présentes dans playerManager
    final playerData = data['playerManager'] as Map<String, dynamic>;
    if (!playerData.containsKey('money')) playerData['money'] = 0.0;
    if (!playerData.containsKey('metal')) playerData['metal'] = GameConstants.INITIAL_METAL;
    if (!playerData.containsKey('sellPrice')) playerData['sellPrice'] = GameConstants.INITIAL_PRICE;
    if (!playerData.containsKey('upgrades')) playerData['upgrades'] = {};

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