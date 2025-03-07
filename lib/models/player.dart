import 'dart:math' as math;
import 'package:paperclip2/models/interfaces/player_interface.dart';
import 'package:paperclip2/models/interfaces/upgrade_interface.dart';
import 'package:paperclip2/models/constants/game_constants.dart';
import 'package:paperclip2/models/upgrade.dart';

class Player implements IPlayer {
  double _paperclips = 0;
  double _money = 0;
  int _autoclippers = 0;
  double _metal = 0;
  double _maxMetalStorage = GameConstants.BASE_METAL_STORAGE;
  double _sellPrice = GameConstants.MIN_PRICE;
  double _maintenanceCosts = 0;
  final Map<String, IUpgrade> _upgrades = {};

  @override
  double get paperclips => _paperclips;

  @override
  double get money => _money;

  @override
  int get autoclippers => _autoclippers;

  @override
  double get metal => _metal;

  @override
  double get maxMetalStorage => _maxMetalStorage;

  @override
  double get sellPrice => _sellPrice;

  @override
  double get maintenanceCosts => _maintenanceCosts;

  @override
  Map<String, IUpgrade> get upgrades => _upgrades;

  @override
  void addPaperclips(double amount) {
    _paperclips += amount;
  }

  @override
  void spendMoney(double amount) {
    if (_money >= amount) {
      _money -= amount;
    }
  }

  @override
  void addMoney(double amount) {
    _money += amount;
  }

  @override
  void updateMetal(double amount) {
    _metal = amount.clamp(0, _maxMetalStorage);
  }

  @override
  void setSellPrice(double price) {
    _sellPrice = price.clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE);
  }

  @override
  void updateMaintenanceCosts(double costs) {
    _maintenanceCosts = costs;
  }

  @override
  bool purchaseAutoclipper() {
    final cost = _calculateAutoclipperCost();
    if (_money >= cost) {
      _money -= cost;
      _autoclippers++;
      return true;
    }
    return false;
  }

  double _calculateAutoclipperCost() {
    return GameConstants.BASE_AUTOCLIPPER_COST * 
        math.pow(GameConstants.AUTOCLIPPER_COST_MULTIPLIER, _autoclippers);
  }

  @override
  bool purchaseUpgrade(String id) {
    final upgrade = _upgrades[id];
    if (upgrade != null && upgrade.canPurchase(_money.toInt(), 1)) {
      _money -= upgrade.getCost();
      upgrade.incrementLevel();
      return true;
    }
    return false;
  }

  @override
  void addUpgrade(IUpgrade upgrade) {
    _upgrades[upgrade.id] = upgrade;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'paperclips': _paperclips,
      'money': _money,
      'autoclippers': _autoclippers,
      'metal': _metal,
      'maxMetalStorage': _maxMetalStorage,
      'sellPrice': _sellPrice,
      'maintenanceCosts': _maintenanceCosts,
      'upgrades': _upgrades.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    final player = Player();
    player._paperclips = json['paperclips'] as double;
    player._money = json['money'] as double;
    player._autoclippers = json['autoclippers'] as int;
    player._metal = json['metal'] as double;
    player._maxMetalStorage = json['maxMetalStorage'] as double;
    player._sellPrice = json['sellPrice'] as double;
    player._maintenanceCosts = json['maintenanceCosts'] as double;
    
    final upgradesJson = json['upgrades'] as Map<String, dynamic>;
    player._upgrades.addAll(
      upgradesJson.map((key, value) => MapEntry(key, Upgrade.fromJson(value))),
    );
    
    return player;
  }
} 