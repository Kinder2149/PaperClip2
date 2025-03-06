import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import '../../domain/entities/upgrade.dart';
import '../../domain/entities/upgrade_category.dart';
import '../../domain/repositories/upgrades_repository.dart';

class UpgradesRepositoryImpl implements UpgradesRepository {
  final SharedPreferences _prefs;
  static const String _upgradeStatesKey = 'upgrade_states';

  UpgradesRepositoryImpl(this._prefs);

  @override
  Future<List<UpgradeCategory>> getCategories() async {
    // Pour l'instant, retournons des catégories statiques
    return [
      UpgradeCategory(
        id: 'production',
        name: 'Production',
        description: 'Améliorez votre capacité de production',
        icon: Icons.factory,
        color: Colors.blue,
      ),
      UpgradeCategory(
        id: 'storage',
        name: 'Stockage',
        description: 'Augmentez votre capacité de stockage',
        icon: Icons.warehouse,
        color: Colors.orange,
      ),
      UpgradeCategory(
        id: 'marketing',
        name: 'Marketing',
        description: 'Optimisez vos ventes',
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      UpgradeCategory(
        id: 'automation',
        name: 'Automatisation',
        description: 'Automatisez votre production',
        icon: Icons.auto_awesome,
        color: Colors.purple,
      ),
    ];
  }

  @override
  Future<List<Upgrade>> getUpgradesForCategory(String categoryId) async {
    final upgradeStates = await loadUpgradeStates();
    
    // Pour l'instant, retournons des améliorations statiques
    switch (categoryId) {
      case 'production':
        return [
          _createUpgrade(
            id: 'faster_production',
            categoryId: categoryId,
            name: 'Production Rapide',
            description: 'Augmente la vitesse de production',
            icon: Icons.speed,
            baseCost: 100,
            costMultiplier: 1.5,
            maxLevel: 10,
            currentLevel: upgradeStates['faster_production'] ?? 0,
            effectValue: 1.2,
            effectMultiplier: 1.1,
          ),
          _createUpgrade(
            id: 'better_quality',
            categoryId: categoryId,
            name: 'Meilleure Qualité',
            description: 'Produit des trombones de meilleure qualité',
            icon: Icons.star,
            baseCost: 200,
            costMultiplier: 1.8,
            maxLevel: 5,
            currentLevel: upgradeStates['better_quality'] ?? 0,
            effectValue: 1.5,
            effectMultiplier: 1.2,
          ),
        ];
      case 'storage':
        return [
          _createUpgrade(
            id: 'larger_storage',
            categoryId: categoryId,
            name: 'Stockage Plus Grand',
            description: 'Augmente la capacité de stockage',
            icon: Icons.warehouse,
            baseCost: 150,
            costMultiplier: 1.6,
            maxLevel: 8,
            currentLevel: upgradeStates['larger_storage'] ?? 0,
            effectValue: 1.3,
            effectMultiplier: 1.1,
          ),
        ];
      case 'marketing':
        return [
          _createUpgrade(
            id: 'better_marketing',
            categoryId: categoryId,
            name: 'Meilleur Marketing',
            description: 'Augmente le prix de vente',
            icon: Icons.trending_up,
            baseCost: 300,
            costMultiplier: 2.0,
            maxLevel: 5,
            currentLevel: upgradeStates['better_marketing'] ?? 0,
            effectValue: 1.4,
            effectMultiplier: 1.15,
          ),
        ];
      case 'automation':
        return [
          _createUpgrade(
            id: 'auto_production',
            categoryId: categoryId,
            name: 'Production Automatique',
            description: 'Produit automatiquement des trombones',
            icon: Icons.auto_awesome,
            baseCost: 500,
            costMultiplier: 2.5,
            maxLevel: 3,
            currentLevel: upgradeStates['auto_production'] ?? 0,
            effectValue: 1.0,
            effectMultiplier: 1.0,
          ),
        ];
      default:
        return [];
    }
  }

  Upgrade _createUpgrade({
    required String id,
    required String categoryId,
    required String name,
    required String description,
    required IconData icon,
    required double baseCost,
    required double costMultiplier,
    required int maxLevel,
    required int currentLevel,
    required double effectValue,
    required double effectMultiplier,
  }) {
    return Upgrade(
      id: id,
      categoryId: categoryId,
      name: name,
      description: description,
      icon: icon,
      baseCost: baseCost,
      costMultiplier: costMultiplier,
      maxLevel: maxLevel,
      currentLevel: currentLevel,
      effectValue: effectValue,
      effectMultiplier: effectMultiplier,
      onPurchase: () {}, // Cette fonction sera injectée par le ViewModel
    );
  }

  @override
  Future<bool> purchaseUpgrade(String upgradeId) async {
    final upgradeStates = await loadUpgradeStates();
    final currentLevel = upgradeStates[upgradeId] ?? 0;
    
    // Sauvegarder le nouveau niveau
    await saveUpgradeState(upgradeId, currentLevel + 1);
    return true;
  }

  @override
  Future<void> saveUpgradeState(String upgradeId, int level) async {
    final upgradeStates = await loadUpgradeStates();
    upgradeStates[upgradeId] = level;
    await _prefs.setString(_upgradeStatesKey, jsonEncode(upgradeStates));
  }

  @override
  Future<Map<String, int>> loadUpgradeStates() async {
    final String? statesJson = _prefs.getString(_upgradeStatesKey);
    if (statesJson == null) return {};
    
    final Map<String, dynamic> states = jsonDecode(statesJson);
    return states.map((key, value) => MapEntry(key, value as int));
  }
} 