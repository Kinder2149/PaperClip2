// lib/domain/entities/player_entity.dart
import 'dart:math';
import 'upgrade_entity.dart';
import '../../core/constants/game_constants.dart';

class PlayerEntity {
  final double paperclips;
  final double metal;
  final double money;
  final int autoclippers;
  final double sellPrice;
  final double maxMetalStorage;
  final Map<String, UpgradeEntity> upgrades;

  PlayerEntity({
    required this.paperclips,
    required this.metal,
    required this.money,
    required this.autoclippers,
    required this.sellPrice,
    required this.maxMetalStorage,
    required this.upgrades,
  });

  bool canConsumeMetal(double amount) {
    return metal >= amount;
  }

  bool consumeMetal(double amount) {
    if (canConsumeMetal(amount)) {
      return true; // Modification pour correspondre à l'implémentation originale
    }
    return false;
  }

  int getMarketingLevel() {
    return upgrades['marketing']?.level ?? 0;
  }

  double calculateAutoclipperCost() {
    double baseCost = 15.0;
    double automationDiscount = 1.0 - ((upgrades['automation']?.level ?? 0) * 0.10);
    return baseCost * pow(1.1, autoclippers) * automationDiscount;
  }

  bool canAffordAutoclipper() {
    return money >= calculateAutoclipperCost();
  }

  double getProductionMultiplier() {
    double bulkBonus = (upgrades['bulk']?.level ?? 0) * 0.25;
    return 1.0 + bulkBonus;
  }

  PlayerEntity copyWith({
    double? paperclips,
    double? metal,
    double? money,
    int? autoclippers,
    double? sellPrice,
    double? maxMetalStorage,
    Map<String, UpgradeEntity>? upgrades,
  }) {
    return PlayerEntity(
      paperclips: paperclips ?? this.paperclips,
      metal: metal ?? this.metal,
      money: money ?? this.money,
      autoclippers: autoclippers ?? this.autoclippers,
      sellPrice: sellPrice ?? this.sellPrice,
      maxMetalStorage: maxMetalStorage ?? this.maxMetalStorage,
      upgrades: upgrades ?? this.upgrades,
    );
  }
}