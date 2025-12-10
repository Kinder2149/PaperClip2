import 'package:flutter/foundation.dart';

class StatisticsManager with ChangeNotifier {
  // Statistiques de production
  int _totalPaperclipsProduced = 0;
  double _totalMetalUsed = 0.0;
  int _manualPaperclipsProduced = 0;
  int _autoPaperclipsProduced = 0;
  
  // Statistiques économiques
  double _totalMoneyEarned = 0.0;
  double _totalMoneySpent = 0.0;
  double _peakMoneyPerMinute = 0.0;
  double _currentMoneyPerMinute = 0.0;
  double _lastMinuteEarnings = 0.0;
  DateTime _lastEarningsUpdate = DateTime.now();
  
  // Statistiques de ressources
  double _totalMetalPurchased = 0.0;
  double _totalIronMined = 0.0;
  double _totalCoalMined = 0.0;
  double _totalElectricityProduced = 0.0;
  double _totalSteelProduced = 0.0;
  
  // Statistiques temporelles
  DateTime _gameStartTime = DateTime.now();
  int _totalGameTimeSec = 0;
  
  // Getters
  int get totalPaperclipsProduced => _totalPaperclipsProduced;
  double get totalMetalUsed => _totalMetalUsed;
  int get manualPaperclipsProduced => _manualPaperclipsProduced;
  int get autoPaperclipsProduced => _autoPaperclipsProduced;
  
  double get totalMoneyEarned => _totalMoneyEarned;
  double get totalMoneySpent => _totalMoneySpent;
  double get peakMoneyPerMinute => _peakMoneyPerMinute;
  double get currentMoneyPerMinute => _currentMoneyPerMinute;
  
  double get totalMetalPurchased => _totalMetalPurchased;
  double get totalIronMined => _totalIronMined;
  double get totalCoalMined => _totalCoalMined;
  double get totalElectricityProduced => _totalElectricityProduced;
  double get totalSteelProduced => _totalSteelProduced;
  
  DateTime get gameStartTime => _gameStartTime;
  int get totalGameTimeSec => _totalGameTimeSec;
  int get totalPlayTimeSeconds => _totalGameTimeSec; // Alias pour compatibilité
  
  // Méthodes de mise à jour
  /// Méthode principale de mise à jour de la production.
  ///
  /// Compatible à la fois avec l'ancien appel
  ///   updateProduction(paperclipsProduced: ..., metalUsed: ..., isAuto: ...)
  /// et les nouveaux appels depuis GameState utilisant
  ///   updateProduction(isManual: ..., amount: ..., metalUsed: ..., metalSaved: ..., efficiency: ...)
  void updateProduction({
    int paperclipsProduced = 0,
    double metalUsed = 0.0,
    bool isAuto = false,
    // Paramètres de compatibilité
    bool isManual = false,
    int amount = 0,
    double metalSaved = 0.0,
    double efficiency = 0.0,
  }) {
    // Déterminer combien de trombones ont réellement été produits
    final int produced = (paperclipsProduced != 0) ? paperclipsProduced : amount;

    _totalPaperclipsProduced += produced;
    _totalMetalUsed += metalUsed;

    // Répartir entre manuel / auto en gardant un comportement raisonnable
    if (isAuto && !isManual) {
      _autoPaperclipsProduced += produced;
    } else if (isManual && !isAuto) {
      _manualPaperclipsProduced += produced;
    } else {
      // Si l'information n'est pas claire, on compte tout en auto par défaut
      _autoPaperclipsProduced += produced;
    }

    notifyListeners();
  }
  
  /// Mise à jour économique.
  ///
  /// Compatible avec les signatures
  ///   updateEconomics(moneyEarned: ..., moneySpent: ...)
  ///   updateEconomics(moneyEarned: ..., sales: ..., price: ...)
  ///   updateEconomics(moneySpent: ..., metalBought: ...)
  void updateEconomics({
    double moneyEarned = 0.0,
    double moneySpent = 0.0,
    // Paramètres de compatibilité supplémentaires (actuellement ignorés)
    int sales = 0,
    double price = 0.0,
    double metalBought = 0.0,
  }) {
    _totalMoneyEarned += moneyEarned;
    _totalMoneySpent += moneySpent;
    
    // Mettre à jour les statistiques de revenus par minute
    final now = DateTime.now();
    final timeDiff = now.difference(_lastEarningsUpdate).inMilliseconds / 1000; // en secondes
    
    if (moneyEarned > 0 && timeDiff > 0) {
      _lastMinuteEarnings += moneyEarned;
      
      // Si une minute s'est écoulée, mettre à jour les statistiques par minute
      if (timeDiff >= 60) {
        // Calculer le taux par minute
        _currentMoneyPerMinute = (_lastMinuteEarnings * 60) / timeDiff;
        
        // Vérifier s'il s'agit d'un nouveau pic
        if (_currentMoneyPerMinute > _peakMoneyPerMinute) {
          _peakMoneyPerMinute = _currentMoneyPerMinute;
        }
        
        // Réinitialiser pour la prochaine minute
        _lastMinuteEarnings = 0;
        _lastEarningsUpdate = now;
      }
    }
    
    notifyListeners();
  }
  
  void updateResources({
    double metalPurchased = 0.0,
    double ironMined = 0.0,
    double coalMined = 0.0,
    double electricityProduced = 0.0,
    double steelProduced = 0.0,
  }) {
    _totalMetalPurchased += metalPurchased;
    _totalIronMined += ironMined;
    _totalCoalMined += coalMined;
    _totalElectricityProduced += electricityProduced;
    _totalSteelProduced += steelProduced;
    
    notifyListeners();
  }
  
  void updateGameTime(int additionalSeconds) {
    _totalGameTimeSec += additionalSeconds;
    notifyListeners();
  }
  
  void setGameStartTime(DateTime startTime) {
    _gameStartTime = startTime;
    notifyListeners();
  }
  
  // Méthode pour charger les données sauvegardées
  void loadFromJson(Map<String, dynamic> json) {
    try {
      _totalPaperclipsProduced = json['totalPaperclipsProduced'] ?? _totalPaperclipsProduced;
      _totalMetalUsed = json['totalMetalUsed']?.toDouble() ?? _totalMetalUsed;
      _manualPaperclipsProduced = json['manualPaperclipsProduced'] ?? _manualPaperclipsProduced;
      _autoPaperclipsProduced = json['autoPaperclipsProduced'] ?? _autoPaperclipsProduced;
      
      _totalMoneyEarned = json['totalMoneyEarned']?.toDouble() ?? _totalMoneyEarned;
      _totalMoneySpent = json['totalMoneySpent']?.toDouble() ?? _totalMoneySpent;
      _peakMoneyPerMinute = json['peakMoneyPerMinute']?.toDouble() ?? _peakMoneyPerMinute;
      _currentMoneyPerMinute = json['currentMoneyPerMinute']?.toDouble() ?? _currentMoneyPerMinute;
      
      _totalMetalPurchased = json['totalMetalPurchased']?.toDouble() ?? _totalMetalPurchased;
      _totalIronMined = json['totalIronMined']?.toDouble() ?? _totalIronMined;
      _totalCoalMined = json['totalCoalMined']?.toDouble() ?? _totalCoalMined;
      _totalElectricityProduced = json['totalElectricityProduced']?.toDouble() ?? _totalElectricityProduced;
      _totalSteelProduced = json['totalSteelProduced']?.toDouble() ?? _totalSteelProduced;
      
      _totalGameTimeSec = json['totalGameTimeSec'] ?? _totalGameTimeSec;
      
      // Convertir la date si elle existe
      if (json.containsKey('gameStartTime')) {
        try {
          _gameStartTime = DateTime.parse(json['gameStartTime']);
        } catch (e) {
          if (kDebugMode) {
            print('Erreur de conversion de la date de début de jeu: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erreur lors du chargement des données statistiques: $e');
      }
    }
  }
  
  // Méthode pour convertir en JSON pour la sauvegarde
  Map<String, dynamic> toJson() {
    return {
      'totalPaperclipsProduced': _totalPaperclipsProduced,
      'totalMetalUsed': _totalMetalUsed,
      'manualPaperclipsProduced': _manualPaperclipsProduced,
      'autoPaperclipsProduced': _autoPaperclipsProduced,
      
      'totalMoneyEarned': _totalMoneyEarned,
      'totalMoneySpent': _totalMoneySpent,
      'peakMoneyPerMinute': _peakMoneyPerMinute,
      'currentMoneyPerMinute': _currentMoneyPerMinute,
      
      'totalMetalPurchased': _totalMetalPurchased,
      'totalIronMined': _totalIronMined,
      'totalCoalMined': _totalCoalMined,
      'totalElectricityProduced': _totalElectricityProduced,
      'totalSteelProduced': _totalSteelProduced,
      
      'gameStartTime': _gameStartTime.toIso8601String(),
      'totalGameTimeSec': _totalGameTimeSec,
    };
  }
  
  // Récupérer toutes les statistiques dans un format structuré
  Map<String, Map<String, dynamic>> getAllStats() {
    return {
      'production': {
        'totalPaperclipsProduced': _totalPaperclipsProduced,
        'totalMetalUsed': _totalMetalUsed,
        'manualPaperclipsProduced': _manualPaperclipsProduced,
        'autoPaperclipsProduced': _autoPaperclipsProduced,
        'efficiency': _totalPaperclipsProduced > 0 ? _totalMetalUsed / _totalPaperclipsProduced : 0,
      },
      'economy': {
        'totalMoneyEarned': _totalMoneyEarned,
        'totalMoneySpent': _totalMoneySpent,
        'netProfit': _totalMoneyEarned - _totalMoneySpent,
        'peakMoneyPerMinute': _peakMoneyPerMinute,
        'currentMoneyPerMinute': _currentMoneyPerMinute,
      },
      'resources': {
        'totalMetalPurchased': _totalMetalPurchased,
        'totalIronMined': _totalIronMined,
        'totalCoalMined': _totalCoalMined,
        'totalElectricityProduced': _totalElectricityProduced,
        'totalSteelProduced': _totalSteelProduced,
      },
      'time': {
        'gameStartTime': _gameStartTime.toIso8601String(),
        'totalGameTimeSec': _totalGameTimeSec,
        'totalGameTimeFormatted': _formatTime(_totalGameTimeSec),
      },
    };
  }
  
  // Méthode pour formater le temps
  String _formatTime(int seconds) {
    final int h = seconds ~/ 3600;
    final int m = (seconds % 3600) ~/ 60;
    final int s = seconds % 60;
    
    final String hStr = h > 0 ? '${h}h ' : '';
    final String mStr = m > 0 ? '${m}m ' : '';
    final String sStr = '${s}s';
    
    return '$hStr$mStr$sStr';
  }
  
  // Méthode spécifique pour récupérer le total d'argent gagné
  double getTotalMoneyEarned() {
    return _totalMoneyEarned;
  }
  
  // Alias de compatibilité pour GameState
  double getTotalMetalUsed() {
    return _totalMetalUsed;
  }
  
  // Mise à jour des statistiques de progression
  void updateProgression({
    int upgradesBought = 0,
    int levelGained = 0,
    int missionCompleted = 0,
    int achievementsUnlocked = 0,
    // Compatibilité : nombre d'autoclippers achetés (actuellement ignoré)
    int autoclippersBought = 0,
  }) {
    // Cette méthode pourrait enregistrer des statistiques de progression
    // qui pourraient être utilisées pour des récompenses ou des réalisations
    
    // Pour l'instant, on notifie simplement les écouteurs
    notifyListeners();
  }
  
  // Alias de compatibilité: certaines anciennes méthodes appelaient fromJson()
  void fromJson(Map<String, dynamic> json) {
    loadFromJson(json);
  }
}
