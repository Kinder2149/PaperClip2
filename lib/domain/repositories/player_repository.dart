abstract class PlayerRepository {
  Future<Player> getPlayer();
  Future<void> updatePlayer(Player player);
  Future<bool> consumeMetal(double amount);
  Future<void> updatePaperclips(double newAmount);
  Future<void> updateMoney(double newAmount);
  Future<void> updateMetal(double newAmount);
  Future<void> updateAutoclippers(int newAmount);
  Future<void> updateSellPrice(double newPrice);
  Future<void> updateMaxMetalStorage(double newCapacity);
  Future<bool> purchaseUpgrade(String upgradeId);
  Future<bool> purchaseAutoclipper();
  Future<int> getMarketingLevel();
  Future<Map<String, Upgrade>> getUpgrades();
  
  // Méthodes pour la gestion de l'état du jeu
  Future<Map<String, dynamic>?> getPlayerState();
  Future<void> updatePlayerState(Map<String, dynamic> state);
}