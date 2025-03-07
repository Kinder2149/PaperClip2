import 'package:paperclip2/models/interfaces/upgrade_interface.dart';
import 'package:paperclip2/models/constants/game_constants.dart';
import 'dart:math' as math;

class Upgrade implements IUpgrade {
  static const double _costMultiplier = 1.5;

  final String _id;
  final String _name;
  final String _description;
  final double _baseCost;
  final int _maxLevel;
  final int _requiredLevel;
  int _level = 0;

  Upgrade({
    required String id,
    required String name,
    required String description,
    required double baseCost,
    required int maxLevel,
    this.requiredLevel = 1,
  })  : _id = id,
        _name = name,
        _description = description,
        _baseCost = baseCost,
        _maxLevel = maxLevel;

  @override
  String get id => _id;

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  double get cost => _baseCost;

  @override
  int get level => _level;

  @override
  int get maxLevel => _maxLevel;

  @override
  int get requiredLevel => _requiredLevel;

  @override
  double get costMultiplier => _costMultiplier;

  @override
  bool isMaxed() => _level >= _maxLevel;

  @override
  bool canPurchase(int playerMoney, int playerLevel) {
    return !isMaxed() && playerMoney >= getCost() && playerLevel >= _requiredLevel;
  }

  @override
  double getCost() {
    return _baseCost * math.pow(_costMultiplier, _level);
  }

  @override
  void incrementLevel() {
    if (!isMaxed()) {
      _level++;
    }
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': _id,
      'name': _name,
      'description': _description,
      'baseCost': _baseCost,
      'maxLevel': _maxLevel,
      'requiredLevel': _requiredLevel,
      'level': _level,
    };
  }

  factory Upgrade.fromJson(Map<String, dynamic> json) {
    return Upgrade(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      baseCost: json['baseCost'] as double,
      maxLevel: json['maxLevel'] as int,
      requiredLevel: json['requiredLevel'] as int,
    ).._level = json['level'] as int;
  }
} 