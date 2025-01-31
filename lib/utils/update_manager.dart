import '../models/game_config.dart';  // Ajustez le chemin selon votre structure de dossiers

class UpdateManager {
  static const String CURRENT_VERSION = "1.0.2";  // Mise à jour de la version
  static const int CURRENT_BUILD_NUMBER = 3;      // Incrémenté

  static const Map<String, List<String>> CHANGES = {
    "1.0.2": [
      "Correction du système d'efficacité (11% par niveau)",
      "Amélioration de la gestion des types de données",
      "Correction des conversions de données statistiques",
      "Plafonnement de l'efficacité à 85%"
    ],
    "1.0.1": [
      "Ajout du système de versions",
      "Amélioration de la gestion des sauvegardes",
      "Préparation pour les futures mises à jour"
    ],
    "1.0.0": [
      "Version initiale du jeu",
      "Système de production de trombones",
      "Système de marché et d'améliorations"
    ]
  };

  static bool needsMigration(String? saveVersion) {
    if (saveVersion == null) return true;

    List<int> currentVersionParts = CURRENT_VERSION.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    List<int> saveVersionParts = saveVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    for (int i = 0; i < currentVersionParts.length; i++) {
      if (i >= saveVersionParts.length) return true;
      if (currentVersionParts[i] > saveVersionParts[i]) return true;
      if (currentVersionParts[i] < saveVersionParts[i]) return false;
    }

    return false;
  }

  static Map<String, dynamic> migrateData(Map<String, dynamic> saveData) {
    String saveVersion = saveData['version'] ?? "1.0.0";

    // Migration de 1.0.0 vers 1.0.1
    if (saveVersion == "1.0.0") {
      saveData['totalTimePlayedInSeconds'] = saveData['totalTimePlayedInSeconds'] ?? 0;
      saveData['achievementsUnlocked'] = saveData['achievementsUnlocked'] ?? [];
      saveVersion = "1.0.1";
    }

    // Migration de 1.0.1 vers 1.0.2
    if (saveVersion == "1.0.1") {
      // Conversion des données statistiques en double
      if (saveData['statistics'] != null) {
        var stats = saveData['statistics'] as Map<String, dynamic>;
        stats['totalMetalUsed'] = (stats['totalMetalUsed'] as num?)?.toDouble() ?? 0.0;
        stats['totalMetalSaved'] = (stats['totalMetalSaved'] as num?)?.toDouble() ?? 0.0;
        stats['currentEfficiency'] = (stats['currentEfficiency'] as num?)?.toDouble() ?? 0.0;
      }

      // Mise à jour des upgrades pour le nouveau système d'efficacité
      if (saveData['playerManager'] != null) {
        var playerData = saveData['playerManager'] as Map<String, dynamic>;
        if (playerData['upgrades'] != null) {
          var upgrades = playerData['upgrades'] as Map<String, dynamic>;
          if (upgrades['efficiency'] != null) {
            var efficiency = upgrades['efficiency'] as Map<String, dynamic>;
            // Assure que le niveau d'efficacité ne dépasse pas la nouvelle limite
            efficiency['level'] = (efficiency['level'] as num?)?.toInt() ?? 0;
            if (efficiency['level'] > GameConstants.MAX_EFFICIENCY_LEVEL) {
              efficiency['level'] = GameConstants.MAX_EFFICIENCY_LEVEL;
            }
          }
        }
      }

      saveVersion = "1.0.2";
    }

    saveData['version'] = CURRENT_VERSION;
    saveData['buildNumber'] = CURRENT_BUILD_NUMBER;

    return saveData;
  }

  static String getChangelogForVersion(String version) {
    if (!CHANGES.containsKey(version)) {
      return "Aucun changement listé pour la version $version";
    }
    return "• ${CHANGES[version]!.join("\n• ")}";
  }

  static String getFullChangelog() {
    String changelog = "";
    CHANGES.forEach((version, changes) {
      changelog += "\nVersion $version:\n• ${changes.join('\n• ')}\n";
    });
    return changelog;
  }
}