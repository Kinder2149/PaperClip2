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
  double get wireToClipRatio => _metalToClipRatio; // Rétrocompatibilité
  double get clipPerSecond => _clipPerSecond;
  bool get metalPurchaseEnabled => _metalPurchaseEnabled;
  bool get wirePurchaseEnabled => _metalPurchaseEnabled; // Rétrocompatibilité
  double get maxPaperclipStorage => _maxPaperclipStorage;
  bool get metalPurchaseAutomated => _metalPurchaseAutomated;
  bool get wirePurchaseAutomated => _metalPurchaseAutomated; // Rétrocompatibilité
  double get metalAutoBuyLevel => _metalAutoBuyLevel;
  double get wireAutoBuyLevel => _metalAutoBuyLevel; // Rétrocompatibilité
  double get clipSpeed => _clipSpeed;
  double get metalEfficiency => _metalEfficiency;
  
  // Getters qui délèguent au PlayerManager
  double get metal => _playerManager.metal;
  double get wire => _playerManager.metal; // Rétrocompatibilité
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
  
  /// Méthode de rétrocompatibilité qui redirige vers purchaseMetal
  bool buyMetal([double? customPrice]) {
    return purchaseMetal(customPrice);
  }
  
  /// Mise à jour du ratio métal/trombone en fonction du niveau d'efficacité
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la production et ses ratios relèvent de ProductionManager/PlayerManager. Ne pas utiliser. (No-op)'
  )
  void updateMetalToClipRatio() {
    // No-op : hors contrat. Conservé pour compatibilité.
  }
  
  /// Mise à jour de l'efficacité du métal pour la production
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la production et son efficacité relèvent de ProductionManager/PlayerManager. Ne pas utiliser. (No-op)'
  )
  void updateMetalEfficiency(double efficiency) {
    // No-op : hors contrat. Conservé pour compatibilité.
  }
  
  /// Mise à jour de la capacité de stockage de trombones
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la capacité de stockage effective est gérée par PlayerManager. Ne pas utiliser. (No-op)'
  )
  void updatePaperclipStorageCapacity() {
    // No-op : hors contrat. Conservé pour compatibilité.
  }
  
  /// Alias de compatibilité: ancien nom utilisé par GameState
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la capacité de stockage effective est gérée par PlayerManager. Conservé uniquement pour compatibilité. (No-op)'
  )
  void upgradeStorageCapacity(int storageLevel) {
    // No-op : hors contrat. Conservé pour compatibilité.
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
  
  /// Achat d'une quantité spécifique de métal depuis le marché
  @Deprecated(
    'Legacy (réduction ciblée): préférer purchaseMetal() comme point d’entrée. Conservé pour compatibilité.'
  )
  bool purchaseSpecificMetalAmount(double amount, PlayerManager playerManager, MarketManager marketManager) {
    if (amount <= 0) return false;
    
    // Vérification des limites
    double currentMetal = _playerManager.metal;
    double maxCapacity = _playerManager.maxMetalStorage;
    double metalPrice = _marketManager.marketMetalPrice;
    
    // Vérification du stock sur le marché
    if (amount > _marketManager.marketMetalStock) {
      return false;
    }
    
    // Vérification de la capacité de stockage
    if (currentMetal + amount > maxCapacity) {
      return false;
    }
    
    // Vérification de l'argent disponible
    double cost = amount * metalPrice;
    if (_playerManager.money < cost) {
      return false;
    }
    
    // Achat effectif
    _playerManager.updateMetal(currentMetal + amount);
    _playerManager.updateMoney(_playerManager.money - cost);
    _marketManager.updateMarketStock(_marketManager.marketMetalStock - amount);

    // Mise à jour centralisée des statistiques si disponible
    if (_statistics != null) {
      _statistics!.updateEconomics(moneySpent: cost);
      _statistics!.updateResources(metalPurchased: amount);
    }
    
    return true;
  }
  
  /// Consommation du métal pour produire des trombones
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la consommation de métal pour production est gérée par ProductionManager/PlayerManager. Conservé pour compatibilité.'
  )
  bool consumeMetal(double amount) {
    // Compatibilité: ne doit plus être utilisé. On évite cependant un crash runtime.
    return false;
  }
  
  /// Calcul la quantité de trombones pouvant être produits avec le métal disponible
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la production relève de ProductionManager. Ne pas utiliser. (Retour par défaut)'
  )
  int calculatePossibleClips() {
    // Compatibilité: ne doit plus être utilisé. On évite cependant un crash runtime.
    return 0;
  }
  
  /// Calculer la consommation de métal pour un nombre de trombones
  @Deprecated(
    'Hors contrat ResourceManager (réduction ciblée): la consommation relève de ProductionManager. Ne pas utiliser. (Retour par défaut)'
  )
  double calculateMetalConsumption(int clipCount) {
    // Compatibilité: ne doit plus être utilisé. On évite cependant un crash runtime.
    return 0.0;
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
    // Charger les valeurs avec rétrocompatibilité pour les anciennes clés 'wire'
    // Les anciennes clés sont conservées pour la compatibilité avec les sauvegardes existantes
    _metalToClipRatio = (json['metalToClipRatio'] as num?)?.toDouble() ?? 
                    // Fallback pour les anciennes sauvegardes utilisant 'wire'
                    (json['wireToClipRatio'] as num?)?.toDouble() ?? 
                    GameConstants.METAL_PER_PAPERCLIP;
                    
    _clipPerSecond = (json['clipPerSecond'] as num?)?.toDouble() ?? 0.0;
    
    _metalPurchaseEnabled = json['metalPurchaseEnabled'] as bool? ?? 
                       // Fallback pour les anciennes sauvegardes utilisant 'wire'
                       json['wirePurchaseEnabled'] as bool? ?? 
                       false;
                       
    _maxPaperclipStorage = (json['maxPaperclipStorage'] as num?)?.toDouble() ?? 
                      GameConstants.INITIAL_STORAGE_CAPACITY;
                      
    _metalPurchaseAutomated = json['metalPurchaseAutomated'] as bool? ?? 
                         // Fallback pour les anciennes sauvegardes utilisant 'wire'
                         json['wirePurchaseAutomated'] as bool? ?? 
                         false;
                         
    _metalAutoBuyLevel = (json['metalAutoBuyLevel'] as num?)?.toDouble() ?? 
                    // Fallback pour les anciennes sauvegardes utilisant 'wire'
                    (json['wireAutoBuyLevel'] as num?)?.toDouble() ?? 
                    0.0;
    notifyListeners();
  }
}
