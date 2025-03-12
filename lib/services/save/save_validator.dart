/// Résultat de la validation des données de sauvegarde
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

/// Classe pour valider les données de sauvegarde
class SaveValidator {
  /// Règles de validation pour les différentes sections des données
  static const Map<String, Map<String, dynamic>> _validationRules = {
    'playerManager': {
      'money': {'type': 'double', 'min': 0.0},
      'metal': {'type': 'double', 'min': 0.0},
      'paperclips': {'type': 'double', 'min': 0.0},
      'autoclippers': {'type': 'int', 'min': 0},
      'sellPrice': {'type': 'double', 'min': 0.01, 'max': 1.0},
      'upgrades': {'type': 'map'},
    },
    'marketManager': {
      'marketMetalStock': {'type': 'double', 'min': 0.0},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0},
      'dynamics': {'type': 'map'},
    },
    'levelSystem': {
      'experience': {'type': 'double', 'min': 0.0},
      'level': {'type': 'int', 'min': 1},
      'currentPath': {'type': 'int', 'min': 0},
      'xpMultiplier': {'type': 'double', 'min': 1.0},
    },
  };

  /// Valide les données de sauvegarde
  static ValidationResult validate(Map<String, dynamic> data) {
    List<String> errors = [];

    // Vérification de base
    if (!data.containsKey('version') || !data.containsKey('timestamp')) {
      errors.add('Données de base manquantes (version ou timestamp)');
      return ValidationResult(isValid: false, errors: errors);
    }

    // Vérification des sections obligatoires
    if (!_validateMandatorySections(data, errors)) {
      return ValidationResult(isValid: false, errors: errors);
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

    // Si pas d'erreurs, les données sont valides
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      validatedData: data,
    );
  }

  /// Validation rapide des données de sauvegarde
  static bool quickValidate(Map<String, dynamic> data) {
    try {
      if (!data.containsKey('version') ||
          !data.containsKey('timestamp') ||
          !data.containsKey('playerManager')) {
        return false;
      }

      // Vérification rapide des données critiques
      final playerData = data['playerManager'] as Map<String, dynamic>?;
      if (playerData == null) return false;

      return playerData.containsKey('money') &&
          playerData.containsKey('metal') &&
          playerData.containsKey('paperclips');
    } catch (e) {
      print('Erreur de validation rapide: $e');
      return false;
    }
  }

  /// Vérifie si les sections obligatoires sont présentes
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

  /// Valide un champ selon les règles spécifiées
  static bool _validateField(dynamic value, Map<String, dynamic> rule, List<String> errors, String fieldPath) {
    // Vérification du type
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

  /// Vérifie si la valeur correspond au type attendu
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
      default:
        return false;
    }
  }
}

/// Exception pour les erreurs de sauvegarde
class SaveError implements Exception {
  final String code;
  final String message;
  
  SaveError(this.code, this.message);

  @override
  String toString() => '$code: $message';
} 