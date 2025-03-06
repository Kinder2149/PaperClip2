// lib/data/datasources/local/player_data_source.dart
import '../../models/player_model.dart';

abstract class PlayerDataSource {
  Future<PlayerModel> getPlayerState();
  Future<void> updatePlayer(PlayerModel player);
  Future<bool> buyAutoclipper();
  Future<bool> purchaseUpgrade(String upgradeId);
  Future<bool> producePaperclip();
  
  // Nouvelles méthodes
  Future<bool> consumeMetal(double amount);
  Future<void> updatePaperclips(double newAmount);
  Future<void> updateMoney(double newAmount);
  Future<void> updateMetal(double newAmount);
  Future<void> updateAutoclippers(int newAmount);
  Future<void> updateSellPrice(double newPrice);
  Future<void> updateMaxMetalStorage(double newCapacity);
  Future<int> getMarketingLevel();
  Future<Map<String, Upgrade>> getUpgrades();
}