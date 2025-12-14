enum GameEventType {
  productionTick,
  marketTick,
  saleProcessed,
  upgradePurchased,
  autoclipperPurchased,
  progressionPathChosen,
}

class GameEvent {
  final GameEventType type;
  final DateTime at;
  final Map<String, dynamic> data;

  GameEvent({
    required this.type,
    DateTime? at,
    Map<String, dynamic>? data,
  })  : at = at ?? DateTime.now(),
        data = data ?? <String, dynamic>{};
}
