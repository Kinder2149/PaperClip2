// lib/data/repositories/player_repository_impl.dart
import '../../domain/repositories/player_repository.dart';
import '../../domain/entities/player_entity.dart';
import '../../domain/entities/upgrade_entity.dart';
import '../datasources/local/player_data_source.dart';
import '../models/player_model.dart';

class PlayerRepositoryImpl implements PlayerRepository {
  final PlayerDataSource _dataSource;

  PlayerRepositoryImpl(this._dataSource);

  @override
  Future<Player> getPlayer() async {
    final playerModel = await _dataSource.getPlayerState();
    return playerModel.toEntity();
  }

  @override
  Future<void> updatePlayer(Player player) async {
    final playerModel = PlayerModel.fromEntity(player);
    await _dataSource.updatePlayer(playerModel);
  }

  @override
  Future<bool> consumeMetal(double amount) async {
    return await _dataSource.consumeMetal(amount);
  }

  @override
  Future<void> updatePaperclips(double newAmount) async {
    await _dataSource.updatePaperclips(newAmount);
  }

  @override
  Future<void> updateMoney(double newAmount) async {
    await _dataSource.updateMoney(newAmount);
  }

  @override
  Future<void> updateMetal(double newAmount) async {
    await _dataSource.updateMetal(newAmount);
  }

  @override
  Future<void> updateAutoclippers(int newAmount) async {
    await _dataSource.updateAutoclippers(newAmount);
  }

  @override
  Future<void> updateSellPrice(double newPrice) async {
    await _dataSource.updateSellPrice(newPrice);
  }

  @override
  Future<void> updateMaxMetalStorage(double newCapacity) async {
    await _dataSource.updateMaxMetalStorage(newCapacity);
  }

  @override
  Future<bool> purchaseUpgrade(String upgradeId) async {
    return await _dataSource.purchaseUpgrade(upgradeId);
  }

  @override
  Future<bool> purchaseAutoclipper() async {
    return await _dataSource.buyAutoclipper();
  }

  @override
  Future<int> getMarketingLevel() async {
    return await _dataSource.getMarketingLevel();
  }

  @override
  Future<Map<String, Upgrade>> getUpgrades() async {
    return await _dataSource.getUpgrades();
  }

  @override
  Future<Map<String, dynamic>?> getPlayerState() async {
    final playerModel = await _dataSource.getPlayerState();
    return playerModel.toJson();
  }

  @override
  Future<void> updatePlayerState(Map<String, dynamic> state) async {
    final playerModel = PlayerModel.fromJson(state);
    await _dataSource.updatePlayer(playerModel);
  }
}