import '../../models/game_config.dart';
import 'dart:math' as math;

class SaveMigrationService {
  static Map<String, dynamic> migrateIfNeeded(Map<String, dynamic> data) {
    try {
      // Déterminer la version actuelle
      final version = data['version'] as String? ?? '1.0.0';

      // Migrations séquentielles depuis la version actuelle
      data = _migrateFromVersion(data, version);

      // Mettre à jour la version
      data['version'] = GameConstants.VERSION;

      return data;
    } catch (e) {
      print('Erreur pendant la migration: $e');
      return data; // Retourner les données originales en cas d'erreur
    }
  }

  static Map<String, dynamic> _migrateFromVersion(Map<String, dynamic> data, String version) {
    // Migration depuis les anciennes versions vers les nouvelles
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
    List<int> currentParts = currentVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    List<int> targetParts = targetVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    // Assurer une longueur minimale
    while (currentParts.length < 3) currentParts.add(0);
    while (targetParts.length < 3) targetParts.add(0);

    // Comparer les parties
    for (int i = 0; i < math.min(currentParts.length, targetParts.length); i++) {
      if (currentParts[i] < targetParts[i]) return true;
      if (currentParts[i] > targetParts[i]) return false;
    }

    return currentParts.length < targetParts.length;
  }

  // Migration V1.0.0 à V1.0.1 - Ajout de statistiques
  static Map<String, dynamic> _migrateV1_0_0_to_V1_0_1(Map<String, dynamic> data) {
    data['totalTimePlayedInSeconds'] = data['totalTimePlayedInSeconds'] ?? 0;
    data['achievementsUnlocked'] = data['achievementsUnlocked'] ?? [];
    return data;
  }

  // Migration V1.0.1 à V1.0.2 - Ajustement des données numériques
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

  // Migration V1.0.2 à V1.0.3 - Ajout de ProductionManager
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

        // Garder paperclips dans playerManager pour compatibilité
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

  // Utilitaire pour convertir en double de manière sécurisée
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

  // Utilitaire pour convertir en int de manière sécurisée
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