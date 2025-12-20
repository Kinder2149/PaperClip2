// lib/managers/resource_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart' show GameConstants; // Import explicite de la classe GameConstants
import '../models/json_loadable.dart';
import 'player_manager.dart';
import 'market_manager.dart';
import '../models/statistics_manager.dart';

/// Manager responsable de la gestion des ressources et des actions liées à ces ressources
class ResourceManager extends ChangeNotifier implements JsonLoadable {
  late PlayerManager _playerManager;
  late MarketManager _marketManager;
  StatisticsManager? _statistics;
  
  // États des ressources
  double _metalToClipRatio = GameConstants.METAL_PER_PAPERCLIP; // Métal nécessaire par trombone
  double _clipPerSecond = 0.0; // Vitesse de production
  bool _metalPurchaseEnabled = false; // Autorisation d'achat de métal
  // Ancienne capacité de stockage de fil fusionnée avec la capacité de stockage de métal
  double _maxPaperclipStorage = 1000.0; // Capacité max de stockage de trombones
  bool _metalPurchaseAutomated = false; // Automatisation de l'achat de métal
  double _metalAutoBuyLevel = 0.0; // Niveau d'achat auto de métal
  // Ancienne efficacité de fil fusionnée avec l'efficacité du métal
  double _metalEfficiency = GameConstants.BASE_EFFICIENCY; // Efficacité du métal par trombone
  double _clipSpeed = GameConstants.BASE_EFFICIENCY; // Vitesse de production
  
  // Getters
  double get metalToClipRatio => _metalToClipRatio;
  double get clipPerSecond => _clipPerSecond;
  bool get metalPurchaseEnabled => _metalPurchaseEnabled;
  double get maxPaperclipStorage => _maxPaperclipStorage;
  bool get metalPurchaseAutomated => _metalPurchaseAutomated;
  double get metalAutoBuyLevel => _metalAutoBuyLevel;
  double get clipSpeed => _clipSpeed;
  double get metalEfficiency => _metalEfficiency;
  
  // Getters qui délèguent au PlayerManager
  double get metal => _playerManager.metal;
  double get maxStorageCapacity => _playerManager.maxMetalStorage;
  double get maxClips => _maxPaperclipStorage;
  
  // Getter qui délègue au MarketManager
  double get marketMetalStock => _marketManager.marketMetalStock;
  
  // Constructeur
  ResourceManager() {
    _clipPerSecond = 0.0;
    _metalPurchaseEnabled = false;
    _maxPaperclipStorage = 1000.0; // En attendant l'ajout de la constante INITIAL_MAX_PAPERCLIPS
  }
  
  /// Configure le PlayerManager associé
  void setPlayerManager(PlayerManager playerManager) {
    _playerManager = playerManager;
  }
  
  /// Configure le MarketManager associé
  void setMarketManager(MarketManager marketManager) {
    _marketManager = marketManager;
  }

  /// Configure le StatisticsManager associé pour la centralisation des métriques
  void setStatisticsManager(StatisticsManager statisticsManager) {
    _statistics = statisticsManager;
  }

  bool canPurchaseMetal([double? customPrice]) {
    final double metalPrice = _marketManager.marketMetalPrice;
    final double amount = GameConstants.METAL_PACK_AMOUNT;
    final double price = customPrice ?? (amount * metalPrice);

    if (_playerManager.money < price) {
      return false;
    }

    if (_playerManager.metal + amount > _playerManager.maxMetalStorage) {
      return false;
    }

    if (_marketManager.marketMetalStock < amount) {
      return false;
    }

    return true;
  }
  
  /// Acheter du métal (anciennement buyWire)
  bool purchaseMetal([double? customPrice]) {
    final double metalPrice = _marketManager.marketMetalPrice;
    final double amount = GameConstants.METAL_PACK_AMOUNT;
    final double price = customPrice ?? (amount * metalPrice);

    if (!canPurchaseMetal(customPrice)) {
      return false;
    }

    _playerManager.updateMoney(_playerManager.money - price);
    _playerManager.updateMetal(_playerManager.metal + amount);
    _marketManager.updateMarketStock(_marketManager.marketMetalStock - amount);

    // Mise à jour centralisée des statistiques si disponible
    if (_statistics != null) {
      _statistics!.updateEconomics(moneySpent: price);
      _statistics!.updateResources(metalPurchased: amount);
    }
    
    return true;
  }
  
  /// Réinitialisation des ressources
  void resetResources() {
    _metalToClipRatio = GameConstants.METAL_PER_PAPERCLIP;
    _clipPerSecond = 0.0;
    _metalPurchaseEnabled = false;
    _maxPaperclipStorage = 1000.0;
    _metalPurchaseAutomated = false;
    _metalAutoBuyLevel = 0.0;
    notifyListeners();
  }
  
  // Méthode calculateWireConsumption supprimée - migration wire vers metal complète
  
  /// Sérialisation en JSON
  @override
  Map<String, dynamic> toJson() => {
    'metalToClipRatio': _metalToClipRatio,
    'clipPerSecond': _clipPerSecond,
    'metalPurchaseEnabled': _metalPurchaseEnabled,
    'maxPaperclipStorage': _maxPaperclipStorage,
    'metalPurchaseAutomated': _metalPurchaseAutomated,
    'metalAutoBuyLevel': _metalAutoBuyLevel,
  };
  
  /// Désérialisation depuis JSON
  @override
  void fromJson(Map<String, dynamic> json) {
    _metalToClipRatio = (json['metalToClipRatio'] as num?)?.toDouble() ?? 
                    GameConstants.METAL_PER_PAPERCLIP;
                    
    _clipPerSecond = (json['clipPerSecond'] as num?)?.toDouble() ?? 0.0;
    
    _metalPurchaseEnabled = json['metalPurchaseEnabled'] as bool? ?? false;
                       
    _maxPaperclipStorage = (json['maxPaperclipStorage'] as num?)?.toDouble() ?? 
                      GameConstants.INITIAL_STORAGE_CAPACITY;
                      
    _metalPurchaseAutomated = json['metalPurchaseAutomated'] as bool? ?? false;
                         
    _metalAutoBuyLevel = (json['metalAutoBuyLevel'] as num?)?.toDouble() ?? 0.0;
    notifyListeners();
  }
}
