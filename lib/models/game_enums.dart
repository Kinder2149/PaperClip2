enum EventType {
  LEVEL_UP,
  MARKET_CHANGE,
  RESOURCE_DEPLETION,
  UPGRADE_AVAILABLE,
  SPECIAL_ACHIEVEMENT,
  XP_BOOST
}

enum EventImportance {
  LOW(0),
  MEDIUM(1),
  HIGH(2),
  CRITICAL(3);

  final int value;
  const EventImportance(this.value);

  bool operator >=(EventImportance other) {
    return value >= other.value;
  }
}

enum UnlockableFeature {
  MANUAL_PRODUCTION,
  METAL_PURCHASE,
  MARKET_SALES,
  MARKET_SCREEN,
  AUTOCLIPPERS,
  UPGRADES,
}
enum MarketEvent {
  PRICE_WAR,
  DEMAND_SPIKE,
  MARKET_CRASH,
  QUALITY_CONCERNS
}

class MarketSegment {
  final String name;
  final double elasticity;
  final double maxPrice;
  final double marketShare;

  const MarketSegment(
      this.name,
      this.elasticity,
      this.maxPrice,
      this.marketShare
      );
}