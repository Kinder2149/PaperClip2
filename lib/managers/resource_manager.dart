// lib/managers/resource_manager.dart
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../constants/game_config.dart' show GameConstants; // Import explicite de la classe GameConstants
import '../models/json_loadable.dart';
import 'player_manager.dart';
import 'market_manager.dart';

/// Manager responsable de la gestion des ressources et des actions liées à ces ressources
class ResourceManager extends ChangeNotifier implements JsonLoadable {
  late PlayerManager _playerManager;
  late MarketManager _marketManager;
  
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
  
  /// Fabrique un trombone manuellement
  bool producePaperclip() {
    if (_playerManager.metal >= _metalToClipRatio) {
      double newPaperclips = _playerManager.paperclips + 1;
      
      // Vérification de l'espace de stockage
      if (newPaperclips > _maxPaperclipStorage) {
        return false; // Stockage plein
      }
      
      // Mise à jour des ressources
      _playerManager.updateMetal(_playerManager.metal - _metalToClipRatio);
      _playerManager.updatePaperclips(newPaperclips);
      return true;
    }
    return false;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers producePaperclip
  bool makePaperclip() {
    return producePaperclip();
  }
  
  /// Acheter du métal (anciennement buyWire)
  bool purchaseMetal([double? customPrice]) {
    double metalPrice = _marketManager.marketMetalPrice;
    double amount = GameConstants.METAL_PACK_AMOUNT;
    double price = customPrice ?? (amount * metalPrice);
    
    if (_playerManager.money < price) {
      return false; // Pas assez d'argent
    }
    
    if (_playerManager.metal + amount > _playerManager.maxMetalStorage) {
      return false; // Stockage insuffisant
    }
    
    _playerManager.updateMoney(_playerManager.money - price);
    _playerManager.updateMetal(_playerManager.metal + amount);
    
    return true;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers purchaseMetal
  bool buyMetal([double? customPrice]) {
    return purchaseMetal(customPrice);
  }
  
  /// Mise à jour du ratio métal/trombone en fonction du niveau d'efficacité
  void updateMetalToClipRatio() {
    _metalToClipRatio = GameConstants.METAL_PER_PAPERCLIP * (1 - (_playerManager.efficiencyUpgradeLevel * 0.05));
    if (_metalToClipRatio < 0.01) {
      _metalToClipRatio = 0.01; // Minimum de métal requis par trombone
    }
    notifyListeners();
  }
  
  /// Mise à jour de l'efficacité du métal pour la production
  void updateMetalEfficiency(double efficiency) {
    _metalEfficiency = efficiency;
    notifyListeners();
  }
  
  /// Mise à jour de la capacité de stockage de trombones
  void updatePaperclipStorageCapacity() {
    int storageLevel = _playerManager.storageUpgradeLevel;
    _maxPaperclipStorage = GameConstants.INITIAL_STORAGE_CAPACITY * pow(GameConstants.STORAGE_MULTIPLIER, storageLevel);
    notifyListeners();
  }
  
  /// Alias de compatibilité: ancien nom utilisé par GameState
  void upgradeStorageCapacity(int storageLevel) {
    // Le niveau est déjà stocké dans PlayerManager, on se contente de recalculer
    updatePaperclipStorageCapacity();
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
    
    return true;
  }
  
  /// Consommation du métal pour produire des trombones
  bool consumeMetal(double amount) {
    if (amount <= 0) return false;
    
    double currentMetal = _playerManager.metal;
    if (currentMetal < amount) return false;
    
    _playerManager.updateMetal(currentMetal - amount);
    return true;
  }
  
  /// Calcul la quantité de trombones pouvant être produits avec le métal disponible
  int calculatePossibleClips() {
    // Si pas de métal, impossible de fabriquer
    if (_playerManager.metal <= 0) return 0;
    
    // Calculer combien de trombones peuvent être fabriqués avec le métal disponible
    int possibleFromMetal = (_playerManager.metal / _metalEfficiency).floor();
    
    return possibleFromMetal;
  }
  
  /// Calculer la consommation de métal pour un nombre de trombones
  double calculateMetalConsumption(int clipCount) {
    return clipCount * _metalEfficiency;
  }
  
  // Méthode calculateWireConsumption supprimée - migration wire vers metal complète
  
  /// Produire des trombones en consommant le métal
  bool produceClips(int clipCount) {
    if (clipCount <= 0) return false;
    
    // Vérifier si on peut produire autant de trombones
    int possibleClips = calculatePossibleClips();
    if (clipCount > possibleClips) {
      clipCount = possibleClips;
      if (clipCount <= 0) return false;
    }
    
    // Consommer le métal
    double metalNeeded = clipCount * _metalEfficiency;
    
    _playerManager.updateMetal(_playerManager.metal - metalNeeded);
    
    // Mettre à jour les trombones du joueur
    _playerManager.updatePaperclips(_playerManager.paperclips + clipCount);
    
    notifyListeners();
    return true;
  }
  
  /// Méthode de rétrocompatibilité qui redirige vers produceClips
  bool addClips(int clipCount) {
    return produceClips(clipCount);
  }
  
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
