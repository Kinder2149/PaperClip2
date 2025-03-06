// lib/core/exceptions/game_exceptions.dart

/// Exception levée lors d'erreurs de logique métier dans le jeu
class GameLogicException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  const GameLogicException(this.message, [this.stackTrace]);

  @override
  String toString() => 'GameLogicException: $message';
}

/// Exception spécifique aux erreurs de ressources insuffisantes
class InsufficientResourcesException extends GameLogicException {
  final String resourceType;
  final double required;
  final double available;

  const InsufficientResourcesException({
    required this.resourceType,
    required this.required,
    required this.available,
  }) : super('Ressources insuffisantes pour $resourceType');

  @override
  String toString() =>
      'InsufficientResourcesException: $resourceType requis $required, disponible $available';
}

/// Exception pour les erreurs de configuration de jeu
class GameConfigurationException extends GameLogicException {
  const GameConfigurationException(String message) : super(message);
}

/// Exception pour les erreurs de sauvegarde et de chargement
class GameSaveException extends GameLogicException {
  final String? saveName;

  const GameSaveException(String message, {this.saveName}) : super(message);

  @override
  String toString() =>
      'GameSaveException: $message' + (saveName != null ? ' (sauvegarde: $saveName)' : '');
}

/// Exception pour les erreurs de progression
class ProgressionLockedException extends GameLogicException {
  final String lockedFeature;
  final int requiredLevel;

  const ProgressionLockedException({
    required this.lockedFeature,
    required this.requiredLevel
  }) : super('Fonctionnalité verrouillée');

  @override
  String toString() =>
      'ProgressionLockedException: $lockedFeature nécessite niveau $requiredLevel';
}