abstract class ResourceRepository {
  Future<void> updateResourceEfficiency(int level);
  Future<bool> canStoreMetal(double amount, int storageUpgradeLevel, double currentMetal);
  Future<void> upgradeStorageCapacity(int level);
  Future<void> improveStorageEfficiency(int level);
  Future<double> calculateStorageEfficiency(int efficiencyUpgradeLevel);
  Future<double> calculateEffectiveStorage(int storageUpgradeLevel);
  Future<void> resetResources();
}