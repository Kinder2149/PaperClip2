import '../models/constants/game_constants.dart';
import '../models/exceptions/game_exceptions.dart';

class GameValidators {
  // Validation des noms
  static void validatePlayerName(String name) {
    if (name.length < GameConstants.minNameLength) {
      throw ValidationError(
        'Le nom doit contenir au moins ${GameConstants.minNameLength} caractères',
        code: 'INVALID_NAME_LENGTH',
      );
    }

    if (name.length > GameConstants.maxNameLength) {
      throw ValidationError(
        'Le nom ne peut pas dépasser ${GameConstants.maxNameLength} caractères',
        code: 'INVALID_NAME_LENGTH',
      );
    }

    if (!GameConstants.validNamePattern.hasMatch(name)) {
      throw ValidationError(
        'Le nom ne peut contenir que des lettres, chiffres et underscores',
        code: 'INVALID_NAME_CHARS',
      );
    }
  }

  // Validation des prix
  static void validatePrice(double price) {
    if (price < GameConstants.minPrice) {
      throw ValidationError(
        'Le prix ne peut pas être inférieur à ${GameConstants.minPrice}€',
        code: 'INVALID_PRICE_MIN',
      );
    }

    if (price > GameConstants.maxPrice) {
      throw ValidationError(
        'Le prix ne peut pas dépasser ${GameConstants.maxPrice}€',
        code: 'INVALID_PRICE_MAX',
      );
    }
  }

  // Validation des ressources
  static void validateMetalAmount(double amount) {
    if (amount < 0) {
      throw ResourceError(
        'La quantité de métal ne peut pas être négative',
        code: 'INVALID_METAL_AMOUNT',
      );
    }

    if (amount > GameConstants.maxMetalStorage) {
      throw ResourceError(
        'La quantité de métal ne peut pas dépasser ${GameConstants.maxMetalStorage}',
        code: 'INVALID_METAL_AMOUNT',
      );
    }
  }

  static void validatePaperclipCount(int count) {
    if (count < 0) {
      throw ResourceError(
        'Le nombre de trombones ne peut pas être négatif',
        code: 'INVALID_PAPERCLIP_COUNT',
      );
    }
  }

  // Validation des niveaux
  static void validateLevel(int level) {
    if (level < 1) {
      throw LevelError(
        'Le niveau ne peut pas être inférieur à 1',
        code: 'INVALID_LEVEL_MIN',
      );
    }

    if (level > GameConstants.maxLevel) {
      throw LevelError(
        'Le niveau ne peut pas dépasser ${GameConstants.maxLevel}',
        code: 'INVALID_LEVEL_MAX',
      );
    }
  }

  // Validation des améliorations
  static void validateUpgradeLevel(int level) {
    if (level < 0) {
      throw UpgradeError(
        'Le niveau d\'amélioration ne peut pas être négatif',
        code: 'INVALID_UPGRADE_LEVEL_MIN',
      );
    }

    if (level > GameConstants.maxUpgradeLevel) {
      throw UpgradeError(
        'Le niveau d\'amélioration ne peut pas dépasser ${GameConstants.maxUpgradeLevel}',
        code: 'INVALID_UPGRADE_LEVEL_MAX',
      );
    }
  }

  // Validation des scores
  static void validateScore(int score) {
    if (score < 0) {
      throw ValidationError(
        'Le score ne peut pas être négatif',
        code: 'INVALID_SCORE',
      );
    }
  }

  // Validation des durées
  static void validateDuration(Duration duration) {
    if (duration.isNegative) {
      throw ValidationError(
        'La durée ne peut pas être négative',
        code: 'INVALID_DURATION',
      );
    }
  }

  // Validation des pourcentages
  static void validatePercentage(double value) {
    if (value < 0 || value > 1) {
      throw ValidationError(
        'Le pourcentage doit être compris entre 0 et 1',
        code: 'INVALID_PERCENTAGE',
      );
    }
  }

  // Validation des réputations
  static void validateReputation(double reputation) {
    if (reputation < GameConstants.minReputation) {
      throw ValidationError(
        'La réputation ne peut pas être inférieure à ${GameConstants.minReputation}',
        code: 'INVALID_REPUTATION_MIN',
      );
    }

    if (reputation > GameConstants.maxReputation) {
      throw ValidationError(
        'La réputation ne peut pas dépasser ${GameConstants.maxReputation}',
        code: 'INVALID_REPUTATION_MAX',
      );
    }
  }

  // Validation des sauvegardes
  static void validateSaveData(Map<String, dynamic> data) {
    if (data.isEmpty) {
      throw ValidationError(
        'Les données de sauvegarde ne peuvent pas être vides',
        code: 'INVALID_SAVE_DATA',
      );
    }

    if (data.length > GameConstants.maxSaveSize) {
      throw ValidationError(
        'Les données de sauvegarde sont trop volumineuses',
        code: 'INVALID_SAVE_SIZE',
      );
    }
  }

  // Validation des événements
  static void validateEventProbability(double probability) {
    if (probability < 0 || probability > 1) {
      throw ValidationError(
        'La probabilité doit être comprise entre 0 et 1',
        code: 'INVALID_EVENT_PROBABILITY',
      );
    }
  }
} 