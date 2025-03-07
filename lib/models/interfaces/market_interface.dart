import '../types/game_types.dart';

abstract class IMarket {
  double get basePrice;
  double get currentPrice;
  double get priceMultiplier;
  double get demandMultiplier;
  MarketEvent? get currentEvent;
  bool get isEventActive;
  DateTime? get eventEndTime;
  double get demand;
  double get reputation;
  double get marketMetalStock;
  double get currentMetalPrice;
  double get competitionPrice;
  double get difficultyMultiplier;

  void updatePrice();
  void setPrice(double newPrice);
  void applyEvent(MarketEvent event);
  void removeEvent();
  void updateDemand(double newDemand);
  double calculateEffectivePrice();
  void updateMarket();
  void updateMarketStock(double amount);
  void updateReputation(double amount);
  void updateDifficulty(int monthsPassed);
  void recordSale(int amount, double price);
  Map<String, dynamic> toJson();
  
  factory IMarket.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('fromJson must be implemented by the concrete class');
  }
} 