import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

/// Gestionnaire centralisé pour les ressources métalliques
class MetalManager extends ChangeNotifier {
  // Propriétés de stockage
  double _playerMetal = 0.0;
  double _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY;
  double _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY;
  
  // Propriétés du marché
  double _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
  double _marketMetalPrice = GameConstants.INITIAL_METAL_PRICE;
  double _marketPriceVolatility = 1.0;
  
  // Propriétés d'acquisition
  double _metalAcquisitionRate = 1.0;
  double _metalAcquisitionEfficiency = 1.0;
  
  // Getters
  double get playerMetal => _playerMetal;
  double get metalStorageCapacity => _metalStorageCapacity;
  double get baseStorageEfficiency => _baseStorageEfficiency;
  double get marketMetalStock => _marketMetalStock;
  double get marketMetalPrice => _marketMetalPrice;
  double get marketPriceVolatility => _marketPriceVolatility;
  double get metalAcquisitionRate => _metalAcquisitionRate;
  double get metalAcquisitionEfficiency => _metalAcquisitionEfficiency;
  
  // Calculs dérivés
  double get effectiveStorageCapacity => _metalStorageCapacity * _baseStorageEfficiency;
  double get storageUtilizationPercentage => (_playerMetal / effectiveStorageCapacity) * 100;
  bool get isStorageFull => _playerMetal >= effectiveStorageCapacity;
  
  // Constructeur
  MetalManager() {
    _initialize();
  }
  
  void _initialize() {
    _playerMetal = 0.0;
    _metalStorageCapacity = GameConstants.INITIAL_STORAGE_CAPACITY;
    _baseStorageEfficiency = GameConstants.BASE_EFFICIENCY;
    _marketMetalStock = GameConstants.INITIAL_MARKET_METAL;
    _marketMetalPrice = GameConstants.INITIAL_METAL_PRICE;
    _marketPriceVolatility = 1.0;
    _metalAcquisitionRate = 1.0;
    _metalAcquisitionEfficiency = 1.0;
  }
  
  // Méthodes de gestion du métal
  
  // Ajouter du métal au stockage du joueur
  bool addMetal(double amount) {
    if (amount <= 0) return false;
    
    // Vérifier la capacité de stockage
    double newTotal = _playerMetal + amount;
    if (newTotal > effectiveStorageCapacity) {
      _playerMetal = effectiveStorageCapacity;
      notifyListeners();
      return false; // Stockage plein
    }
    
    _playerMetal = newTotal;
    notifyListeners();
    return true;
  }
  
  // Consommer du métal
  bool consumeMetal(double amount) {
    if (amount <= 0) return false;
    if (_playerMetal < amount) return false;
    
    _playerMetal -= amount;
    notifyListeners();
    return true;
  }
  
  // Acheter du métal sur le marché
  bool buyMetalFromMarket(double amount, double playerMoney) {
    if (amount <= 0) return false;
    if (_marketMetalStock < amount) return false;
    
    double cost = amount * _marketMetalPrice;
    if (playerMoney < cost) return false;
    
    // Vérifier la capacité de stockage
    double newTotal = _playerMetal + amount;
    if (newTotal > effectiveStorageCapacity) {
      return false; // Stockage plein
    }
    
    // Mettre à jour le stock du marché
    _marketMetalStock -= amount;
    _playerMetal += amount;
    
    // Ajuster le prix du marché en fonction de la demande
    _adjustMarketPrice(amount, true);
    
    notifyListeners();
    return true;
  }
  
  // Vendre du métal sur le marché
  double sellMetalToMarket(double amount) {
    if (amount <= 0) return 0;
    if (_playerMetal < amount) amount = _playerMetal;
    
    double revenue = amount * _marketMetalPrice;
    
    _playerMetal -= amount;
    _marketMetalStock += amount;
    
    // Ajuster le prix du marché en fonction de l'offre
    _adjustMarketPrice(amount, false);
    
    notifyListeners();
    return revenue;
  }
  
  // Ajuster le prix du marché en fonction de l'offre et de la demande
  void _adjustMarketPrice(double amount, bool isBuying) {
    double marketImpact = amount / GameConstants.INITIAL_MARKET_METAL;
    double priceChange = marketImpact * _marketPriceVolatility;
    
    if (isBuying) {
      // L'achat augmente le prix
      _marketMetalPrice *= (1 + priceChange);
    } else {
      // La vente diminue le prix
      _marketMetalPrice *= (1 - priceChange);
    }
    
    // Limiter le prix à des valeurs raisonnables
    _marketMetalPrice = _marketMetalPrice.clamp(
      GameConstants.MIN_METAL_PRICE,
      GameConstants.MAX_METAL_PRICE
    );
  }
  
  // Mettre à jour le marché (appelé périodiquement)
  void updateMarket() {
    // Simuler les fluctuations naturelles du marché
    double randomFactor = 0.95 + (Random().nextDouble() * 0.1);
    _marketMetalPrice *= randomFactor;
    
    // Restaurer progressivement le stock du marché
    if (_marketMetalStock < GameConstants.INITIAL_MARKET_METAL) {
      double restoration = GameConstants.INITIAL_MARKET_METAL * 0.01;
      _marketMetalStock = min(_marketMetalStock + restoration, GameConstants.INITIAL_MARKET_METAL);
    }
    
    // Limiter le prix à des valeurs raisonnables
    _marketMetalPrice = _marketMetalPrice.clamp(
      GameConstants.MIN_METAL_PRICE,
      GameConstants.MAX_METAL_PRICE
    );
    
    notifyListeners();
  }
  
  // Améliorer la capacité de stockage
  void upgradeStorageCapacity(double multiplier) {
    _metalStorageCapacity *= multiplier;
    notifyListeners();
  }
  
  // Améliorer l'efficacité du stockage
  void upgradeStorageEfficiency(double multiplier) {
    _baseStorageEfficiency *= multiplier;
    notifyListeners();
  }
  
  // Améliorer le taux d'acquisition de métal
  void upgradeAcquisitionRate(double multiplier) {
    _metalAcquisitionRate *= multiplier;
    notifyListeners();
  }
  
  // Améliorer l'efficacité d'acquisition de métal
  void upgradeAcquisitionEfficiency(double multiplier) {
    _metalAcquisitionEfficiency *= multiplier;
    notifyListeners();
  }
  
  // Réinitialiser le gestionnaire
  void reset() {
    _initialize();
    notifyListeners();
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'playerMetal': _playerMetal,
    'metalStorageCapacity': _metalStorageCapacity,
    'baseStorageEfficiency': _baseStorageEfficiency,
    'marketMetalStock': _marketMetalStock,
    'marketMetalPrice': _marketMetalPrice,
    'marketPriceVolatility': _marketPriceVolatility,
    'metalAcquisitionRate': _metalAcquisitionRate,
    'metalAcquisitionEfficiency': _metalAcquisitionEfficiency,
  };
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    _playerMetal = (json['playerMetal'] as num?)?.toDouble() ?? 0.0;
    _metalStorageCapacity = (json['metalStorageCapacity'] as num?)?.toDouble() ?? GameConstants.INITIAL_STORAGE_CAPACITY;
    _baseStorageEfficiency = (json['baseStorageEfficiency'] as num?)?.toDouble() ?? GameConstants.BASE_EFFICIENCY;
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_METAL;
    _marketMetalPrice = (json['marketMetalPrice'] as num?)?.toDouble() ?? GameConstants.INITIAL_METAL_PRICE;
    _marketPriceVolatility = (json['marketPriceVolatility'] as num?)?.toDouble() ?? 1.0;
    _metalAcquisitionRate = (json['metalAcquisitionRate'] as num?)?.toDouble() ?? 1.0;
    _metalAcquisitionEfficiency = (json['metalAcquisitionEfficiency'] as num?)?.toDouble() ?? 1.0;
    
    notifyListeners();
  }
} 