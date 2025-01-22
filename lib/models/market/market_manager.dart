import 'dart:math';
import '../constants.dart';
import 'market_dynamics.dart';
import 'sale_record.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/models/level_system.dart';

// Énumération des événements de marché
enum MarketEventType {
  ECONOMIC_SHIFT,
  INNOVATION_BREAKTHROUGH,
  MARKET_DISRUPTION,
  SEASONAL_CHANGE
}

class MarketManager {
  final MarketDynamics dynamics;
  final Random _random = Random();

  List<SaleRecord> salesHistory = [];
  double reputation = 1.0;
  double marketMetalStock = GameConstants.INITIAL_MARKET_METAL; // 1500 unités de métal

  static const double MARKET_DEPLETION_THRESHOLD = 750.0;

  static const double MIN_PRICE = GameConstants.MIN_PRICE;
  static const double MAX_PRICE = GameConstants.MAX_PRICE;

  MarketManager(this.dynamics);




  bool canSellMetal(double quantity, int maxMetalStorage, double currentPlayerMetal) {
    return marketMetalStock >= quantity &&
        (currentPlayerMetal + quantity) <= maxMetalStorage;
  }

  // Méthode de vente de métal
  bool sellMetal(double quantity, int maxMetalStorage, {
    required double currentPlayerMetal,
    required double currentMetalPrice,
    required Function(double) addMetal,
    required Function(double) subtractMoney
  }) {
    if (canSellMetal(quantity, maxMetalStorage, currentPlayerMetal)) {
      // Vendre le métal
      marketMetalStock -= quantity;
      addMetal(quantity);
      subtractMoney(quantity * currentMetalPrice);

      // Vérifier si le stock de métal est proche de l'épuisement
      _checkMarketDepletion();

      return true;
    }
    return false;
  }
  void _checkMarketDepletion() {
    if (marketMetalStock <= MARKET_DEPLETION_THRESHOLD) {
      // Ajouter un événement critique
      EventManager.addEvent(
          EventType.RESOURCE_DEPLETION,
          'Rupture Imminente des Stocks de Métal',
          description: 'Les réserves de métal du marché sont presque épuisées. Une nouvelle stratégie est nécessaire !',
          importance: EventImportance.CRITICAL
      );
    }
  }


  bool isMarketDepletedForNextPhase() {
    return marketMetalStock <= MARKET_DEPLETION_THRESHOLD;
  }

  void triggerNextPhaseTransition() {
    if (isMarketDepletedForNextPhase()) {
      // Logique de passage à la phase suivante
      print("Les réserves de métal du marché s'épuisent. Nouvelle stratégie requise !");
    }
  }


  // Méthode pour recharger le stock du marché (optionnel)
  void restockMetal() {
    // Réapprovisionner périodiquement ou selon certaines conditions
    if (marketMetalStock < GameConstants.INITIAL_MARKET_METAL * 0.5) {
      marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    }
  }

  // Calcul de l'élasticité de prix
  double _calculatePriceElasticity(double price) {
    double baseElasticity = -1.5;
    double historicalAdjustment = _calculateHistoricalElasticityModifier();
    return baseElasticity * (1 + historicalAdjustment);
  }

  double _calculateBaseDemand(double price, double elasticity) {
    const double marketSaturation = 100.0;
    return marketSaturation * (1 / (1 + exp(elasticity * price)));
  }


  // Calcul de la demande de base
  double calculateDemand(double price, int marketingLevel) {
    double baseElasticity = _calculatePriceElasticity(price);
    double baseDemand = _calculateBaseDemand(price, baseElasticity);

    // Facteurs d'influence
    double marketingMultiplier = 1.0 + (marketingLevel * 0.3);
    double reputationFactor = 0.5 + (reputation * 0.5);
    double seasonalityFactor = _calculateSeasonalityFactor();
    double competitivePressure = _calculateCompetitivePressure();

    // Calcul de la demande finale
    double finalDemand = baseDemand
        * marketingMultiplier
        * reputationFactor
        * seasonalityFactor
        * (1 + competitivePressure)
        * dynamics.getMarketConditionMultiplier();

    return finalDemand;
  }


  // Calcul du facteur saisonnier
  double _calculateSeasonalityFactor() {
    DateTime now = DateTime.now();
    switch (now.month) {
      case 12: // Décembre, période de fêtes
      case 1:  // Janvier
        return 1.2;
      case 7:  // Juillet, période creuse
      case 8:
        return 0.8;
      default:
        return 1.0;
    }
  }

  // Pression concurrentielle
  double _calculateCompetitivePressure() {
    return _random.nextDouble() * 0.2; // 0-20% de pression
  }

  double _calculateHistoricalElasticityModifier() {
    if (salesHistory.isEmpty) return 0;
    int recentSales = salesHistory.length;
    return log(recentSales + 1) * 0.1;
  }

  // Enregistrement d'une vente avec mise à jour de la réputation
  void recordSale(int quantity, double price) {
    final sale = SaleRecord(
      timestamp: DateTime.now(),
      quantity: quantity,
      price: price,
      revenue: quantity * price,
    );

    salesHistory.add(sale);

    // Limiter l'historique des ventes
    if (salesHistory.length > 100) {
      salesHistory.removeAt(0);
    }

    updateReputation(price, quantity);
  }

  // Mise à jour de la réputation avec une logique plus nuancée
  void updateReputation(double price, int satisfiedCustomers) {
    // Impact du prix sur la réputation
    double priceImpact = price <= 0.35 ? 0.02 : -0.01;

    // Impact de la satisfaction client
    double customerSatisfactionImpact = satisfiedCustomers * 0.001;

    reputation = (reputation + priceImpact + customerSatisfactionImpact).clamp(0.0, 2.0);
  }

  // Mise à jour du marché
  void updateMarket() {
    dynamics.updateMarketConditions();
  }

  // Génération d'événements de marché
  MarketEventType? generateMarketEvent() {
    // 10% de chance d'un événement
    if (_random.nextDouble() < 0.1) {
      return MarketEventType.values[_random.nextInt(MarketEventType.values.length)];
    }
    return null;
  }

  // Calcul de l'ajustement historique de l'élasticité


  // Recommandation de prix
  double recommendPricing(double currentPrice, double demand) {
    double adjustmentFactor = 1 + ((demand - 50) / 100);
    return currentPrice * adjustmentFactor;
  }
}