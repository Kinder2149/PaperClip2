import 'package:shared_preferences/shared_preferences.dart';
import 'package:paperclip2/core/constants/game_constants.dart';
import 'player_data_source.dart';
import '../../models/player_model.dart';
import 'dart:convert';

class PlayerDataSourceImpl implements PlayerDataSource {
  final SharedPreferences _prefs;
  static const String _playerKey = 'paperclip_player_data';

  PlayerDataSourceImpl(this._prefs);

  @override
  Future<PlayerModel> getPlayerState() async {
    final jsonData = _prefs.getString(_playerKey);
    if (jsonData == null) {
      return _createDefaultPlayerModel();
    }

    try {
      return PlayerModel.fromJson(json.decode(jsonData));
    } catch (e) {
      return _createDefaultPlayerModel();
    }
  }

  @override
  Future<void> updatePlayer(PlayerModel player) async {
    await _prefs.setString(_playerKey, json.encode(player.toJson()));
  }

  @override
  Future<bool> buyAutoclipper() async {
    final player = await getPlayerState();
    final cost = player.calculateAutoclipperCost();

    if (player.money < cost) {
      return false;
    }

    final updatedPlayer = PlayerModel(
      paperclips: player.paperclips,
      metal: player.metal,
      money: player.money - cost,
      autoclippers: player.autoclippers + 1,
      sellPrice: player.sellPrice,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
    );

    await updatePlayer(updatedPlayer);
    return true;
  }

  @override
  Future<bool> purchaseUpgrade(String upgradeId) async {
    final player = await getPlayerState();
    final upgrade = player.upgrades[upgradeId];

    if (upgrade == null) {
      return false;
    }

    if (player.money < upgrade.getCost() || upgrade.level >= upgrade.maxLevel) {
      return false;
    }

    final upgrades = Map<String, UpgradeModel>.from(player.upgrades);
    upgrades[upgradeId] = UpgradeModel(
      id: upgrade.id,
      name: upgrade.name,
      description: upgrade.description,
      level: upgrade.level + 1,
      baseCost: upgrade.baseCost,
      costMultiplier: upgrade.costMultiplier,
      maxLevel: upgrade.maxLevel,
      requiredLevel: upgrade.requiredLevel,
    );

    final updatedPlayer = PlayerModel(
      paperclips: player.paperclips,
      metal: player.metal,
      money: player.money - upgrade.getCost(),
      autoclippers: player.autoclippers,
      sellPrice: player.sellPrice,
      maxMetalStorage: _calculateMaxStorage(player, upgrades),
      upgrades: upgrades,
    );

    await updatePlayer(updatedPlayer);
    return true;
  }

  @override
  Future<bool> producePaperclip() async {
    final player = await getPlayerState();
    final metalPerClip = _calculateMetalPerClip(player);

    if (player.metal < metalPerClip) {
      return false;
    }

    final updatedPlayer = PlayerModel(
      paperclips: player.paperclips + 1,
      metal: player.metal - metalPerClip,
      money: player.money,
      autoclippers: player.autoclippers,
      sellPrice: player.sellPrice,
      maxMetalStorage: player.maxMetalStorage,
      upgrades: player.upgrades,
    );

    await updatePlayer(updatedPlayer);
    return true;
  }

  double _calculateMetalPerClip(PlayerModel player) {
    final efficiencyLevel = player.upgrades['efficiency']?.level ?? 0;
    final metalReduction = efficiencyLevel * 0.11; // 11% de réduction par niveau
    final reduction = metalReduction.clamp(0.0, 0.85); // Maximum 85% de réduction
    return GameConstants.metalPerPaperClip * (1.0 - reduction);
  }

  double _calculateMaxStorage(PlayerModel player, Map<String, UpgradeModel> upgrades) {
    final storageLevel = upgrades['storage']?.level ?? 0;
    return GameConstants.initialStorageCapacity * (1 + (storageLevel * 0.2)); // 20% d'augmentation par niveau
  }

  PlayerModel _createDefaultPlayerModel() {
    return PlayerModel(
      paperclips: 0.0,
      metal: GameConstants.initialMetal,
      money: GameConstants.initialMoney,
      autoclippers: 0,
      sellPrice: GameConstants.initialPrice,
      maxMetalStorage: GameConstants.initialStorageCapacity,
      upgrades: _getDefaultUpgrades(),
    );
  }

  Map<String, UpgradeModel> _getDefaultUpgrades() {
    return {
      'efficiency': UpgradeModel(
        id: 'efficiency',
        name: 'Efficacité',
        description: 'Réduit la consommation de métal de 11% par niveau',
        baseCost: 100.0,
        maxLevel: 8,
        requiredLevel: 5,
      ),
      'speed': UpgradeModel(
        id: 'speed',
        name: 'Vitesse',
        description: 'Augmente la vitesse de production de 20%',
        baseCost: 150.0,
        maxLevel: 5,
        requiredLevel: 5,
      ),
      // Autres améliorations...
    };
  }
}