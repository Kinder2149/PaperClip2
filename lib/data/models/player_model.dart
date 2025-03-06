// lib/data/models/player_model.dart
import 'package:paperclip2/domain/entities/player_entity.dart';
import 'upgrade_model.dart';
import 'dart:math';

class PlayerModel {
  final double paperclips;
  final double metal;
  final double money;
  final int autoclippers;
  final double sellPrice;
  final double maxMetalStorage;
  final Map<String, UpgradeModel> upgrades;

  PlayerModel({
    required this.paperclips,
    required this.metal,
    required this.money,
    required this.autoclippers,
    required this.sellPrice,
    required this.maxMetalStorage,
    required this.upgrades,
  });

  int get marketingLevel => upgrades['marketing']?.level ?? 0;

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    final upgradesMap = <String, UpgradeModel>{};
    if (json['upgrades'] != null) {
      final upgrades = json['upgrades'] as Map<String, dynamic>;
      upgrades.forEach((key, value) {
        upgradesMap[key] = UpgradeModel.fromJson({...value, 'id': key});
      });
    }

    return PlayerModel(
      paperclips: (json['paperclips'] as num?)?.toDouble() ?? 0.0,
      metal: (json['metal'] as num?)?.toDouble() ?? 0.0,
      money: (json['money'] as num?)?.toDouble() ?? 0.0,
      autoclippers: (json['autoclippers'] as num?)?.toInt() ?? 0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0.25,
      maxMetalStorage: (json['maxMetalStorage'] as num?)?.toDouble() ?? 1000.0,
      upgrades: upgradesMap,
    );
  }

  Map<String, dynamic> toJson() => {
    'paperclips': paperclips,
    'metal': metal,
    'money': money,
    'autoclippers': autoclippers,
    'sellPrice': sellPrice,
    'maxMetalStorage': maxMetalStorage,
    'upgrades': upgrades.map((key, value) => MapEntry(key, value.toJson())),
  };

  PlayerEntity toEntity() {
    return PlayerEntity(
      paperclips: paperclips,
      metal: metal,
      money: money,
      autoclippers: autoclippers,
      sellPrice: sellPrice,
      maxMetalStorage: maxMetalStorage,
      upgrades: upgrades.map((key, value) => MapEntry(key, value.toEntity())),
    );
  }

  static PlayerModel fromEntity(PlayerEntity entity) {
    return PlayerModel(
      paperclips: entity.paperclips,
      metal: entity.metal,
      money: entity.money,
      autoclippers: entity.autoclippers,
      sellPrice: entity.sellPrice,
      maxMetalStorage: entity.maxMetalStorage,
      upgrades: entity.upgrades.map((key, value) => MapEntry(key, UpgradeModel.fromEntity(value))),
    );
  }

  double calculateAutoclipperCost() {
    double baseCost = 15.0; // Remplacer par la constante appropriée
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * pow(1.1, autoclippers) * automationDiscount;
  }
}