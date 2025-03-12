import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

/// Classe pour enregistrer les ventes
class SaleRecord {
  final DateTime timestamp;
  final int quantity;
  final double price;
  final double revenue;

  SaleRecord({
    required this.timestamp,
    required this.quantity,
    required this.price,
    required this.revenue,
  });
  
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'quantity': quantity,
    'price': price,
    'revenue': revenue,
  };

  factory SaleRecord.fromJson(Map<String, dynamic> json) {
    return SaleRecord(
      timestamp: DateTime.parse(json['timestamp']),
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}

/// Classe pour représenter un segment de marché
class MarketSegment {
  final String id;
  final String name;
  final double elasticity;
  final double maxPrice;
  final double marketShare;
  double currentDemand;

  MarketSegment({
    required this.id,
    required this.name,
    required this.elasticity,
    required this.maxPrice,
    required this.marketShare,
    this.currentDemand = 1.0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'elasticity': elasticity,
    'maxPrice': maxPrice,
    'marketShare': marketShare,
    'currentDemand': currentDemand,
  };

  factory MarketSegment.fromJson(Map<String, dynamic> json) {
    return MarketSegment(
      id: json['id'],
      name: json['name'],
      elasticity: (json['elasticity'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      marketShare: (json['marketShare'] as num).toDouble(),
      currentDemand: (json['currentDemand'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

/// Classe pour gérer la dynamique du marché
class MarketDynamics {
  double marketVolatility = 1.0;
  double marketTrend = 0.0;
  double competitorPressure = 1.0;
  double globalDemand = 1.0;
  
  MarketDynamics({
    this.marketVolatility = 1.0,
    this.marketTrend = 0.0,
    this.competitorPressure = 1.0,
    this.globalDemand = 1.0,
  });

  Map<String, dynamic> toJson() => {
    'marketVolatility': marketVolatility,
    'marketTrend': marketTrend,
    'competitorPressure': competitorPressure,
    'globalDemand': globalDemand,
  };

  void fromJson(Map<String, dynamic> json) {
    marketVolatility = (json['marketVolatility'] as num?)?.toDouble() ?? 1.0;
    marketTrend = (json['marketTrend'] as num?)?.toDouble() ?? 0.0;
    competitorPressure = (json['competitorPressure'] as num?)?.toDouble() ?? 1.0;
    globalDemand = (json['globalDemand'] as num?)?.toDouble() ?? 1.0;
  }

  void updateMarketConditions() {
    // Simuler des changements aléatoires dans les conditions du marché
    marketVolatility = 0.8 + (Random().nextDouble() * 0.4);
    marketTrend = -0.2 + (Random().nextDouble() * 0.4);
    competitorPressure = 0.9 + (Random().nextDouble() * 0.2);
    
    // Ajuster la demande globale
    double demandChange = -0.05 + (Random().nextDouble() * 0.1);
    globalDemand = (globalDemand + demandChange).clamp(0.5, 1.5);
  }

  double getMarketConditionMultiplier() {
    return marketVolatility * (1 + marketTrend) * competitorPressure * globalDemand;
  }
}

/// Gestionnaire centralisé pour le marché
class MarketSystem extends ChangeNotifier {
  // Propriétés du marché
  final MarketDynamics _dynamics;
  final List<MarketSegment> _segments = [];
  final List<SaleRecord> _salesHistory = [];
  
  // Propriétés de prix
  double _basePaperclipPrice = GameConstants.INITIAL_PAPERCLIP_PRICE;
  double _marketingMultiplier = 1.0;
  double _negotiationMultiplier = 1.0;
  
  // Statistiques
  int _totalSales = 0;
  double _totalRevenue = 0.0;
  
  // Getters
  MarketDynamics get dynamics => _dynamics;
  List<MarketSegment> get segments => _segments;
  List<SaleRecord> get salesHistory => _salesHistory;
  double get basePaperclipPrice => _basePaperclipPrice;
  double get marketingMultiplier => _marketingMultiplier;
  double get negotiationMultiplier => _negotiationMultiplier;
  int get totalSales => _totalSales;
  double get totalRevenue => _totalRevenue;
  
  // Calculs dérivés
  double get currentMarketMultiplier => _dynamics.getMarketConditionMultiplier();
  double get effectivePaperclipPrice => _basePaperclipPrice * _marketingMultiplier * _negotiationMultiplier * currentMarketMultiplier;
  
  // Constructeur
  MarketSystem({MarketDynamics? dynamics}) : _dynamics = dynamics ?? MarketDynamics() {
    _initialize();
  }
  
  void _initialize() {
    _createMarketSegments();
    _basePaperclipPrice = GameConstants.INITIAL_PAPERCLIP_PRICE;
    _marketingMultiplier = 1.0;
    _negotiationMultiplier = 1.0;
    _totalSales = 0;
    _totalRevenue = 0.0;
    _salesHistory.clear();
  }
  
  void _createMarketSegments() {
    _segments.clear();
    
    // Segments de marché prédéfinis
    _segments.add(MarketSegment(
      id: 'consumer',
      name: 'Consommateurs',
      elasticity: 1.2,
      maxPrice: 2.0,
      marketShare: 0.5,
    ));
    
    _segments.add(MarketSegment(
      id: 'business',
      name: 'Entreprises',
      elasticity: 0.8,
      maxPrice: 3.0,
      marketShare: 0.3,
    ));
    
    _segments.add(MarketSegment(
      id: 'premium',
      name: 'Premium',
      elasticity: 0.5,
      maxPrice: 5.0,
      marketShare: 0.2,
    ));
  }
  
  // Mettre à jour le marché (appelé périodiquement)
  void updateMarket() {
    // Mettre à jour les conditions du marché
    _dynamics.updateMarketConditions();
    
    // Mettre à jour la demande pour chaque segment
    for (var segment in _segments) {
      double demandChange = -0.05 + (Random().nextDouble() * 0.1);
      segment.currentDemand = (segment.currentDemand + demandChange).clamp(0.5, 1.5);
    }
    
    notifyListeners();
  }
  
  // Calculer la demande actuelle
  int calculateDemand(double price, double qualityMultiplier) {
    int totalDemand = 0;
    
    for (var segment in _segments) {
      // Calculer l'élasticité-prix pour ce segment
      double priceRatio = price / (segment.maxPrice * qualityMultiplier);
      double segmentDemand = segment.marketShare * segment.currentDemand;
      
      if (priceRatio < 1.0) {
        // Prix inférieur au maximum, bonne demande
        segmentDemand *= (1.0 - (priceRatio * segment.elasticity));
      } else {
        // Prix supérieur au maximum, demande réduite
        segmentDemand *= (1.0 / (priceRatio * segment.elasticity * 2));
      }
      
      // Convertir en nombre entier de trombones demandés
      int segmentPaperclips = (segmentDemand * 100 * _dynamics.globalDemand).round();
      totalDemand += segmentPaperclips;
    }
    
    return max(totalDemand, 1); // Au moins 1 trombone demandé
  }
  
  // Vendre des trombones
  SaleRecord sellPaperclips(int quantity, double price, double qualityMultiplier) {
    if (quantity <= 0) {
      return SaleRecord(
        timestamp: DateTime.now(),
        quantity: 0,
        price: price,
        revenue: 0,
      );
    }
    
    // Calculer la demande actuelle
    int demand = calculateDemand(price, qualityMultiplier);
    
    // Limiter les ventes à la demande
    int actualSales = min(quantity, demand);
    double revenue = actualSales * price;
    
    // Enregistrer la vente
    SaleRecord record = SaleRecord(
      timestamp: DateTime.now(),
      quantity: actualSales,
      price: price,
      revenue: revenue,
    );
    
    _salesHistory.add(record);
    if (_salesHistory.length > 100) {
      _salesHistory.removeAt(0); // Limiter l'historique à 100 entrées
    }
    
    // Mettre à jour les statistiques
    _totalSales += actualSales;
    _totalRevenue += revenue;
    
    notifyListeners();
    return record;
  }
  
  // Améliorer le marketing
  void upgradeMarketing(double multiplier) {
    _marketingMultiplier *= multiplier;
    
    // Augmenter la demande globale
    _dynamics.globalDemand *= 1.1;
    
    notifyListeners();
  }
  
  // Améliorer les compétences de négociation
  void upgradeNegotiation(double multiplier) {
    _negotiationMultiplier *= multiplier;
    notifyListeners();
  }
  
  // Obtenir les statistiques de vente récentes
  Map<String, dynamic> getRecentSalesStats() {
    if (_salesHistory.isEmpty) {
      return {
        'averagePrice': 0.0,
        'totalQuantity': 0,
        'totalRevenue': 0.0,
        'averageQuantityPerSale': 0.0,
      };
    }
    
    // Limiter aux 10 dernières ventes
    List<SaleRecord> recentSales = _salesHistory.length > 10
        ? _salesHistory.sublist(_salesHistory.length - 10)
        : _salesHistory;
    
    double totalPrice = 0.0;
    int totalQuantity = 0;
    double totalRevenue = 0.0;
    
    for (var sale in recentSales) {
      totalPrice += sale.price * sale.quantity;
      totalQuantity += sale.quantity;
      totalRevenue += sale.revenue;
    }
    
    return {
      'averagePrice': totalQuantity > 0 ? totalPrice / totalQuantity : 0.0,
      'totalQuantity': totalQuantity,
      'totalRevenue': totalRevenue,
      'averageQuantityPerSale': recentSales.isNotEmpty ? totalQuantity / recentSales.length : 0.0,
    };
  }
  
  // Réinitialiser le système de marché
  void reset() {
    _initialize();
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'dynamics': _dynamics.toJson(),
    'segments': _segments.map((segment) => segment.toJson()).toList(),
    'salesHistory': _salesHistory.map((sale) => sale.toJson()).toList(),
    'basePaperclipPrice': _basePaperclipPrice,
    'marketingMultiplier': _marketingMultiplier,
    'negotiationMultiplier': _negotiationMultiplier,
    'totalSales': _totalSales,
    'totalRevenue': _totalRevenue,
  };
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    _dynamics.fromJson(json['dynamics'] ?? {});
    
    _segments.clear();
    if (json['segments'] != null) {
      for (var segmentJson in json['segments']) {
        _segments.add(MarketSegment.fromJson(segmentJson));
      }
    } else {
      _createMarketSegments();
    }
    
    _salesHistory.clear();
    if (json['salesHistory'] != null) {
      for (var saleJson in json['salesHistory']) {
        _salesHistory.add(SaleRecord.fromJson(saleJson));
      }
    }
    
    _basePaperclipPrice = (json['basePaperclipPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_PAPERCLIP_PRICE;
    _marketingMultiplier = (json['marketingMultiplier'] as num?)?.toDouble() ?? 1.0;
    _negotiationMultiplier = (json['negotiationMultiplier'] as num?)?.toDouble() ?? 1.0;
    _totalSales = json['totalSales'] ?? 0;
    _totalRevenue = (json['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    
    notifyListeners();
  }
} 