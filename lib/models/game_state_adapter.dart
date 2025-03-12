import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

// Import de l'ancien GameState
import 'game_state.dart';
import 'game_config.dart'; // Pour GameMode

// Import des nouveaux composants
import 'paperclip_manager.dart';
import 'metal_manager.dart';
import 'upgrade_system.dart';
import 'market_system.dart';
import 'player_progression_system.dart';

/// Classe d'adaptateur qui utilise l'ancien GameState et les nouveaux composants
/// Cette classe permet une migration progressive vers la nouvelle architecture
class GameStateAdapter extends ChangeNotifier {
  // Ancien GameState
  final GameState _oldGameState;
  
  // Nouveaux composants
  late final PaperclipManager _paperclipManager;
  late final MetalManager _metalManager;
  late final UpgradeSystem _upgradeSystem;
  late final MarketSystem _marketSystem;
  late final PlayerProgressionSystem _progressionSystem;
  
  // Getters pour l'ancien GameState
  GameState get oldGameState => _oldGameState;
  
  // Getters pour les nouveaux composants
  PaperclipManager get paperclipManager => _paperclipManager;
  MetalManager get metalManager => _metalManager;
  UpgradeSystem get upgradeSystem => _upgradeSystem;
  MarketSystem get marketSystem => _marketSystem;
  PlayerProgressionSystem get progressionSystem => _progressionSystem;
  
  // Délégation des getters de l'ancien GameState
  int get totalPaperclipsProduced => _oldGameState.totalPaperclipsProduced;
  int get totalTimePlayed => _oldGameState.totalTimePlayed;
  bool get isInCrisisMode => _oldGameState.isInCrisisMode;
  bool get crisisTransitionComplete => _oldGameState.crisisTransitionComplete;
  bool get showingCrisisView => _oldGameState.showingCrisisView;
  DateTime? get crisisStartTime => _oldGameState.crisisStartTime;
  bool get isInitialized => _oldGameState.isInitialized;
  String? get gameName => _oldGameState.gameName;
  GameMode get gameMode => _oldGameState.gameMode;
  DateTime? get competitiveStartTime => _oldGameState.competitiveStartTime;
  Duration get competitivePlayTime => _oldGameState.competitivePlayTime;
  
  // Accès aux managers de l'ancien GameState
  dynamic get playerManager => _oldGameState.playerManager;
  dynamic get marketManager => _oldGameState.marketManager;
  dynamic get resourceManager => _oldGameState.resourceManager;
  dynamic get levelSystem => _oldGameState.levelSystem;
  dynamic get missionSystem => _oldGameState.missionSystem;
  dynamic get statistics => _oldGameState.statistics;
  
  // Constructeur
  GameStateAdapter(this._oldGameState) {
    _initializeNewComponents();
    _syncComponentsWithOldState();
    
    // Écouter les changements de l'ancien GameState
    _oldGameState.addListener(_handleOldGameStateChanged);
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
      'totalPaperclipsProduced': _oldGameState.totalPaperclipsProduced,
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
      'playerMetal': _oldGameState.resourceManager.marketMetalStock,
      'metalStorageCapacity': _oldGameState.resourceManager.metalStorageCapacity,
      'baseStorageEfficiency': _oldGameState.resourceManager.baseStorageEfficiency,
      'marketMetalStock': _oldGameState.resourceManager.marketMetalStock,
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
        'level': _oldGameState.levelSystem.level,
        'experience': _oldGameState.levelSystem.experience,
        'experienceToNextLevel': 100, // Valeur par défaut
      },
      'missionSystem': {}, // À adapter selon votre logique actuelle
      'playerStats': {
        'paperclips_produced': _oldGameState.totalPaperclipsProduced,
        'paperclips_sold': 0, // À adapter selon votre logique actuelle
        'total_money_earned': 0.0, // À adapter selon votre logique actuelle
        'upgrades_purchased': 0, // À adapter selon votre logique actuelle
        'play_time_seconds': _oldGameState.totalTimePlayed,
        'market_transactions': 0, // À adapter selon votre logique actuelle
        'metal_purchased': 0.0, // À adapter selon votre logique actuelle
        'metal_used': 0.0, // À adapter selon votre logique actuelle
      },
    });
  }
  
  // Gérer les changements de l'ancien GameState
  void _handleOldGameStateChanged() {
    // Mettre à jour les nouveaux composants en fonction des changements de l'ancien GameState
    _syncComponentsWithOldState();
    
    // Notifier les écouteurs de cette classe
    notifyListeners();
  }
  
  // Méthodes de délégation vers l'ancien GameState
  
  // Vérifier et restaurer les sauvegardes
  Future<void> checkAndRestoreFromBackup() async {
    await _oldGameState.checkAndRestoreFromBackup();
  }
  
  // Production manuelle de trombones
  void producePaperclip() {
    // Appeler la méthode de l'ancien GameState
    _oldGameState.producePaperclip();
    
    // Mettre à jour le nouveau composant
    _paperclipManager.produceManually(_oldGameState.resourceManager, _oldGameState.resourceManager.marketMetalStock);
    _progressionSystem.updateStat('paperclips_produced', 1);
    
    // Notifier les écouteurs
    notifyListeners();
  }
  
  // Achat de métal
  void buyMetal() {
    // Appeler la méthode de l'ancien GameState
    _oldGameState.buyMetal();
    
    // Mettre à jour le nouveau composant
    double amount = 100; // Valeur par défaut, à adapter selon votre logique
    _metalManager.buyMetalFromMarket(amount, _oldGameState.playerManager.money);
    _progressionSystem.updateStat('metal_purchased', amount);
    
    // Notifier les écouteurs
    notifyListeners();
  }
  
  // Version surchargée pour l'adaptateur
  void buyMetalAmount(double amount) {
    // Appeler la méthode de l'ancien GameState
    _oldGameState.buyMetal();
    
    // Mettre à jour le nouveau composant
    double currentMetal = _metalManager.playerMetal;
    _metalManager.buyMetalFromMarket(amount, _oldGameState.playerManager.money);
    _progressionSystem.updateStat('metal_purchased', amount);
    
    // Synchroniser avec l'ancien état
    _oldGameState.resourceManager.updateMarketStock(amount);
    
    // Notifier les écouteurs
    notifyListeners();
  }
  
  // Achat d'amélioration
  bool purchaseUpgrade(String id) {
    // Vérifier si l'amélioration peut être achetée
    if (!_oldGameState.playerManager.canAffordUpgrade(id)) {
      return false;
    }
    
    // Appeler la méthode de l'ancien GameState
    bool success = _oldGameState.purchaseUpgrade(id);
    
    // Mettre à jour le nouveau composant si l'achat a réussi
    if (success) {
      _upgradeSystem.purchaseUpgrade(id, _oldGameState.playerManager.money);
      _progressionSystem.updateStat('upgrades_purchased', 1);
    }
    
    // Notifier les écouteurs
    notifyListeners();
    
    return success;
  }
  
  // Vente de trombones
  void sellPaperclips(int amount) {
    // Logique de vente de trombones
    // À adapter selon votre logique actuelle
    
    // Mettre à jour le nouveau composant
    _paperclipManager.sellPaperclips(amount);
    _progressionSystem.updateStat('paperclips_sold', amount);
    
    // Notifier les écouteurs
    notifyListeners();
  }
  
  // Démarrer une nouvelle partie
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    await _oldGameState.startNewGame(name, mode: mode);
    _syncComponentsWithOldState();
    notifyListeners();
  }
  
  // Mettre le jeu en pause - Délégation simple
  void pauseGame() {
    // Logique de pause
    notifyListeners();
  }
  
  // Reprendre le jeu - Délégation simple
  void resumeGame() {
    // Logique de reprise
    notifyListeners();
  }
  
  // Sauvegarder le jeu
  Future<bool> saveGame() async {
    // Logique de sauvegarde
    return true;
  }
  
  // Charger une partie
  Future<bool> loadGame(String name) async {
    // Logique de chargement
    _syncComponentsWithOldState();
    notifyListeners();
    return true;
  }
  
  // Sérialisation
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
  
  // Désérialisation
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
    
    // Notifier les écouteurs
    notifyListeners();
  }
  
  // Nettoyage
  @override
  void dispose() {
    // Arrêter d'écouter les changements de l'ancien GameState
    _oldGameState.removeListener(_handleOldGameStateChanged);
    
    super.dispose();
  }
} 