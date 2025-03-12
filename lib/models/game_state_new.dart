import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

// Import des composants principaux
import 'paperclip_manager.dart';
import 'metal_manager.dart';
import 'upgrade_system.dart';
import 'market_system.dart';
import 'player_progression_system.dart';
import 'event_system.dart';
import 'game_config.dart';

// Import des services
import '../services/save_manager.dart';
import '../services/auto_save_service.dart';
import '../services/games_services_controller.dart';

/// Classe principale qui gère l'état du jeu
class GameState extends ChangeNotifier {
  // Composants principaux
  late final PaperclipManager _paperclipManager;
  late final MetalManager _metalManager;
  late final UpgradeSystem _upgradeSystem;
  late final MarketSystem _marketSystem;
  late final PlayerProgressionSystem _progressionSystem;
  late final EventManager _eventManager;
  
  // Services
  late final AutoSaveService _autoSaveService;
  
  // État du jeu
  bool _isInitialized = false;
  String? _gameName;
  GameMode _gameMode = GameMode.INFINITE;
  DateTime? _gameStartTime;
  DateTime? _competitiveStartTime;
  DateTime _lastUpdateTime = DateTime.now();
  bool _isPaused = false;
  double _money = GameConstants.INITIAL_MONEY;
  
  // Timers
  Timer? _gameLoopTimer;
  
  // Getters
  bool get isInitialized => _isInitialized;
  String? get gameName => _gameName;
  GameMode get gameMode => _gameMode;
  DateTime? get gameStartTime => _gameStartTime;
  DateTime? get competitiveStartTime => _competitiveStartTime;
  bool get isPaused => _isPaused;
  double get money => _money;
  
  // Getters pour les composants
  PaperclipManager get paperclipManager => _paperclipManager;
  MetalManager get metalManager => _metalManager;
  UpgradeSystem get upgradeSystem => _upgradeSystem;
  MarketSystem get marketSystem => _marketSystem;
  PlayerProgressionSystem get progressionSystem => _progressionSystem;
  EventManager get eventManager => _eventManager;
  
  // Constructeur
  GameState() {
    _initializeComponents();
  }
  
  void _initializeComponents() {
    if (!_isInitialized) {
      // Initialiser les composants
      _paperclipManager = PaperclipManager();
      _metalManager = MetalManager();
      _upgradeSystem = UpgradeSystem();
      _marketSystem = MarketSystem();
      _progressionSystem = PlayerProgressionSystem();
      _eventManager = EventManager.instance;
      
      // Initialiser les services
      _autoSaveService = AutoSaveService(this);
      
      // Configurer les événements
      _setupEventListeners();
      
      // Démarrer le jeu
      _startGameLoop();
      
      _isInitialized = true;
    }
  }
  
  void _setupEventListeners() {
    // Écouter les événements importants
    _eventManager.on('mission_completed', _handleMissionCompleted);
    _eventManager.on('upgrade_purchased', _handleUpgradePurchased);
    _eventManager.on('paperclip_produced', _handlePaperclipProduced);
    _eventManager.on('paperclip_sold', _handlePaperclipSold);
    _eventManager.on('metal_purchased', _handleMetalPurchased);
  }
  
  // Gestionnaires d'événements
  void _handleMissionCompleted(Map<String, dynamic> data) {
    if (data.containsKey('rewards')) {
      Map<String, dynamic> rewards = data['rewards'];
      
      // Appliquer les récompenses
      if (rewards.containsKey('money')) {
        _money += (rewards['money'] as num).toDouble();
      }
      
      if (rewards.containsKey('experience')) {
        _progressionSystem.addExperience(rewards['experience']);
      }
    }
  }
  
  void _handleUpgradePurchased(Map<String, dynamic> data) {
    if (data.containsKey('id') && data.containsKey('cost')) {
      String id = data['id'];
      double cost = (data['cost'] as num).toDouble();
      
      // Mettre à jour les statistiques
      _progressionSystem.updateStat('upgrades_purchased', 1);
      
      // Appliquer les effets de l'amélioration
      _applyUpgradeEffects(id);
    }
  }
  
  void _handlePaperclipProduced(Map<String, dynamic> data) {
    if (data.containsKey('amount')) {
      int amount = data['amount'];
      
      // Mettre à jour les statistiques
      _progressionSystem.updateStat('paperclips_produced', amount);
    }
  }
  
  void _handlePaperclipSold(Map<String, dynamic> data) {
    if (data.containsKey('amount') && data.containsKey('revenue')) {
      int amount = data['amount'];
      double revenue = (data['revenue'] as num).toDouble();
      
      // Mettre à jour les statistiques
      _progressionSystem.updateStat('paperclips_sold', amount);
      _progressionSystem.updateStat('total_money_earned', revenue);
      
      // Ajouter l'argent
      _money += revenue;
    }
  }
  
  void _handleMetalPurchased(Map<String, dynamic> data) {
    if (data.containsKey('amount') && data.containsKey('cost')) {
      double amount = (data['amount'] as num).toDouble();
      double cost = (data['cost'] as num).toDouble();
      
      // Mettre à jour les statistiques
      _progressionSystem.updateStat('metal_purchased', amount);
      _progressionSystem.updateStat('market_transactions', 1);
      
      // Soustraire l'argent
      _money -= cost;
    }
  }
  
  // Appliquer les effets d'une amélioration
  void _applyUpgradeEffects(String upgradeId) {
    switch (upgradeId) {
      case 'production_efficiency':
        _paperclipManager.upgradeEfficiency(1.2);
        break;
      case 'production_speed':
        _paperclipManager.upgradeProductionRate(1.5);
        break;
      case 'production_quality':
        _paperclipManager.upgradeQuality(1.3);
        break;
      case 'storage_capacity':
        _metalManager.upgradeStorageCapacity(1.5);
        break;
      case 'storage_efficiency':
        _metalManager.upgradeStorageEfficiency(1.2);
        break;
      case 'market_intelligence':
        // Améliorer la visibilité du marché
        break;
      case 'market_negotiation':
        _marketSystem.upgradeNegotiation(1.2);
        break;
      case 'automation_basic':
        _paperclipManager.enableAutomation();
        break;
      case 'automation_speed':
        _paperclipManager.upgradeAutomation(1.5);
        break;
      case 'special_marketing':
        _marketSystem.upgradeMarketing(1.3);
        break;
    }
  }
  
  // Boucle de jeu principale
  void _startGameLoop() {
    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(Duration(milliseconds: 100), _gameLoop);
  }
  
  void _gameLoop(Timer timer) {
    if (_isPaused) return;
    
    // Calculer le temps écoulé depuis la dernière mise à jour
    DateTime now = DateTime.now();
    double deltaTime = now.difference(_lastUpdateTime).inMilliseconds / 1000.0;
    _lastUpdateTime = now;
    
    // Mettre à jour le temps de jeu
    _progressionSystem.updateStat('play_time_seconds', deltaTime);
    
    // Production automatique
    if (_paperclipManager.isAutomated) {
      int produced = _paperclipManager.produceAutomatically(
        _metalManager,
        _metalManager.playerMetal,
        deltaTime
      );
      
      if (produced > 0) {
        // Consommer le métal
        double metalUsed = produced * _paperclipManager.effectiveMetalPerPaperclip;
        _metalManager.consumeMetal(metalUsed);
        _progressionSystem.updateStat('metal_used', metalUsed);
        
        // Notifier la production
        _eventManager.emit('paperclip_produced', {'amount': produced});
      }
    }
    
    // Mettre à jour le marché périodiquement (toutes les 2 secondes)
    static const marketUpdateInterval = 2.0; // secondes
    static double timeSinceLastMarketUpdate = 0.0;
    
    timeSinceLastMarketUpdate += deltaTime;
    if (timeSinceLastMarketUpdate >= marketUpdateInterval) {
      _marketSystem.updateMarket();
      timeSinceLastMarketUpdate = 0.0;
    }
  }
  
  // Actions du joueur
  
  // Produire un trombone manuellement
  bool produceManually() {
    if (_metalManager.playerMetal < _paperclipManager.effectiveMetalPerPaperclip) {
      return false;
    }
    
    bool success = _paperclipManager.produceManually(_metalManager, _metalManager.playerMetal);
    
    if (success) {
      // Consommer le métal
      double metalUsed = _paperclipManager.effectiveMetalPerPaperclip;
      _metalManager.consumeMetal(metalUsed);
      _progressionSystem.updateStat('metal_used', metalUsed);
      
      // Notifier la production
      _eventManager.emit('paperclip_produced', {'amount': 1});
    }
    
    return success;
  }
  
  // Vendre des trombones
  bool sellPaperclips(int amount) {
    if (amount <= 0 || _paperclipManager.paperclipsInInventory < amount) {
      return false;
    }
    
    // Vendre les trombones
    int sold = _paperclipManager.sellPaperclips(amount);
    
    if (sold > 0) {
      // Calculer le prix de vente
      double price = _paperclipManager.currentPrice;
      
      // Enregistrer la vente sur le marché
      var saleRecord = _marketSystem.sellPaperclips(
        sold,
        price,
        _paperclipManager.productionQuality
      );
      
      // Notifier la vente
      _eventManager.emit('paperclip_sold', {
        'amount': sold,
        'revenue': saleRecord.revenue,
        'price': price
      });
      
      return true;
    }
    
    return false;
  }
  
  // Acheter du métal
  bool buyMetal(double amount) {
    if (amount <= 0) return false;
    
    // Calculer le coût
    double cost = amount * _metalManager.marketMetalPrice;
    
    if (_money < cost) return false;
    
    // Acheter le métal
    bool success = _metalManager.buyMetalFromMarket(amount, _money);
    
    if (success) {
      // Notifier l'achat
      _eventManager.emit('metal_purchased', {
        'amount': amount,
        'cost': cost
      });
      
      return true;
    }
    
    return false;
  }
  
  // Acheter une amélioration
  bool purchaseUpgrade(String id) {
    Upgrade? upgrade = _upgradeSystem.getUpgrade(id);
    if (upgrade == null) return false;
    
    double cost = upgrade.getCost();
    if (_money < cost) return false;
    
    bool success = _upgradeSystem.purchaseUpgrade(id, _money);
    
    if (success) {
      // Soustraire l'argent
      _money -= cost;
      
      // Notifier l'achat
      _eventManager.emit('upgrade_purchased', {
        'id': id,
        'cost': cost,
        'level': upgrade.level
      });
      
      return true;
    }
    
    return false;
  }
  
  // Gestion du jeu
  
  // Démarrer une nouvelle partie
  Future<void> startNewGame(String name, {GameMode mode = GameMode.INFINITE}) async {
    // Réinitialiser tous les composants
    _paperclipManager.reset();
    _metalManager.reset();
    _upgradeSystem.reset();
    _marketSystem.reset();
    _progressionSystem.reset();
    
    // Configurer la nouvelle partie
    _gameName = name;
    _gameMode = mode;
    _gameStartTime = DateTime.now();
    _money = GameConstants.INITIAL_MONEY;
    
    if (mode == GameMode.COMPETITIVE) {
      _competitiveStartTime = DateTime.now();
    } else {
      _competitiveStartTime = null;
    }
    
    // Démarrer la boucle de jeu
    _isPaused = false;
    _startGameLoop();
    
    // Initialiser l'autosave
    _autoSaveService.initialize();
    
    notifyListeners();
  }
  
  // Mettre le jeu en pause
  void pauseGame() {
    _isPaused = true;
    notifyListeners();
  }
  
  // Reprendre le jeu
  void resumeGame() {
    _isPaused = false;
    _lastUpdateTime = DateTime.now(); // Réinitialiser pour éviter les sauts
    notifyListeners();
  }
  
  // Sauvegarder le jeu
  Future<bool> saveGame() async {
    try {
      Map<String, dynamic> gameData = toJson();
      
      // Utiliser SaveManager pour sauvegarder
      await SaveManager.saveGame(SaveGame(
        name: _gameName ?? 'Unnamed Game',
        data: gameData,
        timestamp: DateTime.now(),
        gameMode: _gameMode,
      ));
      
      return true;
    } catch (e) {
      print('Erreur lors de la sauvegarde: $e');
      return false;
    }
  }
  
  // Charger une partie
  Future<bool> loadGame(String name) async {
    try {
      // Utiliser SaveManager pour charger
      SaveGame? saveGame = await SaveManager.loadGame(name);
      
      if (saveGame != null) {
        fromJson(saveGame.data);
        _gameName = saveGame.name;
        _gameMode = saveGame.gameMode;
        
        // Redémarrer la boucle de jeu
        _isPaused = false;
        _lastUpdateTime = DateTime.now();
        _startGameLoop();
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur lors du chargement: $e');
      return false;
    }
  }
  
  // Sérialisation
  Map<String, dynamic> toJson() => {
    'gameName': _gameName,
    'gameMode': _gameMode.toString(),
    'gameStartTime': _gameStartTime?.toIso8601String(),
    'competitiveStartTime': _competitiveStartTime?.toIso8601String(),
    'money': _money,
    'paperclipManager': _paperclipManager.toJson(),
    'metalManager': _metalManager.toJson(),
    'upgradeSystem': _upgradeSystem.toJson(),
    'marketSystem': _marketSystem.toJson(),
    'progressionSystem': _progressionSystem.toJson(),
  };
  
  // Désérialisation
  void fromJson(Map<String, dynamic> json) {
    _gameName = json['gameName'];
    _gameMode = json['gameMode'] == 'GameMode.COMPETITIVE'
        ? GameMode.COMPETITIVE
        : GameMode.INFINITE;
    
    _gameStartTime = json['gameStartTime'] != null
        ? DateTime.parse(json['gameStartTime'])
        : DateTime.now();
    
    _competitiveStartTime = json['competitiveStartTime'] != null
        ? DateTime.parse(json['competitiveStartTime'])
        : null;
    
    _money = (json['money'] as num?)?.toDouble() ?? GameConstants.INITIAL_MONEY;
    
    // Charger les composants
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
    
    notifyListeners();
  }
  
  // Nettoyage
  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    super.dispose();
  }
} 