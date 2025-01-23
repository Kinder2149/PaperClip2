import 'dart:math';
import '../game_enums.dart';
import '../constants.dart';
import '../event_manager.dart';
import 'market_dynamics.dart';
import 'sale_record.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
  int _gameStartDay = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
  double _difficultyMultiplier = GameConstants.BASE_DIFFICULTY;
  double _currentMetalPrice = GameConstants.MIN_METAL_PRICE;


  static const double MARKET_DEPLETION_THRESHOLD = 750.0;

  static const double MIN_PRICE = GameConstants.MIN_PRICE;
  static const double MAX_PRICE = GameConstants.MAX_PRICE;

  MarketManager(this.dynamics);
  double _currentPrice = 1.0;
  double _competitionPrice = GameConstants.INITIAL_PRICE;
  double _marketSaturation = 100.0;
  Map<String, MarketSegment> _segments = {
    'budget': MarketSegment('Budget', -2.0, 0.25, 0.4),
    'standard': MarketSegment('Standard', -1.5, 0.50, 0.4),
    'premium': MarketSegment('Premium', -1.0, 1.00, 0.2),
  };
  double updateMetalPrice() {
    dynamics.updateMarketConditions();
    double variation = (Random().nextDouble() * 4) - 2;
    _currentMetalPrice = (_currentMetalPrice + variation)
        .clamp(GameConstants.MIN_METAL_PRICE, GameConstants.MAX_METAL_PRICE);
    return _currentMetalPrice;
  }

  double getCurrentPrice() {
    return _currentMetalPrice;
  }

  bool isPriceExcessive(double price) {
    return price > _currentMetalPrice * 2;
  }

  String getPriceRecommendation() {
    return "Prix recommandé : ${(_currentMetalPrice * 1.5).toStringAsFixed(2)}";
  }






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
    if (price <= 0.25) return -1.0;
    if (price <= 0.50) return -2.0;
    return -3.0;
  }

  double _calculateBaseDemand(double price) {
    double elasticity;

    if (price <= GameConstants.OPTIMAL_PRICE_LOW) {
      // Forte demande mais faible marge
      elasticity = -1.0;
    } else if (price <= GameConstants.OPTIMAL_PRICE_HIGH) {
      // Zone optimale
      elasticity = -1.5;
    } else if (price <= GameConstants.MAX_PRICE) {
      // Demande réduite
      elasticity = -2.0;
    } else {
      // Prix excessif
      elasticity = -3.0;
    }

    return _marketSaturation * exp(elasticity * (price / GameConstants.OPTIMAL_PRICE_LOW));
  }
  double _calculateReputationFactor(double price) {
    return max(0.1, 1.0 - (price - 0.25) * 0.5) * reputation;
  }

  double _calculateCompetitionFactor(double price) {
    return max(0.1, 1.0 - (price / _competitionPrice - 1.0));
  }




  // Calcul de la demande de base
  double calculateDemand(double price, int marketingLevel) {
    _updateDifficultyMultiplier();

    double baseDemand = _calculateBaseDemand(price);
    double reputationFactor = _calculateReputationImpact(price);
    double difficultyFactor = _calculateDifficultyFactor();
    double marketingFactor = 1.0 + (marketingLevel * 0.2);

    double finalDemand = baseDemand *
        reputationFactor *
        difficultyFactor *
        marketingFactor;

    // Appliquer les limites
    return max(0, min(finalDemand, _marketSaturation));
  }
  double _calculateReputationImpact(double price) {
    if (price > GameConstants.MAX_PRICE) {
      // Pénalité pour prix excessif
      reputation *= GameConstants.REPUTATION_PENALTY_RATE;
    } else if (price <= GameConstants.OPTIMAL_PRICE_HIGH) {
      // Bonus pour prix raisonnable
      reputation = min(
          GameConstants.MAX_REPUTATION,
          reputation * GameConstants.REPUTATION_BONUS_RATE
      );
    }

    return max(GameConstants.MIN_REPUTATION, reputation);
  }

  double _calculateDifficultyFactor() {
    return 1.0 / _difficultyMultiplier;
  }
  void _updateDifficultyMultiplier() {
    int currentDay = DateTime.now().millisecondsSinceEpoch ~/ (1000 * 60 * 60 * 24);
    int monthsPassed = (currentDay - _gameStartDay) ~/ 30;
    _difficultyMultiplier = GameConstants.BASE_DIFFICULTY +
        (monthsPassed * GameConstants.DIFFICULTY_INCREASE_PER_MONTH);
  }




  // Ajouter ces méthodes dans la classe MarketManager
  String _getEventTitle(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        return "Guerre des Prix!";
      case MarketEvent.DEMAND_SPIKE:
        return "Pic de Demande!";
      case MarketEvent.MARKET_CRASH:
        return "Krach du Marché!";
      case MarketEvent.QUALITY_CONCERNS:
        return "Problèmes de Qualité";
    }
  }

  String _getEventDescription(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        return "Les concurrents baissent leurs prix agressivement";
      case MarketEvent.DEMAND_SPIKE:
        return "La demande en trombones explose!";
      case MarketEvent.MARKET_CRASH:
        return "Le marché s'effondre, les prix chutent";
      case MarketEvent.QUALITY_CONCERNS:
        return "Des inquiétudes sur la qualité affectent la réputation";
    }
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
  void updateMarketConditions() {
    // Mise à jour du prix de la concurrence
    _competitionPrice = GameConstants.INITIAL_PRICE *
        (0.8 + Random().nextDouble() * 0.4);

    // Mise à jour de la saturation du marché
    _marketSaturation = max(50, _marketSaturation +
        (Random().nextDouble() - 0.5) * 10);

    // Possibilité d'événement de marché
    _checkForMarketEvent();
  }

  void _checkForMarketEvent() {
    if (Random().nextDouble() < 0.05) { // 5% de chance
      final event = MarketEvent.values[
      Random().nextInt(MarketEvent.values.length)
      ];
      _handleMarketEvent(event);
    }
  }

  void _handleMarketEvent(MarketEvent event) {
    switch (event) {
      case MarketEvent.PRICE_WAR:
        _competitionPrice *= 0.8;
        break;
      case MarketEvent.DEMAND_SPIKE:
        _marketSaturation *= 1.5;
        break;
      case MarketEvent.MARKET_CRASH:
        _competitionPrice *= 0.6;
        _marketSaturation *= 0.7;
        break;
      case MarketEvent.QUALITY_CONCERNS:
        reputation *= 0.9;
        break;
    }

    // Notifier l'événement
    EventManager.addEvent(
        EventType.MARKET_CHANGE,
        _getEventTitle(event),
        description: _getEventDescription(event),
        importance: EventImportance.MEDIUM
    );
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