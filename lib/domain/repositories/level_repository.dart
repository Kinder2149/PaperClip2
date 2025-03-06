abstract class LevelRepository {
  Future<LevelSystem> getLevelSystem();
  Future<void> updateLevelSystem(LevelSystem levelSystem);
  Future<void> gainExperience(double amount);
  Future<bool> claimDailyBonus();
  Future<void> addManualProduction();
  Future<void> addAutomaticProduction(int amount);
  Future<void> addSale(int quantity, double price);
  Future<void> addAutoclipperPurchase();
  Future<void> addUpgradePurchase(int upgradeLevel);
  Future<void> applyXPBoost(double multiplier, Duration duration);
  Future<void> checkLevelUp();
}