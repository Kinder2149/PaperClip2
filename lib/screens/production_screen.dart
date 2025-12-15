import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../widgets/resources/resource_widgets.dart';
import '../widgets/indicators/level_widgets.dart';
import '../widgets/buttons/action_button.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../widgets/indicators/stat_indicator.dart';
import '../widgets/cards/stats_panel.dart';
import '../widgets/save_button.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/format/game_format.dart';

class _ProductionScreenView {
  final bool showMarketInfo;
  final bool showMetalPurchaseButton;
  final bool showAutoClipperCountSection;
  final bool autoSellEnabled;
  final int totalPaperclipsProduced;
  final double paperclipsInStock;
  final double metal;
  final double maxMetalStorage;

  final double currentMetalPrice;
  final double sellPrice;
  final int level;
  final double productionMultiplier;
  final int autoClipperCount;

  const _ProductionScreenView({
    required this.showMarketInfo,
    required this.showMetalPurchaseButton,
    required this.showAutoClipperCountSection,
    required this.autoSellEnabled,
    required this.totalPaperclipsProduced,
    required this.paperclipsInStock,
    required this.metal,
    required this.maxMetalStorage,

    required this.currentMetalPrice,
    required this.sellPrice,
    required this.level,
    required this.productionMultiplier,
    required this.autoClipperCount,
  });

  @override
  bool operator ==(Object other) {
    return other is _ProductionScreenView &&
        other.showMarketInfo == showMarketInfo &&
        other.showMetalPurchaseButton == showMetalPurchaseButton &&
        other.showAutoClipperCountSection == showAutoClipperCountSection &&
        other.autoSellEnabled == autoSellEnabled &&
        other.totalPaperclipsProduced == totalPaperclipsProduced &&
        other.paperclipsInStock == paperclipsInStock &&
        other.metal == metal &&
        other.maxMetalStorage == maxMetalStorage &&

        other.currentMetalPrice == currentMetalPrice &&
        other.sellPrice == sellPrice &&
        other.level == level &&
        other.productionMultiplier == productionMultiplier &&
        other.autoClipperCount == autoClipperCount;
  }

  @override
  int get hashCode => Object.hash(
        showMarketInfo,
        showMetalPurchaseButton,
        showAutoClipperCountSection,
        autoSellEnabled,
        totalPaperclipsProduced,
        paperclipsInStock,
        metal,
        maxMetalStorage,
        currentMetalPrice,

        sellPrice,
        level,
        productionMultiplier,
        autoClipperCount,
      );
}

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  // L'écran est mis à jour via l'architecture réactive (Provider/ChangeNotifier)
  // au travers de `Consumer<GameState>` et des `notifyListeners()`.

  bool _canPurchaseMetal(GameState gameState) {
    return gameState.canBuyMetal();
  }

  String formatNumber(double number, bool isMetal) {
    if (isMetal) {
      return GameFormat.number(number, decimals: 2);
    } else {
      return GameFormat.intWithSeparators(number.floor());
    }
  }

  Widget _buildResourceCard(String title, String value, Color color,
      {VoidCallback? onTap}) {
    // Utilisation du nouveau widget InfoCard
    return InfoCard(
      title: title,
      value: value,
      backgroundColor: color,
      onTap: onTap,
      crossAxisAlignment: CrossAxisAlignment.center,
      expanded: true,
    );
  }

  void _showInfoDialog(BuildContext context, String title, String message) {
    // Utilisation du nouveau widget InfoDialog
    InfoDialog.show(
      context,
      title: title,
      message: message,
    );
  }

  // Méthode _saveGame supprimée car maintenant gérée par le widget SaveButton

  Widget _buildAutoclippersSection(BuildContext context, GameState gameState) {
    final bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;
    final speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;

    final bulkMultiplier = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);
    final speedMultiplier = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
    final reduction = UpgradeEffectsCalculator.efficiencyReduction(level: efficiencyLevel);

    final bulkBonus = (bulkMultiplier - 1.0) * 100;
    final speedBonus = (speedMultiplier - 1.0) * 100;
    final metalSavingPercent = reduction * 100;
    double roi = gameState.player.calculateAutoclipperROI();

    final autoclipperCost = gameState.productionManager.calculateAutoclipperCost();
    final canBuyAutoclipper = gameState.productionManager.canBuyAutoclipper();

    return Card(
      elevation: 2,
      color: Colors.orange.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.precision_manufacturing),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Autoclippers: ${gameState.player.autoClipperCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Retour sur investissement: ${GameFormat.number(roi, decimals: 1)}%/min',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () =>
                      _showAutoclipperInfoDialog(
                        context,
                        gameState,
                        bulkBonus,
                        speedBonus,
                        metalSavingPercent,
                      ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBonusIndicator(
                  'Production',
                  '+${GameFormat.number(bulkBonus, decimals: 0)}%',
                  Icons.trending_up,
                ),
                _buildBonusIndicator(
                  'Vitesse',
                  '+${GameFormat.number(speedBonus, decimals: 0)}%',
                  Icons.speed,
                ),
                _buildBonusIndicator(
                  'Économie Métal',
                  '-${GameFormat.number(metalSavingPercent, decimals: 0)}%',
                  Icons.eco,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ActionButton.purchase(
              onPressed: canBuyAutoclipper ? () => gameState.buyAutoclipper() : null,
              label: 'Acheter Autoclipper (${GameFormat.money(autoclipperCost, decimals: 1)})',
              showComboMultiplier: true,
            ),
          ],
        ),
      ),
    );
  }

  void _showAutoclipperInfoDialog(BuildContext context,
      GameState gameState,
      double bulkBonus,
      double speedBonus,
      double metalSavingPercent) {
    // Calculs pour des informations précises
    double baseProduction = gameState.player.autoClipperCount *
        (GameConstants.BASE_AUTOCLIPPER_PRODUCTION * 60.0); // par minute
    double speedMultiplier = 1.0 + (speedBonus / 100);
    double bulkMultiplier = 1.0 + (bulkBonus / 100);
    double effectiveProduction = baseProduction * speedMultiplier * bulkMultiplier;

    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
    final metalPerPaperclip = UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );

    double effectiveMetalConsumption =
        effectiveProduction * metalPerPaperclip * (1.0 - metalSavingPercent / 100);
    double metalSaved =
        effectiveProduction * metalPerPaperclip * (metalSavingPercent / 100);

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Détails des Autoclippers'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Production et améliorations
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Production de base: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${GameFormat.number(baseProduction, decimals: 1)} trombones/min\n'),
                        const TextSpan(text: 'Avec améliorations: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${GameFormat.number(effectiveProduction, decimals: 1)} trombones/min'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Détail des bonus
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Bonus de production: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '+${GameFormat.number(bulkBonus, decimals: 0)}%\n', style: const TextStyle(color: Colors.green)),
                        const TextSpan(text: 'Bonus de vitesse: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '+${GameFormat.number(speedBonus, decimals: 0)}%', style: const TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Consommation de métal
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Consommation de métal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${GameFormat.number(effectiveMetalConsumption, decimals: 2)}/min\n'),
                        const TextSpan(text: 'Économie de métal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: '-${GameFormat.number(metalSavingPercent, decimals: 0)}% (${GameFormat.number(metalSaved, decimals: 2)} unités/min)',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  
                  // Coûts de maintenance
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Coûts de maintenance: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: '${GameFormat.money(gameState.maintenanceCosts, decimals: 2)} par min',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showProductionStatsInfoDialog(BuildContext context, GameState gameState, 
      double baseProduction, double actualProduction, double metalUsage, 
      double metalSaved, double metalSavingPercent) {
    
    // Calculer le pourcentage d'augmentation de la production
    double productionIncrease = baseProduction > 0 ? 
        ((actualProduction - baseProduction) / baseProduction * 100) : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails des Statistiques de Production'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Production et augmentation
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Production\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: 'Base: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${GameFormat.number(baseProduction, decimals: 1)} trombones/min\n'),
                    const TextSpan(text: 'Effective: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: '${GameFormat.number(actualProduction, decimals: 1)} trombones/min ',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    TextSpan(
                      text: '(+${GameFormat.number(productionIncrease, decimals: 0)}%)',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(),
              
              // Consommation de métal
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Métal\n',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: 'Consommation: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${GameFormat.number(metalUsage, decimals: 1)} unités/min\n'),
                    const TextSpan(text: 'Économie: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: metalSavingPercent > 0 ? 
                        '${GameFormat.number(metalSaved, decimals: 1)} unités/min ' : 
                        '0 unités/min',
                    ),
                    if (metalSavingPercent > 0)
                      TextSpan(
                        text: '(-${GameFormat.number(metalSavingPercent, decimals: 0)}%)',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              const Divider(),
              
              // Explications supplémentaires
              const Text(
                'Comment ça marche:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Production de base = Nombre d\'autoClipperCount × Production unitaire\n'
                '• Production effective = Production de base × Bonus vitesse × Bonus production\n'
                '• Économie métal = Réduction de la consommation de métal grâce aux améliorations d\'efficacité\n'
                '• Métal utilisé = Production effective × Consommation par trombone × Facteur d\'économie',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showMarketInfoDialog(BuildContext context, GameState gameState) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Informations du Marché'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Réputation: ${GameFormat.number(gameState.market.reputation, decimals: 2)}'),
                  const Text(
                    'Influence les ventes et les prix maximum.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                  Text('Demande actuelle: ${(gameState.market.calculateDemand(
                      gameState.player.sellPrice,
                      gameState.player.getMarketingLevel()) * 100).toStringAsFixed(0)}%'),
                  const Text(
                    'Basée sur le prix et le niveau marketing.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Divider(),
                  Text('Stock mondial de métal: ${gameState.marketManager
                      .marketMetalStock.toStringAsFixed(0)}'),
                  const Text(
                    'Influence les prix et la disponibilité.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  Widget _buildBonusIndicator(String label, String value, IconData icon) {
    // Utilisation du nouveau widget StatIndicator
    return StatIndicator(
      label: label,
      value: value,
      icon: icon,
      layout: StatIndicatorLayout.vertical,
      spaceBetween: 4,
    );
  }

  Widget _buildMarketInfoCard(BuildContext context, GameState gameState) {
    // Utilisation du nouveau widget StatsPanel
    return StatsPanel(
      title: 'État du Marché',
      titleIcon: Icons.trending_up,
      backgroundColor: Colors.teal.shade100,
      // Le paramètre trailing n'est pas supporté, nous utilisons action à la place
      action: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showMarketInfoDialog(context, gameState),
        iconSize: 20,
      ),
      children: [
        StatIndicator(
          label: 'Réputation',
          value: GameFormat.number(gameState.market.reputation, decimals: 2),
          icon: Icons.star,
        ),
        StatIndicator(
          label: 'Demande',
          value: '${(gameState.market.calculateDemand(
              gameState.player.sellPrice,
              gameState.player.getMarketingLevel()) * 100).toStringAsFixed(0)}%',
          icon: Icons.people,
        ),
        StatIndicator(
          label: 'Stock Métal Mondial',
          value: gameState.marketManager.marketMetalStock.toStringAsFixed(0),
          icon: Icons.inventory_2,
        ),
      ],
    );
  }

  Widget _buildProductionStatsCard(GameState gameState) {
    // Calcul des bonus et effets des améliorations
    final efficiencyLevel = (gameState.player.upgrades['efficiency']?.level ?? 0);
    final speedLevel = (gameState.player.upgrades['speed']?.level ?? 0);
    final bulkLevel = (gameState.player.upgrades['bulk']?.level ?? 0);

    final metalSavingPercent = UpgradeEffectsCalculator.efficiencyReduction(level: efficiencyLevel) * 100;
    final efficiencyBonus = 1.0 - (metalSavingPercent / 100);
    final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
    final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);

    // Calculs de production précis
    double baseAutoclipperRate = GameConstants.BASE_AUTOCLIPPER_PRODUCTION;
    double clipperCount = gameState.player.autoClipperCount.toDouble();
    double baseProduction = clipperCount * baseAutoclipperRate * 60; // par minute
    double boostedProduction = baseProduction * speedBonus * bulkBonus; // avec les bonus
    double actualProduction = boostedProduction; // production effective
    double metalUsage = actualProduction * GameConstants.METAL_PER_PAPERCLIP * efficiencyBonus; // consommation de métal
    double metalSaved = actualProduction * GameConstants.METAL_PER_PAPERCLIP * (metalSavingPercent / 100); // métal économisé

    // Statistiques principales avec un affichage vertical
    Widget statsWrap = Wrap(
      spacing: 20, // Espace horizontal entre les éléments
      runSpacing: 10, // Espace vertical entre les lignes
      children: [
        // Production de base
        SizedBox(
          width: 160,
          child: StatIndicator(
            label: 'Production de base',
            value: '${GameFormat.number(baseProduction, decimals: 1)}/min',
            icon: Icons.speed,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.blue,
            // tooltip: 'Production de base sans bonus des améliorations',
          ),
        ),
        // Production effective
        SizedBox(
          width: 160,
          child: StatIndicator(
            label: 'Production effective',
            value: '${GameFormat.number(actualProduction, decimals: 1)}/min',
            icon: Icons.precision_manufacturing,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.green,
            valueStyle: TextStyle(
              color: actualProduction > baseProduction ? Colors.green : Colors.black,
              fontWeight: FontWeight.bold,
            ),
            // tooltip: 'Production avec tous les bonus appliqués',
          ),
        ),
        // Économie de métal
        SizedBox(
          width: 160,
          child: StatIndicator(
            label: 'Économie de métal',
            value: metalSavingPercent > 0 ? 
              '-${GameFormat.number(metalSavingPercent, decimals: 0)}%' : 
              '0%',
            icon: Icons.eco,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.green[700],
            valueStyle: TextStyle(
              color: metalSavingPercent > 0 ? Colors.green[700]! : Colors.black,
              fontWeight: FontWeight.bold,
            ),
            // tooltip: 'Réduction de la consommation de métal par trombone',
          ),
        ),
        // Métal utilisé par minute
        SizedBox(
          width: 160,
          child: StatIndicator(
            label: 'Métal utilisé/min',
            value: GameFormat.number(metalUsage, decimals: 1),
            icon: Icons.settings_input_component,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.orange[700],
            // tooltip: 'Quantité de métal consommée par minute pour la production',
          ),
        ),
      ],
    );

    // Récapitulatif des bonus appliqués
    Widget bonusInfo = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          StatIndicator(
            label: 'Vitesse',
            value: '+${GameFormat.number(((speedBonus - 1.0) * 100), decimals: 0)}%',
            icon: Icons.shutter_speed,
            layout: StatIndicatorLayout.horizontal,
            iconColor: Colors.blue[400],
            valueStyle: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
            // tooltip: 'Augmentation de la vitesse de production',
          ),
          StatIndicator(
            label: 'Production',
            value: '+${GameFormat.number(((bulkBonus - 1.0) * 100), decimals: 0)}%',
            icon: Icons.inventory_2,
            layout: StatIndicatorLayout.horizontal,
            iconColor: Colors.green[400],
            valueStyle: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
            // tooltip: 'Augmentation de la quantité produite',
          ),
        ],
      ),
    );

    // Information sur les coûts de maintenance
    Widget maintenanceInfo = Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StatIndicator(
        label: 'Coût maintenance',
        value: GameFormat.moneyPerMin(gameState.maintenanceCosts, decimals: 2),
        icon: Icons.euro,
        layout: StatIndicatorLayout.horizontal,
        iconColor: Colors.red[400],
        valueStyle: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        // tooltip n'est pas supporté par StatIndicator
        // tooltip: 'Coût de maintenance des autoClipperCount et équipements',
      ),
    );

    // Utilisation du widget StatsPanel pour l'affichage
    return StatsPanel(
      title: 'Statistiques de Production',
      titleIcon: Icons.bar_chart,
      backgroundColor: Colors.blue.shade50,
      // Le paramètre trailing n'est pas supporté, nous utilisons action à la place
      action: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showProductionStatsInfoDialog(
          context, 
          gameState, 
          baseProduction, 
          actualProduction, 
          metalUsage, 
          metalSaved, 
          metalSavingPercent),
      ),
      children: [
        statsWrap,
        bonusInfo,
        maintenanceInfo,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _ProductionScreenView>(
      selector: (context, gameState) {
        final visibleElements = gameState.getVisibleUiElements();
        return _ProductionScreenView(
          showMarketInfo: visibleElements[UiElement.marketInfo],
          showMetalPurchaseButton: visibleElements[UiElement.metalPurchaseButton],
          showAutoClipperCountSection:
              visibleElements[UiElement.autoClipperCountSection],
          autoSellEnabled: gameState.autoSellEnabled,
          totalPaperclipsProduced: gameState.totalPaperclipsProduced,
          paperclipsInStock: gameState.player.paperclips,
          metal: gameState.player.metal,
          maxMetalStorage: gameState.player.maxMetalStorage,
          currentMetalPrice: gameState.market.currentMetalPrice,
          sellPrice: gameState.player.sellPrice,
          level: gameState.level.level,
          productionMultiplier: gameState.level.productionMultiplier,
          autoClipperCount: gameState.player.autoClipperCount,
        );
      },
      builder: (context, view, child) {
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const XPStatusDisplay(),
                      const MoneyDisplay(),
                      const SizedBox(height: 8),

                      SwitchListTile(
                        title: const Text('Vente automatique'),
                        subtitle: const Text(
                            'Vendre automatiquement selon la demande du marché'),
                        value: view.autoSellEnabled,
                        onChanged: (value) {
                          context.read<GameState>().setAutoSellEnabled(value);
                        },
                      ),

                      const SizedBox(height: 16),

                      // Ressources existantes
                      Row(
                        children: [
                          _buildResourceCard(
                            'Total Trombones',
                            GameFormat.intWithSeparators(view.totalPaperclipsProduced),
                            Colors.purple.shade100,
                            onTap: () => _showInfoDialog(
                              context,
                              'Statistiques de Production',
                              'Total produit: ${GameFormat.intWithSeparators(view.totalPaperclipsProduced)}\n'
                                  'Niveau: ${view.level}\n'
                                  'Multiplicateur: x${view.productionMultiplier.toStringAsFixed(2)}',
                            ),
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Stock Trombones',
                            GameFormat.intWithSeparators(view.paperclipsInStock.floor()),
                            Colors.blue.shade100,
                            onTap: () => _showInfoDialog(
                              context,
                              'Stock de Trombones',
                              'Total en stock: ${GameFormat.intWithSeparators(view.paperclipsInStock.floor())}\n'
                                  'Production totale: ${GameFormat.intWithSeparators(view.totalPaperclipsProduced)}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (view.showMarketInfo)
                        Consumer<GameState>(
                          builder: (context, gameState, _) =>
                              _buildMarketInfoCard(context, gameState),
                        ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildResourceCard(
                            'Métal',
                            '${GameFormat.number(view.metal, decimals: 2)} / ${GameFormat.number(view.maxMetalStorage, decimals: 0)}',
                            Colors.grey.shade200,
                            onTap: () {
                              final gameState = context.read<GameState>();
                              _showInfoDialog(
                                context,
                                'Stock de Métal',
                                'Stock: ${GameFormat.number(view.metal, decimals: 2)}\n'
                                    'Capacité: ${GameFormat.number(view.maxMetalStorage, decimals: 0)}\n'
                                    'Prix: ${GameFormat.money(view.currentMetalPrice, decimals: 2)}\n'
                                    'Efficacité: ${((1 - ((gameState.player.upgrades["efficiency"]?.level ?? 0) * 0.15)) * 100).toStringAsFixed(0)}%',
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Prix Vente',
                            GameFormat.money(view.sellPrice, decimals: 2),
                            Colors.green.shade100,
                            onTap: () {
                              final gameState = context.read<GameState>();
                              _showInfoDialog(
                                context,
                                'Prix de Vente',
                                'Prix actuel: ${GameFormat.money(view.sellPrice, decimals: 2)}\n'
                                    'Bonus qualité: +${((gameState.player.upgrades["quality"]?.level ?? 0) * 10)}%\n'
                                    'Impact réputation: x${gameState.market.reputation.toStringAsFixed(2)}',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (view.showMarketInfo)
                        Consumer<GameState>(
                          builder: (context, gameState, _) =>
                              _buildMarketInfoCard(context, gameState),
                        ),
                      if (view.showMarketInfo)
                        const SizedBox(height: 16),

                      if (view.showMetalPurchaseButton) ...[
                        Consumer<GameState>(
                          builder: (context, gameState, _) {
                            return ActionButton.purchase(
                              onPressed: _canPurchaseMetal(gameState)
                                  ? () => context.read<GameState>().purchaseMetal()
                                  : null,
                              label:
                                  'Acheter Métal (${GameFormat.money(gameState.market.currentMetalPrice, decimals: 1)})',
                              showComboMultiplier: true,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (view.showAutoClipperCountSection) ...[
                        Consumer<GameState>(
                          builder: (context, gameState, _) =>
                              _buildAutoclippersSection(context, gameState),
                        ),
                        const SizedBox(height: 16),
                      ],

                      const SaveButton(
                        label: 'Sauvegarder la Partie',
                      ),

                      // Statistiques de production déplacées à la fin
                      if (view.autoClipperCount > 0) ...[
                        const SizedBox(height: 16),
                        Consumer<GameState>(
                          builder: (context, gameState, _) =>
                              _buildProductionStatsCard(gameState),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}