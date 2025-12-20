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
import '../services/game_actions.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/format/game_format.dart';
import '../services/metrics/game_metrics_service.dart';

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

  final double demandPerSecEstimated;
  final String formattedDemandPerSec;
  final String formattedDemandPerMinDisplay;
  final String formattedReputation;

  final double baseProductionPerSecEstimated;
  final double actualProductionPerSecEstimated;
  final double metalUsagePerSecEstimated;
  final double metalSavedPerSecEstimated;
  final double metalSavingPercent;
  final double speedBonusPercent;
  final double bulkBonusPercent;

  final double paybackSecondsEstimated;
  final double autoclipperCost;
  final bool canBuyAutoclipper;

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

    required this.demandPerSecEstimated,
    required this.formattedDemandPerSec,
    required this.formattedDemandPerMinDisplay,
    required this.formattedReputation,

    required this.baseProductionPerSecEstimated,
    required this.actualProductionPerSecEstimated,
    required this.metalUsagePerSecEstimated,
    required this.metalSavedPerSecEstimated,
    required this.metalSavingPercent,
    required this.speedBonusPercent,
    required this.bulkBonusPercent,

    required this.paybackSecondsEstimated,
    required this.autoclipperCost,
    required this.canBuyAutoclipper,
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
        other.autoClipperCount == autoClipperCount &&

        other.demandPerSecEstimated == demandPerSecEstimated &&
        other.formattedDemandPerSec == formattedDemandPerSec &&
        other.formattedDemandPerMinDisplay == formattedDemandPerMinDisplay &&
        other.formattedReputation == formattedReputation &&

        other.baseProductionPerSecEstimated == baseProductionPerSecEstimated &&
        other.actualProductionPerSecEstimated == actualProductionPerSecEstimated &&
        other.metalUsagePerSecEstimated == metalUsagePerSecEstimated &&
        other.metalSavedPerSecEstimated == metalSavedPerSecEstimated &&
        other.metalSavingPercent == metalSavingPercent &&
        other.speedBonusPercent == speedBonusPercent &&
        other.bulkBonusPercent == bulkBonusPercent &&
        other.paybackSecondsEstimated == paybackSecondsEstimated &&
        other.autoclipperCost == autoclipperCost &&
        other.canBuyAutoclipper == canBuyAutoclipper;
  }

  @override
  int get hashCode => Object.hashAll([
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

        demandPerSecEstimated,
        formattedDemandPerSec,
        formattedDemandPerMinDisplay,
        formattedReputation,

        baseProductionPerSecEstimated,
        actualProductionPerSecEstimated,
        metalUsagePerSecEstimated,
        metalSavedPerSecEstimated,
        metalSavingPercent,
        speedBonusPercent,
        bulkBonusPercent,
        paybackSecondsEstimated,
        autoclipperCost,
        canBuyAutoclipper,
      ]);
}

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  static const GameMetricsService _metricsService = GameMetricsService();

  double _perMinFromPerSec(double perSec) => perSec * 60.0;

  Widget _buildResourceCard(
    String title,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InfoCard(
        title: title,
        value: value,
        backgroundColor: color,
        onTap: onTap,
      ),
    );
  }

  Future<void> _showInfoDialog(BuildContext context, String title, String message) async {
    await InfoDialog.show(
      context,
      title: title,
      message: message,
      barrierDismissible: true,
    );
  }

  bool _canPurchaseMetal(GameState gameState) {
    return gameState.canBuyMetal();
  }

  String _formatUnitsPerSec(double value, {int decimals = 2}) {
    return '${GameFormat.number(value, decimals: decimals)}/sec';
  }

  String _formatUnitsPerMinApprox(double perSec, {int decimals = 1}) {
    return '≈ ${GameFormat.number(_perMinFromPerSec(perSec), decimals: decimals)}/min';
  }

  String _formatMoneyPerSec(double valuePerSec, {int decimals = 2}) {
    return '${GameFormat.money(valuePerSec, decimals: decimals)}/sec';
  }

  String _formatMoneyPerMinApprox(double perSec, {int decimals = 2}) {
    return '≈ ${GameFormat.money(_perMinFromPerSec(perSec), decimals: decimals)}/min';
  }

  Widget _buildAutoclippersSection(BuildContext context, GameState gameState, _ProductionScreenView view) {
    final bulkBonus = view.bulkBonusPercent;
    final speedBonus = view.speedBonusPercent;
    final metalSavingPercent = view.metalSavingPercent;

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
                        'Autoclippers: ${view.autoClipperCount}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        view.paybackSecondsEstimated.isFinite
                            ? 'Temps de retour: ≈ ${GameFormat.number(view.paybackSecondsEstimated, decimals: 0)} sec (estimé)'
                            : 'Temps de retour: —',
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
                  onPressed: () => _showAutoclipperInfoDialog(
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
              onPressed: view.canBuyAutoclipper
                  ? () => context.read<GameActions>().buyAutoclipper()
                  : null,
              label: 'Acheter Autoclipper (${GameFormat.money(view.autoclipperCost, decimals: 1)})',
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
    final double baseProductionPerSec = gameState.player.autoClipperCount *
        GameConstants.BASE_AUTOCLIPPER_PRODUCTION;
    double speedMultiplier = 1.0 + (speedBonus / 100);
    double bulkMultiplier = 1.0 + (bulkBonus / 100);
    final double effectiveProductionPerSec =
        baseProductionPerSec * speedMultiplier * bulkMultiplier;

    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
    final metalPerPaperclip = UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );

    final double effectiveMetalConsumptionPerSec =
        effectiveProductionPerSec * metalPerPaperclip;
    final double metalSavedPerSec =
        effectiveProductionPerSec * GameConstants.METAL_PER_PAPERCLIP - effectiveMetalConsumptionPerSec;

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
                        TextSpan(text: '${_formatUnitsPerSec(baseProductionPerSec, decimals: 2)}\n'),
                        TextSpan(text: '  ${_formatUnitsPerMinApprox(baseProductionPerSec)}\n'),
                        const TextSpan(text: 'Avec améliorations: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '${_formatUnitsPerSec(effectiveProductionPerSec, decimals: 2)}\n'),
                        TextSpan(text: '  ${_formatUnitsPerMinApprox(effectiveProductionPerSec)}'),
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
                        TextSpan(text: '${_formatUnitsPerSec(effectiveMetalConsumptionPerSec, decimals: 2)}\n'),
                        TextSpan(text: '  ${_formatUnitsPerMinApprox(effectiveMetalConsumptionPerSec, decimals: 1)}\n'),
                        const TextSpan(text: 'Économie de métal: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(
                          text: '-${GameFormat.number(metalSavingPercent, decimals: 0)}% (${_formatUnitsPerSec(metalSavedPerSec, decimals: 2)} / ${_formatUnitsPerMinApprox(metalSavedPerSec, decimals: 1)})',
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
                          text: '${_formatMoneyPerSec(gameState.maintenanceCosts, decimals: 2)}\n',
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        TextSpan(text: '  ${_formatMoneyPerMinApprox(gameState.maintenanceCosts, decimals: 2)}'),
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
      double baseProductionPerSec, double actualProductionPerSec, double metalUsagePerSec, 
      double metalSavedPerSec, double metalSavingPercent) {
    
    // Calculer le pourcentage d'augmentation de la production
    double productionIncrease = baseProductionPerSec > 0 ? 
        ((actualProductionPerSec - baseProductionPerSec) / baseProductionPerSec * 100) : 0;

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
                    TextSpan(text: '${_formatUnitsPerSec(baseProductionPerSec, decimals: 2)}\n'),
                    TextSpan(text: '  ${_formatUnitsPerMinApprox(baseProductionPerSec)}\n'),
                    const TextSpan(text: 'Effective: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: '${_formatUnitsPerSec(actualProductionPerSec, decimals: 2)} ',
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
                    TextSpan(text: '${_formatUnitsPerSec(metalUsagePerSec, decimals: 2)}\n'),
                    TextSpan(text: '  ${_formatUnitsPerMinApprox(metalUsagePerSec, decimals: 1)}\n'),
                    const TextSpan(text: 'Économie: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(
                      text: metalSavingPercent > 0 ? 
                        '${_formatUnitsPerSec(metalSavedPerSec, decimals: 2)} ' : 
                        '0',
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

  void _showMarketInfoDialog(BuildContext context, GameState gameState, _ProductionScreenView view) {
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
                  Text('Demande (estimée): ${view.formattedDemandPerSec}'),
                  Text(
                    view.formattedDemandPerMinDisplay,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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

  Widget _buildMarketInfoCard(BuildContext context, GameState gameState, _ProductionScreenView view) {
    // Utilisation du nouveau widget StatsPanel
    return StatsPanel(
      title: 'État du Marché',
      titleIcon: Icons.trending_up,
      backgroundColor: Colors.teal.shade100,
      // Le paramètre trailing n'est pas supporté, nous utilisons action à la place
      action: IconButton(
        icon: const Icon(Icons.info_outline),
        onPressed: () => _showMarketInfoDialog(context, gameState, view),
        iconSize: 20,
      ),
      children: [
        StatIndicator(
          label: 'Réputation',
          value: view.formattedReputation,
          icon: Icons.star,
        ),
        StatIndicator(
          label: 'Demande',
          value: view.formattedDemandPerSec,
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

  Widget _buildProductionStatsCard(BuildContext context, GameState gameState, _ProductionScreenView view) {
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
            value: _formatUnitsPerSec(view.baseProductionPerSecEstimated, decimals: 2),
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
            value: _formatUnitsPerSec(view.actualProductionPerSecEstimated, decimals: 2),
            icon: Icons.precision_manufacturing,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.green,
            valueStyle: TextStyle(
              color: view.actualProductionPerSecEstimated > view.baseProductionPerSecEstimated ? Colors.green : Colors.black,
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
            value: view.metalSavingPercent > 0 ? 
              '-${GameFormat.number(view.metalSavingPercent, decimals: 0)}%' : 
              '0%',
            icon: Icons.eco,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.green[700],
            valueStyle: TextStyle(
              color: view.metalSavingPercent > 0 ? Colors.green[700]! : Colors.black,
              fontWeight: FontWeight.bold,
            ),
            // tooltip: 'Réduction de la consommation de métal par trombone',
          ),
        ),
        // Métal utilisé par seconde
        SizedBox(
          width: 160,
          child: StatIndicator(
            label: 'Métal utilisé',
            value: _formatUnitsPerSec(view.metalUsagePerSecEstimated, decimals: 2),
            icon: Icons.settings_input_component,
            layout: StatIndicatorLayout.vertical,
            iconColor: Colors.orange[700],
            // tooltip: 'Quantité de métal consommée par seconde pour la production',
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
            value: '+${GameFormat.number(view.speedBonusPercent, decimals: 0)}%',
            icon: Icons.shutter_speed,
            layout: StatIndicatorLayout.horizontal,
            iconColor: Colors.blue[400],
            valueStyle: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
            // tooltip: 'Augmentation de la vitesse de production',
          ),
          StatIndicator(
            label: 'Production',
            value: '+${GameFormat.number(view.bulkBonusPercent, decimals: 0)}%',
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
        value: '${_formatMoneyPerSec(gameState.maintenanceCosts, decimals: 2)}\n'
            '${_formatMoneyPerMinApprox(gameState.maintenanceCosts, decimals: 2)}',
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
          view.baseProductionPerSecEstimated,
          view.actualProductionPerSecEstimated,
          view.metalUsagePerSecEstimated,
          view.metalSavedPerSecEstimated,
          view.metalSavingPercent),
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

        final metrics = _metricsService.computeProduction(gameState);

        final demandPerSecEstimated = metrics.demandPerSecondEstimated.value;

        final formattedDemandPerSec = _formatUnitsPerSec(demandPerSecEstimated, decimals: 2);
        final formattedDemandPerMinDisplay = _formatUnitsPerMinApprox(demandPerSecEstimated);
        final formattedReputation = GameFormat.number(gameState.market.reputation, decimals: 2);

        final speedLevel = (gameState.player.upgrades['speed']?.level ?? 0);
        final bulkLevel = (gameState.player.upgrades['bulk']?.level ?? 0);

        final metalSavingPercent = metrics.metalSavingRatio.toPercent();
        final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
        final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);

        final baseProductionPerSecEstimated = metrics.baseProductionPerSecondEstimated.value;
        final actualProductionPerSecEstimated = metrics.actualProductionPerSecondEstimated.value;

        final metalUsagePerSecEstimated = metrics.metalUsagePerSecondEstimated.value;
        final metalSavedPerSecEstimated = metrics.metalSavedPerSecondEstimated.value;

        final roi = gameState.player.calculateAutoclipperROI();
        final paybackSecondsEstimated = roi > 0 ? (6000.0 / roi) : double.infinity;

        final autoclipperCost = gameState.productionManager.calculateAutoclipperCost();
        final canBuyAutoclipper = gameState.productionManager.canBuyAutoclipper();

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

          demandPerSecEstimated: demandPerSecEstimated,
          formattedDemandPerSec: formattedDemandPerSec,
          formattedDemandPerMinDisplay: formattedDemandPerMinDisplay,
          formattedReputation: formattedReputation,

          baseProductionPerSecEstimated: baseProductionPerSecEstimated,
          actualProductionPerSecEstimated: actualProductionPerSecEstimated,
          metalUsagePerSecEstimated: metalUsagePerSecEstimated,
          metalSavedPerSecEstimated: metalSavedPerSecEstimated,
          metalSavingPercent: metalSavingPercent,

          speedBonusPercent: ((speedBonus - 1.0) * 100),
          bulkBonusPercent: ((bulkBonus - 1.0) * 100),

          paybackSecondsEstimated: paybackSecondsEstimated,
          autoclipperCost: autoclipperCost,
          canBuyAutoclipper: canBuyAutoclipper,
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
                          context.read<GameActions>().setAutoSellEnabled(value);
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
                        _buildMarketInfoCard(context, context.read<GameState>(), view),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          _buildResourceCard(
                            'Métal',
                            '${GameFormat.number(view.metal, decimals: 2)} / ${GameFormat.number(view.maxMetalStorage, decimals: 0)}',
                            Colors.grey.shade200,
                            onTap: () {
                              _showInfoDialog(
                                context,
                                'Stock de Métal',
                                'Stock: ${GameFormat.number(view.metal, decimals: 2)}\n'
                                    'Capacité: ${GameFormat.number(view.maxMetalStorage, decimals: 0)}\n'
                                    'Prix: ${GameFormat.money(view.currentMetalPrice, decimals: 2)}\n'
                                    'Efficacité: -${GameFormat.number(view.metalSavingPercent, decimals: 0)}%',
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          _buildResourceCard(
                            'Prix Vente',
                            GameFormat.money(view.sellPrice, decimals: 2),
                            Colors.green.shade100,
                            onTap: () {
                              _showInfoDialog(
                                context,
                                'Prix de Vente',
                                'Prix actuel: ${GameFormat.money(view.sellPrice, decimals: 2)}\n'
                                    'Bonus qualité: +${((context.read<GameState>().player.upgrades["quality"]?.level ?? 0) * 10)}%\n'
                                    'Impact réputation: x${context.read<GameState>().market.reputation.toStringAsFixed(2)}',
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (view.showMetalPurchaseButton) ...[
                        ActionButton.purchase(
                          onPressed: _canPurchaseMetal(context.read<GameState>())
                              ? () => context.read<GameActions>().purchaseMetal()
                              : null,
                          label: () {
                            final unitPrice = context.select((GameState gs) => gs.market.currentMetalPrice);
                            final pack = GameConstants.METAL_PACK_AMOUNT;
                            final total = unitPrice * pack;
                            return 'Acheter Métal (+${GameFormat.number(pack, decimals: 0)}) (${GameFormat.money(total, decimals: 2)})';
                          }(),
                          showComboMultiplier: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (view.showAutoClipperCountSection) ...[
                        _buildAutoclippersSection(context, context.read<GameState>(), view),
                        const SizedBox(height: 16),
                      ],

                      const SaveButton(
                        label: 'Sauvegarder la Partie',
                      ),

                      // Statistiques de production déplacées à la fin
                      if (view.autoClipperCount > 0) ...[
                        const SizedBox(height: 16),
                        _buildProductionStatsCard(context, context.read<GameState>(), view),
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