// lib/services/save_system/save_validator.dart
// Validateur amélioré pour les données de sauvegarde

import 'package:flutter/foundation.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Résultat d'une opération de validation.
class ValidationResult {
  /// Indique si les données sont valides.
  final bool isValid;
  
  /// Liste des erreurs rencontrées lors de la validation.
  final List<String> errors;
  
  /// Données validées et potentiellement corrigées.
  final Map<String, dynamic>? validatedData;
  
  /// Niveau de gravité des erreurs.
  final ValidationSeverity severity;
  
  /// Alias pour validatedData, pour compatibilité avec l'ancien code
  Map<String, dynamic>? get sanitizedData => validatedData;

  ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.validatedData,
    this.severity = ValidationSeverity.none,
  });
  
  @override
  String toString() => 'ValidationResult(isValid: $isValid, errors: ${errors.length}, severity: $severity)';
}

/// Niveau de gravité des erreurs de validation.
enum ValidationSeverity {
  /// Aucune erreur.
  none,
  
  /// Erreurs mineures qui ont été corrigées automatiquement.
  warning,
  
  /// Erreurs qui nécessitent une attention mais n'empêchent pas le chargement.
  moderate,
  
  /// Erreurs critiques qui empêchent le chargement des données.
  critical,
}

/// Validateur avancé pour les données de sauvegarde avec support multi-versions.
class SaveValidator {
  /// Règles de validation pour la version actuelle (2.0) du format de sauvegarde.
  static const Map<String, Map<String, dynamic>> _validationRulesV2 = {
    'playerManager': {
      'money': {'type': 'double', 'min': 0.0, 'required': true},
      'metal': {'type': 'double', 'min': 0.0, 'required': true},
      'paperclips': {'type': 'double', 'min': 0.0, 'required': true},
      'autoClipperCount': {'type': 'int', 'min': 0, 'required': false, 'defaultValue': 0},
      'megaClipperCount': {'type': 'int', 'min': 0, 'required': false, 'defaultValue': 0},
      'sellPrice': {'type': 'double', 'min': 0.01, 'max': 1.0, 'required': true},
      'upgrades': {'type': 'map', 'required': false, 'defaultValue': {}},
    },
    'marketManager': {
      'marketMetalStock': {'type': 'double', 'min': 0.0, 'required': true},
      'reputation': {'type': 'double', 'min': 0.0, 'max': 2.0, 'required': false, 'defaultValue': 1.0},
      'dynamics': {'type': 'map', 'required': false, 'defaultValue': {}},
    },
    'levelSystem': {
      'experience': {'type': 'double', 'min': 0.0, 'required': true},
      'level': {'type': 'int', 'min': 1, 'required': true},
      'currentPath': {'type': 'int', 'min': 0, 'required': false, 'defaultValue': 0},
      'xpMultiplier': {'type': 'double', 'min': 1.0, 'required': false, 'defaultValue': 1.0},
    },
  };

  /// Validation complète des données de sauvegarde avec support multi-versions.
  ///
  /// [data] : Les données à valider
  /// [targetVersion] : Version cible pour la validation (par défaut : version actuelle)
  /// [strictMode] : Si true, échoue à la première erreur critique
  /// [quickMode] : Si true, utilise une validation rapide et allégée (utile pour les sauvegardes automatiques)
  static ValidationResult validate(
    Map<String, dynamic> data, {
    String? targetVersion,
    bool strictMode = false,
    bool quickMode = false,
  }) {
    List<String> errors = [];
    ValidationSeverity highestSeverity = ValidationSeverity.none;

    try {
      // Si quickMode est activé, utiliser la validation rapide
      if (quickMode) {
        return _quickValidate(data);
      }
      
      // Déterminer la version source des données
      final String sourceVersion = data['version'] as String? ?? '1.0';
      final String validationVersion = targetVersion ?? sourceVersion;
      
      if (kDebugMode) {
        print('Validation de données en version $sourceVersion (cible: $validationVersion)');
      }
      
      // 1. Vérifier les métadonnées de base
      final metadataResult = _validateBasicMetadata(data);
      errors.addAll(metadataResult.errors);
      highestSeverity = _maxSeverity(highestSeverity, metadataResult.severity);
      
      if (strictMode && metadataResult.severity == ValidationSeverity.critical) {
        return ValidationResult(
          isValid: false,
          errors: errors,
          severity: highestSeverity,
        );
      }

      // 2. Extraire gameData si présent
      Map<String, dynamic> gameData = data;
      if (data.containsKey('gameData') && data['gameData'] is Map<String, dynamic>) {
        gameData = data['gameData'] as Map<String, dynamic>;
      }

      // 3. Vérifier les sections obligatoires
      final sectionsResult = _validateMandatorySections(gameData);
      errors.addAll(sectionsResult.errors);
      highestSeverity = _maxSeverity(highestSeverity, sectionsResult.severity);
      
      if (strictMode && sectionsResult.severity == ValidationSeverity.critical) {
        return ValidationResult(
          isValid: false,
          errors: errors,
          severity: highestSeverity,
        );
      }
      
      // 4. Compléter les champs manquants
      final Map<String, dynamic> fixedData = Map<String, dynamic>.from(data);
      Map<String, dynamic> fixedGameData;
      
      if (fixedData.containsKey('gameData')) {
        fixedGameData = Map<String, dynamic>.from(fixedData['gameData'] as Map<String, dynamic>);
        fixedData['gameData'] = fixedGameData;
      } else {
        fixedGameData = fixedData;
      }
      
      _fillMissingFields(fixedGameData);
      
      // 5. Valider toutes les sections
      final sectionsValidationResult = _validateAllSections(fixedGameData);
      errors.addAll(sectionsValidationResult.errors);
      highestSeverity = _maxSeverity(highestSeverity, sectionsValidationResult.severity);
      
      // 6. Valider les règles spécifiques au jeu
      final gameRulesResult = _validateGameSpecificRules(fixedGameData);
      errors.addAll(gameRulesResult.errors);
      highestSeverity = _maxSeverity(highestSeverity, gameRulesResult.severity);

      // Déterminer si les données sont globalement valides
      final bool isValid = highestSeverity != ValidationSeverity.critical;
      
      return ValidationResult(
        isValid: isValid,
        errors: errors,
        validatedData: fixedData,
        severity: highestSeverity,
      );
    } catch (e) {
      errors.add('Erreur inattendue lors de la validation: $e');
      if (kDebugMode) {
        print('Erreur lors de la validation des données: $e');
      }
      return ValidationResult(
        isValid: false,
        errors: errors,
        severity: ValidationSeverity.critical,
      );
    }
  }

  /// Validation rapide pour les vérifications de routine.
  ///
  /// Ne vérifie que la présence des champs essentiels.
  /// [data] : Les données à valider rapidement
  static ValidationResult _quickValidate(Map<String, dynamic> data) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;

    try {
      // Vérifier les métadonnées de base
      if (!data.containsKey('version') || !data.containsKey('timestamp')) {
        errors.add('Métadonnées de base manquantes (version ou timestamp)');
        severity = ValidationSeverity.critical;
        return ValidationResult(
          isValid: false,
          errors: errors,
          severity: severity,
        );
      }
      
      // Vérifier la présence de gameData
      Map<String, dynamic> gameData;
      if (data.containsKey('gameData')) {
        if (data['gameData'] is! Map) {
          errors.add('Le champ gameData n\'est pas une Map valide');
          severity = ValidationSeverity.critical;
          return ValidationResult(
            isValid: false,
            errors: errors,
            severity: severity,
          );
        }
        
        try {
          gameData = Map<String, dynamic>.from(data['gameData'] as Map);
        } catch (e) {
          errors.add('Erreur lors de la conversion de gameData: $e');
          severity = ValidationSeverity.critical;
          return ValidationResult(
            isValid: false,
            errors: errors,
            severity: severity,
          );
        }
      } else {
        // Ancienne structure où les données sont directement à la racine
        gameData = data;
      }
      
      // Vérifier les sections essentielles
      final essentialSections = ['playerManager', 'marketManager'];
      for (final section in essentialSections) {
        if (!gameData.containsKey(section)) {
          errors.add('Section essentielle manquante: $section');
          severity = ValidationSeverity.moderate;
        } else if (gameData[section] is! Map) {
          errors.add('Section $section invalide (type incorrect)');
          severity = ValidationSeverity.moderate;
        }
      }

      // Vérifier les champs essentiels dans playerManager
      if (gameData.containsKey('playerManager') && gameData['playerManager'] is Map) {
        final playerManager = Map<String, dynamic>.from(gameData['playerManager'] as Map);
        final essentialFields = ['money', 'metal', 'paperclips'];
        
        for (final field in essentialFields) {
          if (!playerManager.containsKey(field)) {
            errors.add('Champ essentiel manquant dans playerManager: $field');
            severity = ValidationSeverity.moderate;
          }
        }
      }

      return ValidationResult(
        isValid: severity != ValidationSeverity.critical,
        errors: errors,
        validatedData: data,
        severity: severity,
      );
    } catch (e) {
      errors.add('Erreur lors de la validation rapide: $e');
      return ValidationResult(
        isValid: false,
        errors: errors,
        severity: ValidationSeverity.critical,
      );
    }
  }

  /// Valide les métadonnées de base (version, timestamp).
  static ValidationResult _validateBasicMetadata(Map<String, dynamic> data) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;
    
    // Vérifier la présence de la version
    if (!data.containsKey('version')) {
      errors.add('Version manquante');
      severity = ValidationSeverity.moderate; // On peut fixer ça
    } else if (data['version'] is! String) {
      errors.add('Version invalide (type incorrect)');
      severity = ValidationSeverity.moderate;
    }
    
    // Vérifier la présence du timestamp
    if (!data.containsKey('timestamp')) {
      errors.add('Timestamp manquant');
      severity = ValidationSeverity.warning; // On peut fixer ça
    } else {
      try {
        DateTime.parse(data['timestamp'].toString());
      } catch (e) {
        errors.add('Timestamp invalide: ${data['timestamp']}');
        severity = ValidationSeverity.warning;
      }
    }
    
    return ValidationResult(
      isValid: severity != ValidationSeverity.critical,
      errors: errors,
      severity: severity,
    );
  }

  /// Vérifie la présence des sections obligatoires.
  static ValidationResult _validateMandatorySections(Map<String, dynamic> data) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;
    
    // Liste des sections obligatoires
    final mandatorySections = ['playerManager', 'marketManager'];
    
    for (final section in mandatorySections) {
      if (!data.containsKey(section)) {
        errors.add('Section obligatoire manquante: $section');
        severity = ValidationSeverity.moderate; // On peut la créer vide
      } else if (data[section] is! Map) {
        errors.add('Section $section invalide (type incorrect)');
        severity = ValidationSeverity.moderate;
      }
    }
    
    return ValidationResult(
      isValid: severity != ValidationSeverity.critical,
      errors: errors,
      severity: severity,
    );
  }

  /// Ajoute des valeurs par défaut aux champs manquants.
  static void _fillMissingFields(Map<String, dynamic> data) {
    // Pour chaque section dans les règles de validation
    for (final sectionName in _validationRulesV2.keys) {
      // Si la section n'existe pas, la créer
      if (!data.containsKey(sectionName)) {
        data[sectionName] = <String, dynamic>{};
      }
      
      // Garantir que la section est bien une Map<String, dynamic>
      if (data[sectionName] is! Map) {
        data[sectionName] = <String, dynamic>{};
      }
      
      // Utiliser Map.from pour garantir Map<String, dynamic>
      var sectionData = Map<String, dynamic>.from(data[sectionName] as Map);
      data[sectionName] = sectionData; // Réattribution pour garantir le type
      var rules = _validationRulesV2[sectionName]!;
      
      // Pour chaque champ de la section, vérifier s'il est manquant
      for (var fieldName in rules.keys) {
        var rule = rules[fieldName] as Map<String, dynamic>;
        
        // Si le champ est manquant et qu'il a une valeur par défaut définie
        if (!sectionData.containsKey(fieldName) && rule.containsKey('defaultValue')) {
          if (kDebugMode) {
            print('Ajout du champ manquant $sectionName.$fieldName avec valeur par défaut ${rule['defaultValue']}');
          }
          sectionData[fieldName] = rule['defaultValue'];
        }
      }
    }
  }

  /// Valide toutes les sections selon les règles définies.
  static ValidationResult _validateAllSections(Map<String, dynamic> data) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;
    
    for (var sectionName in _validationRulesV2.keys) {
      if (!data.containsKey(sectionName)) {
        continue; // Déjà traité dans _validateMandatorySections
      }

      // Vérification et conversion sécurisée
      if (data[sectionName] is! Map) {
        continue; // Déjà traité dans _validateMandatorySections
      }
      
      // Conversion sécurisée avec Map.from
      Map<String, dynamic> sectionData;
      try {
        sectionData = Map<String, dynamic>.from(data[sectionName] as Map);
      } catch (e) {
        errors.add('Erreur lors de la conversion de $sectionName: $e');
        severity = _maxSeverity(severity, ValidationSeverity.moderate);
        continue;
      }

      // Vérifier chaque champ de la section
      var rules = _validationRulesV2[sectionName]!;
      for (var fieldName in rules.keys) {
        var rule = rules[fieldName] as Map<String, dynamic>;
        bool required = rule['required'] as bool? ?? true;
        
        if (!sectionData.containsKey(fieldName)) {
          if (required && !rule.containsKey('defaultValue')) {
            errors.add('Champ obligatoire manquant dans $sectionName: $fieldName');
            severity = _maxSeverity(severity, ValidationSeverity.moderate);
          }
          continue;
        }

        var value = sectionData[fieldName];
        final fieldResult = _validateField(value, rule, '$sectionName.$fieldName');
        errors.addAll(fieldResult.errors);
        severity = _maxSeverity(severity, fieldResult.severity);
      }
    }
    
    return ValidationResult(
      isValid: severity != ValidationSeverity.critical,
      errors: errors,
      severity: severity,
    );
  }

  /// Valide un champ selon sa règle.
  static ValidationResult _validateField(
    dynamic value,
    Map<String, dynamic> rule,
    String fieldPath,
  ) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;
    
    // Vérification du type
    if (!_validateType(value, rule['type'] as String)) {
      errors.add('Type invalide pour $fieldPath');
      severity = ValidationSeverity.moderate;
      return ValidationResult(
        isValid: false,
        errors: errors,
        severity: severity,
      );
    }

    // Vérification des limites pour les nombres
    if (value is num) {
      if (rule.containsKey('min') && value < rule['min']) {
        errors.add('Valeur trop petite pour $fieldPath');
        severity = ValidationSeverity.moderate;
      }
      if (rule.containsKey('max') && value > rule['max']) {
        errors.add('Valeur trop grande pour $fieldPath');
        severity = ValidationSeverity.moderate;
      }
    }
    
    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      severity: severity,
    );
  }

  /// Valide les règles spécifiques au jeu.
  static ValidationResult _validateGameSpecificRules(Map<String, dynamic> data) {
    List<String> errors = [];
    ValidationSeverity severity = ValidationSeverity.none;
    
    // Vérification du mode de jeu
    if (data.containsKey('gameMode')) {
      try {
        int modeIndex = data['gameMode'] as int;
        if (modeIndex < 0 || modeIndex >= GameMode.values.length) {
          errors.add('Mode de jeu invalide');
          severity = ValidationSeverity.moderate;
        }
      } catch (e) {
        errors.add('Format du mode de jeu invalide');
        severity = ValidationSeverity.moderate;
      }
    }

    // Vérification de la cohérence entre paperclips et money
    try {
      if (data.containsKey('playerManager')) {
        final playerManager = data['playerManager'] as Map<String, dynamic>;
        final double paperclips = playerManager['paperclips'] as double? ?? 0.0;
        final double money = playerManager['money'] as double? ?? 0.0;
        final double sellPrice = playerManager['sellPrice'] as double? ?? 0.05;
        
        // Vérification simpliste : l'argent ne devrait pas dépasser un seuil basé sur les clips
        final double maxMoney = paperclips * sellPrice * 2.0; // Un facteur arbitraire pour la flexibilité
        if (money > maxMoney && paperclips > 100) {
          errors.add('Possible incohérence détectée entre argent ($money) et clips produits ($paperclips)');
          severity = _maxSeverity(severity, ValidationSeverity.warning);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors de la vérification de cohérence: $e');
      }
      // Ne pas bloquer pour cette vérification
    }
    
    return ValidationResult(
      isValid: severity != ValidationSeverity.critical,
      errors: errors,
      severity: severity,
    );
  }

  /// Valide le type d'une valeur.
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
  
  /// Retourne la sévérité la plus élevée entre deux valeurs.
  static ValidationSeverity _maxSeverity(ValidationSeverity a, ValidationSeverity b) {
    return ValidationSeverity.values[
      max(ValidationSeverity.values.indexOf(a), ValidationSeverity.values.indexOf(b))
    ];
  }
  
  /// Fonction utilitaire max
  static int max(int a, int b) => a > b ? a : b;

  /// Validation rapide publique pour les vérifications de routine.
  /// 
  /// Appelle la méthode privée _quickValidate
  /// [data] : Les données à valider rapidement
  static ValidationResult quickValidate(Map<String, dynamic> data) {
    return _quickValidate(data);
  }
}
