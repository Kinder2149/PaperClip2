import '../../core/constants/game_constants.dart';  // Ajustez le chemin selon votre structure de dossiers

class UpdateManager {
  static const String CURRENT_VERSION = "1.0.3";  // Mise Ã  jour de la version
  static const int CURRENT_BUILD_NUMBER = 3;      // IncrÃ©mentÃ©

  static const Map<String, List<String>> CHANGES = {
    "1.0.2": [
      "Correction du systÃ¨me d'efficacitÃ© (11% par niveau)",
      "AmÃ©lioration de la gestion des types de donnÃ©es",
      "Correction des conversions de donnÃ©es statistiques",
      "Plafonnement de l'efficacitÃ© Ã  85%"
    ],
    "1.0.1": [
      "Ajout du systÃ¨me de versions",
      "AmÃ©lioration de la gestion des sauvegardes",
      "PrÃ©paration pour les futures mises Ã  jour"
    ],
    "1.0.0": [
      "Version initiale du jeu",
      "SystÃ¨me de production de trombones",
      "SystÃ¨me de marchÃ© et d'amÃ©liorations"
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
      // Conversion des donnÃ©es statistiques en double
      if (saveData['statistics'] != null) {
        var stats = saveData['statistics'] as Map<String, dynamic>;
        stats['totalMetalUsed'] = (stats['totalMetalUsed'] as num?)?.toDouble() ?? 0.0;
        stats['totalMetalSaved'] = (stats['totalMetalSaved'] as num?)?.toDouble() ?? 0.0;
        stats['currentEfficiency'] = (stats['currentEfficiency'] as num?)?.toDouble() ?? 0.0;
      }

      // Mise Ã  jour des upgrades pour le nouveau systÃ¨me d'efficacitÃ©
      if (saveData['playerManager'] != null) {
        var playerData = saveData['playerManager'] as Map<String, dynamic>;
        if (playerData['upgrades'] != null) {
          var upgrades = playerData['upgrades'] as Map<String, dynamic>;
          if (upgrades['efficiency'] != null) {
            var efficiency = upgrades['efficiency'] as Map<String, dynamic>;
            // Assure que le niveau d'efficacitÃ© ne dÃ©passe pas la nouvelle limite
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
      return "Aucun changement listÃ© pour la version $version";
    }
    return "â€¢ ${CHANGES[version]!.join("\nâ€¢ ")}";
  }

  static String getFullChangelog() {
    String changelog = "";
    CHANGES.forEach((version, changes) {
      changelog += "\nVersion $version:\nâ€¢ ${changes.join('\nâ€¢ ')}\n";
    });
    return changelog;
  }
}






