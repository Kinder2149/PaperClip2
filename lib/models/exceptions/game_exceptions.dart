class GameException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  GameException(this.message, {this.code, this.details});

  @override
  String toString() {
    final codeStr = code != null ? '[$code] ' : '';
    final detailsStr = details != null ? '\nDétails: $details' : '';
    return 'GameException: $codeStr$message$detailsStr';
  }
}

class SaveError extends GameException {
  SaveError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'SAVE_ERROR', details: details);
}

class LoadError extends GameException {
  LoadError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'LOAD_ERROR', details: details);
}

class MarketError extends GameException {
  MarketError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'MARKET_ERROR', details: details);
}

class AchievementError extends GameException {
  AchievementError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'ACHIEVEMENT_ERROR', details: details);
}

class LeaderboardError extends GameException {
  LeaderboardError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'LEADERBOARD_ERROR', details: details);
}

class AnalyticsError extends GameException {
  AnalyticsError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'ANALYTICS_ERROR', details: details);
}

class ValidationError extends GameException {
  ValidationError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'VALIDATION_ERROR', details: details);
}

class ResourceError extends GameException {
  ResourceError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'RESOURCE_ERROR', details: details);
}

class StateError extends GameException {
  StateError(String message, {String? code, dynamic details})
      : super(message, code: code ?? 'STATE_ERROR', details: details);
}

class UpgradeError extends GameException {
  UpgradeError(String message, {String code = 'UPGRADE_ERROR', dynamic details})
      : super(message, code: code, details: details);
}

class LevelError extends GameException {
  LevelError(String message, {String code = 'LEVEL_ERROR', dynamic details})
      : super(message, code: code, details: details);
} 