import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// Import de l'ancien GameState
import 'game_state.dart';

// Import des nouveaux composants
import 'paperclip_manager.dart';
import 'metal_manager.dart';
import 'upgrade_system.dart';
import 'market_system.dart';
import 'player_progression_system.dart';

/// Classe de transition qui hérite de l'ancien GameState et utilise les nouveaux composants
/// Cette classe permet une migration progressive vers la nouvelle architecture
class GameStateTransition extends GameState {
  // Nouveaux composants
  late final PaperclipManager _paperclipManager;
  late final MetalManager _metalManager;
  late final UpgradeSystem _upgradeSystem;
  late final MarketSystem _marketSystem;
  late final PlayerProgressionSystem _progressionSystem;
  
  // Getters pour les nouveaux composants
  PaperclipManager get paperclipManager => _paperclipManager;
  MetalManager get metalManager => _metalManager;
  UpgradeSystem get upgradeSystem => _upgradeSystem;
  MarketSystem get marketSystem => _marketSystem;
  PlayerProgressionSystem get progressionSystem => _progressionSystem;
  
  // Constructeur
  GameStateTransition() : super() {
    _initializeNewComponents();
    _syncComponentsWithOldState();
  }
  
  // Initialiser les nouveaux composants
  void _initializeNewComponents() {
    _paperclipManager = PaperclipManager();
    _metalManager = MetalManager();
    _upgradeSystem = UpgradeSystem();
    _marketSystem = MarketSystem();
    _progressionSystem = PlayerProgressionSystem();
  }
  
  // Synchroniser les nouveaux composants avec l'état actuel
  void _syncComponentsWithOldState() {
    // Synchroniser PaperclipManager
    _paperclipManager.fromJson({
      'totalPaperclipsProduced': totalPaperclipsProduced,
      'paperclipsInInventory': 0, // À adapter selon votre logique actuelle
      'productionRate': 1.0, // À adapter selon votre logique actuelle
      'productionEfficiency': 1.0, // À adapter selon votre logique actuelle
      'productionQuality': 1.0, // À adapter selon votre logique actuelle
      'metalPerPaperclip': 1.0, // À adapter selon votre logique actuelle
      'isAutomated': false, // À adapter selon votre logique actuelle
      'automationSpeed': 1.0, // À adapter selon votre logique actuelle
      'automationLevel': 0, // À adapter selon votre logique actuelle
      'basePrice': 1.0, // À adapter selon votre logique actuelle
      'priceMultiplier': 1.0, // À adapter selon votre logique actuelle
    });
    
    // Synchroniser MetalManager
    _metalManager.fromJson({
      'playerMetal': resourceManager.marketMetalStock,
      'metalStorageCapacity': resourceManager.metalStorageCapacity,
      'baseStorageEfficiency': resourceManager.baseStorageEfficiency,
      'marketMetalStock': resourceManager.marketMetalStock,
      'marketMetalPrice': 1.0, // À adapter selon votre logique actuelle
      'marketPriceVolatility': 1.0, // À adapter selon votre logique actuelle
      'metalAcquisitionRate': 1.0, // À adapter selon votre logique actuelle
      'metalAcquisitionEfficiency': 1.0, // À adapter selon votre logique actuelle
    });
    
    // Synchroniser UpgradeSystem
    // Cette synchronisation est plus complexe et dépend de votre implémentation actuelle
    // des améliorations. Vous devrez adapter cette partie selon votre logique.
    
    // Synchroniser MarketSystem
    // Cette synchronisation est plus complexe et dépend de votre implémentation actuelle
    // du marché. Vous devrez adapter cette partie selon votre logique.
    
    // Synchroniser PlayerProgressionSystem
    _progressionSystem.fromJson({
      'levelSystem': {
        'level': levelSystem.level,
        'experience': levelSystem.experience,
        'experienceToNextLevel': 100, // Valeur par défaut
      },
      'missionSystem': {}, // À adapter selon votre logique actuelle
      'playerStats': {
        'paperclips_produced': totalPaperclipsProduced,
        'paperclips_sold': 0, // À adapter selon votre logique actuelle
        'total_money_earned': 0.0, // À adapter selon votre logique actuelle
        'upgrades_purchased': 0, // À adapter selon votre logique actuelle
        'play_time_seconds': totalTimePlayed,
        'market_transactions': 0, // À adapter selon votre logique actuelle
        'metal_purchased': 0.0, // À adapter selon votre logique actuelle
        'metal_used': 0.0, // À adapter selon votre logique actuelle
      },
    });
  }
  
  // Surcharge des méthodes de l'ancien GameState pour utiliser les nouveaux composants
  
  // Exemple : Production manuelle de trombones
  @override
  void producePaperclip() {
    // Appeler la méthode de l'ancien GameState
    super.producePaperclip();
    
    // Mettre à jour le nouveau composant
    _paperclipManager.produceManually(resourceManager, resourceManager.marketMetalStock);
    _progressionSystem.updateStat('paperclips_produced', 1);
  }
  
  // Exemple : Achat de métal
  // Nous devons adapter cette méthode car l'ancien GameState n'a pas de paramètre
  void buyMetal(double amount) {
    // Appeler la méthode de l'ancien GameState
    super.buyMetal();
    
    // Mettre à jour le nouveau composant
    _metalManager.buyMetalFromMarket(amount, playerManager.money);
    _progressionSystem.updateStat('metal_purchased', amount);
  }
  
  // Exemple : Achat d'amélioration
  @override
  bool purchaseUpgrade(String id) {
    // Appeler la méthode de l'ancien GameState
    bool success = super.purchaseUpgrade(id);
    
    // Mettre à jour le nouveau composant si l'achat a réussi
    if (success) {
      _upgradeSystem.purchaseUpgrade(id, playerManager.money);
      _progressionSystem.updateStat('upgrades_purchased', 1);
    }
    
    return success;
  }
  
  // Exemple : Vente de trombones
  // Cette méthode n'existe pas dans l'ancien GameState, nous la créons
  void sellPaperclips(int amount) {
    // Logique de vente de trombones
    // À adapter selon votre logique actuelle
    
    // Mettre à jour le nouveau composant
    _paperclipManager.sellPaperclips(amount);
    _progressionSystem.updateStat('paperclips_sold', amount);
  }
  
  // Surcharge de la méthode de sauvegarde pour inclure les nouveaux composants
  // Nous créons cette méthode car l'ancien GameState n'a pas de méthode toJson
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    
    // Ajouter les données des nouveaux composants
    json['paperclipManager'] = _paperclipManager.toJson();
    json['metalManager'] = _metalManager.toJson();
    json['upgradeSystem'] = _upgradeSystem.toJson();
    json['marketSystem'] = _marketSystem.toJson();
    json['progressionSystem'] = _progressionSystem.toJson();
    
    return json;
  }
  
  // Surcharge de la méthode de chargement pour inclure les nouveaux composants
  // Nous créons cette méthode car l'ancien GameState n'a pas de méthode fromJson
  void fromJson(Map<String, dynamic> json) {
    // Charger les données des nouveaux composants
    if (json['paperclipManager'] != null) {
      _paperclipManager.fromJson(json['paperclipManager']);
    }
    
    if (json['metalManager'] != null) {
      _metalManager.fromJson(json['metalManager']);
    }
    
    if (json['upgradeSystem'] != null) {
      _upgradeSystem.fromJson(json['upgradeSystem']);
    }
    
    if (json['marketSystem'] != null) {
      _marketSystem.fromJson(json['marketSystem']);
    }
    
    if (json['progressionSystem'] != null) {
      _progressionSystem.fromJson(json['progressionSystem']);
    }
  }
} 