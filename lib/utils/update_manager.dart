class UpdateManager {
  static const String CURRENT_VERSION = "1.0.1";
  static const int CURRENT_BUILD_NUMBER = 2;  // Incrémenté à chaque mise à jour

  static const Map<String, List<String>> CHANGES = {
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

    // Convertit les versions en nombres pour comparaison
    List<int> currentVersionParts = CURRENT_VERSION.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    List<int> saveVersionParts = saveVersion.split('.')
        .map((part) => int.parse(part.replaceAll(RegExp(r'[^\d]'), '')))
        .toList();

    // Compare les versions
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
      // Ajout des nouveaux champs si nécessaire
      saveData['totalTimePlayedInSeconds'] = saveData['totalTimePlayedInSeconds'] ?? 0;
      saveData['achievementsUnlocked'] = saveData['achievementsUnlocked'] ?? [];

      saveVersion = "1.0.1";
    }

    // Migration futures versions
    // if (saveVersion == "1.0.1") { ... }

    // Met à jour la version dans les données
    saveData['version'] = CURRENT_VERSION;
    saveData['buildNumber'] = CURRENT_BUILD_NUMBER;

    return saveData;
  }

  static String getChangelogForVersion(String version) {
    if (!CHANGES.containsKey(version)) {
      return "Aucun changement listé pour la version $version";
    }

    return CHANGES[version]!.join("\n• ");
  }

  static String getFullChangelog() {
    String changelog = "";
    CHANGES.forEach((version, changes) {
      changelog += "\nVersion $version:\n• ${changes.join('\n• ')}\n";
    });
    return changelog;
  }
}