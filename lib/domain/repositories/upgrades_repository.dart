import '../entities/upgrade.dart';
import '../entities/upgrade_category.dart';

abstract class UpgradesRepository {
  Future<List<UpgradeCategory>> getCategories();
  Future<List<Upgrade>> getUpgradesForCategory(String categoryId);
  Future<bool> purchaseUpgrade(String upgradeId);
  Future<void> saveUpgradeState(String upgradeId, int level);
  Future<Map<String, int>> loadUpgradeStates();
} 