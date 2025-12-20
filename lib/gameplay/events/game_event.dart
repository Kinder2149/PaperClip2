enum GameEventType {
  productionTick,
  marketTick,
  saleProcessed,
  upgradePurchased,
  autoclipperPurchased,
  progressionPathChosen,
  importantEventOccurred,
}

/// Niveau de sévérité indicatif pour l'UI/Audio/Logs.
enum GameEventSeverity {
  info,
  warning,
  error,
}

class GameEvent {
  final GameEventType type;
  final DateTime at;
  final Map<String, dynamic> data;
  /// Origine logique de l'événement (ex: "GameState", "MarketManager").
  final String? source;
  /// Sévérité pour aider l'UI/Audio à prioriser.
  final GameEventSeverity severity;

  GameEvent({
    required this.type,
    DateTime? at,
    Map<String, dynamic>? data,
    this.source,
    GameEventSeverity? severity,
  })  : at = at ?? DateTime.now(),
        data = data ?? <String, dynamic>{},
        severity = severity ?? GameEventSeverity.info;
}
