import 'package:flutter/foundation.dart';
import 'dart:math';
import 'game_config.dart';
import 'event_system.dart';

class ResourceManager extends ChangeNotifier {
  double _metalStorageCapacity;
  double _baseStorageEfficiency;
  double _marketMetalStock;
  double _currentEfficiency;
  double _maintenanceLevel;
  DateTime _lastMaintenanceCheck;
  bool _isMaintenanceActive;

  ResourceManager()
      : _metalStorageCapacity = GameConstants.BASE_STORAGE_CAPACITY,
        _baseStorageEfficiency = 1.0,
        _marketMetalStock = GameConstants.INITIAL_MARKET_STOCK,
        _currentEfficiency = 1.0,
        _maintenanceLevel = 1.0,
        _lastMaintenanceCheck = DateTime.now(),
        _isMaintenanceActive = false;

  // Getters
  double get metalStorageCapacity => _metalStorageCapacity;
  double get baseStorageEfficiency => _baseStorageEfficiency;
  double get marketMetalStock => _marketMetalStock;
  double get currentEfficiency => _currentEfficiency;
  double get maintenanceLevel => _maintenanceLevel;
  bool get isMaintenanceActive => _isMaintenanceActive;

  void upgradeStorageCapacity(int level) {
    _metalStorageCapacity = GameConstants.BASE_STORAGE_CAPACITY *
        pow(GameConstants.STORAGE_UPGRADE_MULTIPLIER, level);
    notifyListeners();
  }

  void updateEfficiency(double newEfficiency) {
    _currentEfficiency = newEfficiency.clamp(
      GameConstants.MIN_STORAGE_EFFICIENCY,
      1.0,
    );
    notifyListeners();
  }

  void setMaintenanceLevel(double level) {
    _maintenanceLevel = level.clamp(0.0, 1.0);
    notifyListeners();
  }

  void toggleMaintenance() {
    _isMaintenanceActive = !_isMaintenanceActive;
    notifyListeners();
  }

  bool checkStorageCapacity(double amount) {
    return amount <= _metalStorageCapacity;
  }

  double calculateEfficiencyLoss() {
    final now = DateTime.now();
    final hoursSinceLastCheck = now.difference(_lastMaintenanceCheck).inHours;
    
    if (hoursSinceLastCheck <= 0) return 0;

    double baseDecay = GameConstants.STORAGE_EFFICIENCY_DECAY * hoursSinceLastCheck;
    double maintenanceEffect = _isMaintenanceActive ? _maintenanceLevel : 0;
    
    return baseDecay * (1 - maintenanceEffect);
  }

  void performMaintenance() {
    if (!_isMaintenanceActive) return;

    final efficiencyLoss = calculateEfficiencyLoss();
    _currentEfficiency = max(
      GameConstants.MIN_STORAGE_EFFICIENCY,
      _currentEfficiency - efficiencyLoss,
    );

    if (_currentEfficiency <= GameConstants.MIN_STORAGE_EFFICIENCY + 0.1) {
      EventManager.instance.addNotification(
        title: 'Alerte Maintenance',
        description: 'L\'efficacité du stockage est critique !',
        icon: Icons.warning,
        priority: NotificationPriority.HIGH,
      );
    }

    _lastMaintenanceCheck = DateTime.now();
    notifyListeners();
  }

  void restoreMarketStock(double amount) {
    _marketMetalStock = min(
      GameConstants.MAX_MARKET_STOCK,
      _marketMetalStock + amount,
    );
    notifyListeners();
  }

  void resetResources() {
    _metalStorageCapacity = GameConstants.BASE_STORAGE_CAPACITY;
    _baseStorageEfficiency = 1.0;
    _marketMetalStock = GameConstants.INITIAL_MARKET_STOCK;
    _currentEfficiency = 1.0;
    _maintenanceLevel = 1.0;
    _lastMaintenanceCheck = DateTime.now();
    _isMaintenanceActive = false;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
    'metalStorageCapacity': _metalStorageCapacity,
    'baseStorageEfficiency': _baseStorageEfficiency,
    'marketMetalStock': _marketMetalStock,
    'currentEfficiency': _currentEfficiency,
    'maintenanceLevel': _maintenanceLevel,
    'lastMaintenanceCheck': _lastMaintenanceCheck.toIso8601String(),
    'isMaintenanceActive': _isMaintenanceActive,
  };

  void fromJson(Map<String, dynamic> json) {
    _metalStorageCapacity = (json['metalStorageCapacity'] as num?)?.toDouble() ?? GameConstants.BASE_STORAGE_CAPACITY;
    _baseStorageEfficiency = (json['baseStorageEfficiency'] as num?)?.toDouble() ?? 1.0;
    _marketMetalStock = (json['marketMetalStock'] as num?)?.toDouble() ?? GameConstants.INITIAL_MARKET_STOCK;
    _currentEfficiency = (json['currentEfficiency'] as num?)?.toDouble() ?? 1.0;
    _maintenanceLevel = (json['maintenanceLevel'] as num?)?.toDouble() ?? 1.0;
    _lastMaintenanceCheck = json['lastMaintenanceCheck'] != null
        ? DateTime.parse(json['lastMaintenanceCheck'] as String)
        : DateTime.now();
    _isMaintenanceActive = json['isMaintenanceActive'] as bool? ?? false;
    notifyListeners();
  }
} 