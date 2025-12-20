import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/progression_system.dart';
import 'package:paperclip2/gameplay/events/game_event.dart';

enum UiElement {
  metalStock,
  paperclipStock,
  manualProductionButton,
  moneyDisplay,
  marketPrice,
  sellButton,
  market,
  marketStats,
  priceChart,
  marketInfo,
  metalPurchaseButton,
  autoclippersSection,
  autoClipperCountSection,
  productionStats,
  efficiencyDisplay,
  upgradesSection,
  upgradesScreen,
  levelDisplay,
  experienceBar,
  comboDisplay,
  statsSection,
  achievementsSection,
  settingsButton,
  musicToggle,
  notificationButton,
  saveLoadButtons,
}

extension UiElementKey on UiElement {
  String get key {
    switch (this) {
      case UiElement.metalStock:
        return 'metalStock';
      case UiElement.paperclipStock:
        return 'paperclipStock';
      case UiElement.manualProductionButton:
        return 'manualProductionButton';
      case UiElement.moneyDisplay:
        return 'moneyDisplay';
      case UiElement.marketPrice:
        return 'marketPrice';
      case UiElement.sellButton:
        return 'sellButton';
      case UiElement.market:
        return 'market';
      case UiElement.marketStats:
        return 'marketStats';
      case UiElement.priceChart:
        return 'priceChart';
      case UiElement.marketInfo:
        return 'marketInfo';
      case UiElement.metalPurchaseButton:
        return 'metalPurchaseButton';
      case UiElement.autoclippersSection:
        return 'autoclippersSection';
      case UiElement.autoClipperCountSection:
        return 'autoClipperCountSection';
      case UiElement.productionStats:
        return 'productionStats';
      case UiElement.efficiencyDisplay:
        return 'efficiencyDisplay';
      case UiElement.upgradesSection:
        return 'upgradesSection';
      case UiElement.upgradesScreen:
        return 'upgradesScreen';
      case UiElement.levelDisplay:
        return 'levelDisplay';
      case UiElement.experienceBar:
        return 'experienceBar';
      case UiElement.comboDisplay:
        return 'comboDisplay';
      case UiElement.statsSection:
        return 'statsSection';
      case UiElement.achievementsSection:
        return 'achievementsSection';
      case UiElement.settingsButton:
        return 'settingsButton';
      case UiElement.musicToggle:
        return 'musicToggle';
      case UiElement.notificationButton:
        return 'notificationButton';
      case UiElement.saveLoadButtons:
        return 'saveLoadButtons';
    }
  }
}

class VisibleUiElements {
  final Map<UiElement, bool> _flags;

  const VisibleUiElements(this._flags);

  bool isEnabled(UiElement element) => _flags[element] ?? false;

  bool operator [](UiElement element) => isEnabled(element);

  Map<String, bool> toLegacyMap() {
    return {
      for (final element in UiElement.values) element.key: isEnabled(element),
    };
  }
}

class ProgressionRulesService {
  final LevelSystem _levelSystem;
  final PlayerManager _playerManager;

  ProgressionRulesService({
    required LevelSystem levelSystem,
    required PlayerManager playerManager,
  })  : _levelSystem = levelSystem,
        _playerManager = playerManager;

  VisibleUiElements getVisibleUiElements(int level) {
    final flags = <UiElement, bool>{
      UiElement.metalStock: true,
      UiElement.paperclipStock: true,
      UiElement.manualProductionButton: true,
      UiElement.moneyDisplay: true,

      UiElement.marketPrice: level >= 1,
      UiElement.sellButton: level >= 1,

      UiElement.market: level >= GameConstants.MARKET_UNLOCK_LEVEL,
      UiElement.marketStats: level >= GameConstants.MARKET_UNLOCK_LEVEL,
      UiElement.priceChart: level >= GameConstants.MARKET_UNLOCK_LEVEL,
      UiElement.marketInfo: level >= GameConstants.MARKET_UNLOCK_LEVEL,

      UiElement.metalPurchaseButton: level >= 2,

      UiElement.autoclippersSection: level >= 3,
      UiElement.autoClipperCountSection: level >= 3,

      UiElement.productionStats: level >= 2,
      UiElement.efficiencyDisplay: level >= 3,
      UiElement.upgradesSection: level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      UiElement.upgradesScreen: level >= GameConstants.UPGRADES_UNLOCK_LEVEL,
      UiElement.levelDisplay: true,
      UiElement.experienceBar: true,
      UiElement.comboDisplay: level >= 2,
      UiElement.statsSection: level >= 4,
      UiElement.achievementsSection: level >= 5,
      UiElement.settingsButton: true,
      UiElement.musicToggle: true,
      UiElement.notificationButton: true,
      UiElement.saveLoadButtons: true,
    };

    assert(() {
      // Cohérence minimale: si le marché (onglet) est visible, alors les éléments associés doivent être présents.
      if (flags[UiElement.market] == true) {
        return flags[UiElement.marketStats] == true &&
            flags[UiElement.priceChart] == true;
      }
      return true;
    }());

    return VisibleUiElements(flags);
  }

  Map<String, bool> getVisibleScreenElements(int level) {
    return getVisibleUiElements(level).toLegacyMap();
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
      case GameEventType.importantEventOccurred:
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
