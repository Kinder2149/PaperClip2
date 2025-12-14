import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/gameplay/events/game_event.dart';

class ProgressionRulesService {
  final LevelSystem _levelSystem;
  final PlayerManager _playerManager;

  ProgressionRulesService({
    required LevelSystem levelSystem,
    required PlayerManager playerManager,
  })  : _levelSystem = levelSystem,
        _playerManager = playerManager;

  Map<String, bool> getVisibleScreenElements(int level) {
    final flags = {
      'metalStock': true,
      'paperclipStock': true,
      'manualProductionButton': true,
      'moneyDisplay': true,

      // Ventes activables dès le début (l'utilisateur peut ensuite désactiver via l'UI).
      'marketPrice': level >= 1,
      'sellButton': level >= 1,

      // L'écran/onglet Marché (analyses/graphes) reste un déblocage UX.
      'market': level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketStats': level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'priceChart': level >= GameConstants.MARKET_UNLOCK_LEVEL,
      'marketInfo': level >= GameConstants.MARKET_UNLOCK_LEVEL,

      // Achat de métal débloqué au niveau 2.
      'metalPurchaseButton': level >= 2,

      // Autoclippers
      'autoclippersSection': level >= 3,
      // Alias utilisé par certains écrans.
      'autoClipperCountSection': level >= 3,

      'productionStats': level >= 2,
      'efficiencyDisplay': level >= 3,
      'upgradesSection': level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'upgradesScreen': level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      'levelDisplay': true,
      'experienceBar': true,
      'comboDisplay': level >= 2,
      'statsSection': level >= 4,
      'achievementsSection': level >= 5,
      'settingsButton': true,
      'musicToggle': true,
      'notificationButton': true,
      'saveLoadButtons': true,
    };

    assert(() {
      // Cohérence minimale: si le marché (onglet) est visible, alors les éléments associés doivent être présents.
      if (flags['market'] == true) {
        return flags['marketStats'] == true && flags['priceChart'] == true;
      }
      return true;
    }());

    return flags;
  }

  void onSale({required int quantity, required double unitPrice}) {
    _levelSystem.addSale(quantity, unitPrice);
  }

  void onUpgradePurchase({required int upgradeLevel}) {
    _levelSystem.addUpgradePurchase(upgradeLevel);
  }

  void onGameEvent(GameEvent event) {
    switch (event.type) {
      case GameEventType.saleProcessed:
        final quantity = (event.data['quantity'] as num?)?.toInt() ?? 0;
        final unitPrice = (event.data['unitPrice'] as num?)?.toDouble() ?? 0.0;
        if (quantity > 0) {
          onSale(quantity: quantity, unitPrice: unitPrice);
        }
        return;
      case GameEventType.upgradePurchased:
        final upgradeLevel = (event.data['upgradeLevel'] as num?)?.toInt() ?? 0;
        if (upgradeLevel > 0) {
          onUpgradePurchase(upgradeLevel: upgradeLevel);
        }
        return;
      case GameEventType.productionTick:
      case GameEventType.marketTick:
      case GameEventType.autoclipperPurchased:
      case GameEventType.progressionPathChosen:
        return;
    }
  }

  void handleLevelUp({
    required int newLevel,
    required List<UnlockableFeature> newFeatures,
    void Function(String message)? notifyUnlock,
    Future<void> Function()? saveOnImportantEvent,
  }) {
    for (final feature in newFeatures) {
      switch (feature) {
        case UnlockableFeature.MANUAL_PRODUCTION:
          notifyUnlock?.call('Production manuelle débloquée !');
          break;
        case UnlockableFeature.MARKET_SALES:
          notifyUnlock?.call('Ventes débloquées !');
          break;
        case UnlockableFeature.AUTOCLIPPERS:
          notifyUnlock?.call('Autoclippeuses disponibles !');
          _playerManager.updateMoney(
            _playerManager.money + GameConstants.BASE_AUTOCLIPPER_COST,
          );
          break;
        case UnlockableFeature.METAL_PURCHASE:
          notifyUnlock?.call('Achat de métal débloqué !');
          break;
        case UnlockableFeature.MARKET_SCREEN:
          notifyUnlock?.call('Écran de marché débloqué !');
          break;
        case UnlockableFeature.UPGRADES:
          notifyUnlock?.call('Améliorations disponibles !');
          break;
      }
    }

    if (newLevel % 5 == 0) {
      _levelSystem.applyXPBoost(2.0, const Duration(minutes: 5));
    }

    saveOnImportantEvent?.call();
  }
}
