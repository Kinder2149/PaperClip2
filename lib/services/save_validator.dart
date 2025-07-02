// lib/services/save_validator.dart

import 'package:flutter/foundation.dart';
import '../models/game_config.dart';

/// Résultat de validation d'une sauvegarde
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

/// Classe centralisée pour la validation des données de sauvegarde
class SaveDataValidator {
  // Règles de validation pour les différentes sections de données
  static const Map<String, Map<String, dynamic>> _validationRules = {
    'playerManager': {
      'money': {'type': 'double', 'min': 0.0, 'required': true},
      'metal': {'type': 'double', 'min': 0.0, 'required': true},
      'paperclips': {'type': 'double', 'min': 0.0, 'required': true},
      'autoclippers': {'type': 'int', 'min': 0, 'required': true},
      'sellPrice': {'type': 'double', 'min': 0.01, 'max': 1.0, 'required': true},
      'upgrades': {'type': 'map', 'required': false},
    },
    'marketManager': {
      'marketMetalStock': {'type': 'double', 'min': 0.0, 'required': true},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0, 'required': true},
      'dynamics': {'type': 'map', 'required': false},
    },
    'levelSystem': {
      'experience': {'type': 'double', 'min': 0.0, 'required': true},
      'level': {'type': 'int', 'min': 1, 'required': true},
      'currentPath': {'type': 'int', 'min': 0, 'required': false},
      'xpMultiplier': {'type': 'double', 'min': 1.0, 'required': false},
    },
  };

  /// Validation complète des données de sauvegarde
  /// Vérifie la structure, les types et les contraintes des données
  static ValidationResult validate(Map<String, dynamic> data) {
    List<String> errors = [];

    try {
      // 1. Vérification des métadonnées de base
      if (!_validateBasicMetadata(data, errors)) {
        return ValidationResult(isValid: false, errors: errors);
      }

      // 2. Vérifier la présence et la structure des sections gameData si nécessaire
      Map<String, dynamic> gameData = data;
      if (data.containsKey('gameData') && data['gameData'] is Map<String, dynamic>) {
        gameData = data['gameData'] as Map<String, dynamic>;
      }

      // 3. Vérification des sections obligatoires
      if (!_validateMandatorySections(gameData, errors)) {
        return ValidationResult(isValid: false, errors: errors);
      }

      // 4. Vérification détaillée des règles pour chaque section
      _validateAllSections(gameData, errors);
      
      // 5. Vérifications supplémentaires spécifiques au jeu
      _validateGameSpecificRules(gameData, errors);

      // Si pas d'erreurs, les données sont valides
      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        validatedData: data,
      );
    } catch (e) {
      errors.add('Erreur inattendue lors de la validation: $e');
      if (kDebugMode) {
        print('Erreur lors de la validation des données: $e');
      }
      return ValidationResult(isValid: false, errors: errors);
    }
  }

  /// Validation rapide pour les vérifications de routine
  /// Ne vérifie que la présence des champs essentiels
  static bool quickValidate(Map<String, dynamic> data) {
    try {
      // Vérification des métadonnées de base
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        return false;
      }

      // Vérification de gameData si présent
      Map<String, dynamic> gameData = data;
      if (data.containsKey('gameData') && data['gameData'] is Map<String, dynamic>) {
        gameData = data['gameData'] as Map<String, dynamic>;
      }

      // Vérification de playerManager
      if (!gameData.containsKey('playerManager')) {
        return false;
      }

      // Vérification des champs essentiels de playerManager
      final playerData = gameData['playerManager'] as Map<String, dynamic>?;
      if (playerData == null) return false;

      return playerData.containsKey('paperclips') &&
             playerData.containsKey('money') &&
             playerData.containsKey('metal');
    } catch (e) {
      if (kDebugMode) {
        print('Erreur de validation rapide: $e');
      }
      return false;
    }
  }

  /// Validation des métadonnées de base (version, timestamp)
  static bool _validateBasicMetadata(Map<String, dynamic> data, List<String> errors) {
    if (!data.containsKey('version')) {
      errors.add('Métadonnée manquante: version');
      return false;
    }

    if (!data.containsKey('timestamp')) {
      errors.add('Métadonnée manquante: timestamp');
      return false;
    }

    // Vérifier que le timestamp est valide
    try {
      DateTime.parse(data['timestamp'] as String);
    } catch (e) {
      errors.add('Format de timestamp invalide');
      return false;
    }

    return true;
  }

  /// Vérification des sections obligatoires
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

  /// Validation de toutes les sections selon les règles définies
  static void _validateAllSections(Map<String, dynamic> data, List<String> errors) {
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
        var rule = rules[fieldName] as Map<String, dynamic>;
        bool required = rule['required'] as bool? ?? true;
        
        if (!sectionData.containsKey(fieldName)) {
          if (required) {
            errors.add('Champ manquant dans $sectionName: $fieldName');
          }
          continue;
        }

        var value = sectionData[fieldName];
        _validateField(value, rule, errors, '$sectionName.$fieldName');
      }
    }
  }

  /// Validation d'un champ selon sa règle
  static void _validateField(dynamic value, Map<String, dynamic> rule, List<String> errors, String fieldPath) {
    // Vérification du type
    if (!_validateType(value, rule['type'] as String)) {
      errors.add('Type invalide pour $fieldPath');
      return;
    }

    // Vérification des limites pour les nombres
    if (value is num) {
      if (rule.containsKey('min') && value < rule['min']) {
        errors.add('Valeur trop petite pour $fieldPath');
        return;
      }
      if (rule.containsKey('max') && value > rule['max']) {
        errors.add('Valeur trop grande pour $fieldPath');
        return;
      }
    }
  }

  /// Validation des règles spécifiques au jeu
  static void _validateGameSpecificRules(Map<String, dynamic> data, List<String> errors) {
    // Vérification du mode de jeu
    if (data.containsKey('gameMode')) {
      try {
        int modeIndex = data['gameMode'] as int;
        if (modeIndex < 0 || modeIndex >= GameMode.values.length) {
          errors.add('Mode de jeu invalide');
        }
      } catch (e) {
        errors.add('Format du mode de jeu invalide');
      }
    }

    // Ajoutez ici d'autres validations spécifiques au jeu
  }

  /// Validation du type d'une valeur
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
      case 'string':
        return value is String;
      case 'bool':
        return value is bool;
      default:
        return false;
    }
  }
}
