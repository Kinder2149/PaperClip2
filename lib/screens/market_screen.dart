import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../managers/market_manager.dart';
import '../constants/game_config.dart'; // Importé depuis constants au lieu de models
import '../widgets/charts/chart_widgets.dart';
import '../widgets/resources/resource_widgets.dart';
import 'demand_calculation_screen.dart';
import '../screens/sales_history_screen.dart';
import '../widgets/buttons/action_button.dart';
import '../widgets/cards/info_card.dart';
import '../widgets/dialogs/info_dialog.dart';
import '../services/upgrades/upgrade_effects_calculator.dart';
import '../services/progression/progression_rules_service.dart';
import '../services/format/game_format.dart';
import '../services/metrics/game_metrics_service.dart';

class _MarketScreenView {
  final VisibleUiElements visibleElements;
  final bool showMarketPrice;
  final double sellPrice;
  final int marketingLevel;
  final int autoClipperCount;
  final int qualityLevel;
  final int speedLevel;
  final int bulkLevel;

  final double demand;
  final double autoclipperProduction;
  final double effectiveProduction;
  final double profitability;
  final double qualityBonus;
  final double effectiveSellPrice;
  final double reputation;
  final List<SaleRecord> salesHistory;
  final int lastSaleTimestampMs;

  final List<String> productionBonuses;
  final double baseAutoclipperProductionPerSec;
  final double metalPerClip;
  final double currentMetalForClips;
  final double productionDelta;
  final String productionStatus;
  final Color productionStatusColor;

  final String formattedDemandPerSec;
  final String formattedDemandPerMinDisplay;
  final String formattedProductionPerSec;
  final String formattedProductionPerMinDisplay;
  final String formattedSalesPerSec;
  final String formattedSalesPerMinDisplay;
  final String formattedProfitabilityPerSec;
  final String formattedProfitabilityPerMinDisplay;
  final String formattedSellPrice;
  final String formattedEffectiveSellPrice;
  final String formattedReputationPercent;

  const _MarketScreenView({
    required this.visibleElements,
    required this.showMarketPrice,
    required this.sellPrice,
    required this.marketingLevel,
    required this.autoClipperCount,
    required this.qualityLevel,
    required this.speedLevel,
    required this.bulkLevel,

    required this.demand,
    required this.autoclipperProduction,
    required this.effectiveProduction,
    required this.profitability,
    required this.qualityBonus,
    required this.effectiveSellPrice,
    required this.reputation,
    required this.salesHistory,
    required this.lastSaleTimestampMs,

    required this.productionBonuses,
    required this.baseAutoclipperProductionPerSec,
    required this.metalPerClip,
    required this.currentMetalForClips,
    required this.productionDelta,
    required this.productionStatus,
    required this.productionStatusColor,

    required this.formattedDemandPerSec,
    required this.formattedDemandPerMinDisplay,
    required this.formattedProductionPerSec,
    required this.formattedProductionPerMinDisplay,
    required this.formattedSalesPerSec,
    required this.formattedSalesPerMinDisplay,
    required this.formattedProfitabilityPerSec,
    required this.formattedProfitabilityPerMinDisplay,
    required this.formattedSellPrice,
    required this.formattedEffectiveSellPrice,
    required this.formattedReputationPercent,
  });

  @override
  bool operator ==(Object other) {
    return other is _MarketScreenView &&
        other.showMarketPrice == showMarketPrice &&
        other.sellPrice == sellPrice &&
        other.marketingLevel == marketingLevel &&
        other.autoClipperCount == autoClipperCount &&
        other.demand == demand &&
        other.autoclipperProduction == autoclipperProduction &&
        other.effectiveProduction == effectiveProduction &&
        other.profitability == profitability &&
        other.qualityLevel == qualityLevel &&
        other.qualityBonus == qualityBonus &&
        other.effectiveSellPrice == effectiveSellPrice &&
        other.reputation == reputation &&
        other.lastSaleTimestampMs == lastSaleTimestampMs &&
        other.baseAutoclipperProductionPerSec == baseAutoclipperProductionPerSec &&
        other.metalPerClip == metalPerClip &&
        other.currentMetalForClips == currentMetalForClips &&
        other.productionDelta == productionDelta &&
        other.productionStatus == productionStatus;
  }

  @override
  int get hashCode => Object.hash(
        showMarketPrice,
        sellPrice,
        marketingLevel,
        autoClipperCount,
        demand,
        autoclipperProduction,
        effectiveProduction,
        profitability,
        qualityLevel,
        qualityBonus,
        effectiveSellPrice,
        reputation,
        lastSaleTimestampMs,
        baseAutoclipperProductionPerSec,
        metalPerClip,
        currentMetalForClips,
        productionDelta,
        productionStatus,
      );
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  static const GameMetricsService _metricsService = GameMetricsService();

  String _formatUnitsPerSec(double value, {int decimals = 2}) {
    return '${GameFormat.number(value, decimals: decimals)}/sec';
  }

  String _formatUnitsPerMinApprox(double perSec, {int decimals = 1}) {
    return '≈ ${GameFormat.number(perSec * 60.0, decimals: decimals)}/min';
  }

  String _formatMoneyPerSec(double valuePerSec, {int decimals = 2}) {
    return '${GameFormat.money(valuePerSec, decimals: decimals)}/sec';
  }

  Widget _buildMarketCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onInfoPressed,
    Widget? trailing,
  }) {
    // Utilisation du widget InfoCard réutilisable
    return InfoCard(
      title: title,
      value: value,
      icon: icon,
      backgroundColor: color,
      tooltip: tooltip,
      onTap: null, // On préserve le comportement original qui n'a pas de onTap sur la carte entière
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing,
          IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: onInfoPressed,
            tooltip: tooltip,
          ),
        ],
      ),
      // Personnalisation de la taille de police via les paramètres disponibles de InfoCard
      valueFontSize: 16,
      titleFontSize: 14,
    );
  }

  Future<void> _showInfoDialog(BuildContext context, String title, String message) async {
    // Utilisation du widget InfoDialog réutilisable
    // La valeur retournée n'est pas utilisée ici car il s'agit seulement d'un dialogue d'information
    await InfoDialog.show(
      context,
      title: title,
      message: message,
      barrierDismissible: true,
    );
  }

  String _formatBonusText(String name, double bonus) {
    return '$name: ${((bonus - 1.0) * 100).toStringAsFixed(1)}%';
  }

  Widget _buildProductionCard(BuildContext context, GameState gameState, _MarketScreenView view) {
    return _buildMarketCard(
      title: 'Production des Autoclippers',
      value: _formatUnitsPerSec(view.autoclipperProduction, decimals: 2),
      icon: Icons.precision_manufacturing,
      color: Colors.orange.shade100,
      tooltip: 'Production (estimée) avec bonus appliqués',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Production Détaillée',
        'Détails de la production :\n'
            '- Base (${gameState.player.autoClipperCount} autoClipperCount): ${_formatUnitsPerSec(view.baseAutoclipperProductionPerSec, decimals: 2)}\n'
            '  ${_formatUnitsPerMinApprox(view.baseAutoclipperProductionPerSec)}\n'
            '${view.productionBonuses.isNotEmpty ? '\nBonus actifs:\n${view.productionBonuses.join("\n")}\n' : ''}'
            '\nMétal utilisé par trombone: ${view.metalPerClip.toStringAsFixed(2)} unités\n'
            'Comparaison avec la demande du marché:\n'
            '- Production (estimée): ${_formatUnitsPerSec(view.autoclipperProduction, decimals: 2)}\n'
            '  ${_formatUnitsPerMinApprox(view.autoclipperProduction)}\n'
            '- Demande (estimée): ${_formatUnitsPerSec(view.demand, decimals: 2)}\n'
            '  ${_formatUnitsPerMinApprox(view.demand)}\n'
            '- Statut: ${view.productionStatus}\n\n'
            "${view.productionDelta > 0 ? 'ATTENTION: Une surproduction par rapport à la demande implique des trombones non vendus!' : ''}\n"
            "${view.productionDelta < 0 ? 'OPPORTUNITÉ: La demande est supérieure à votre production actuelle. Envisagez d\'augmenter votre capacité!' : ''}",
      ),
      trailing: Text(
        view.productionStatus,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: view.productionStatusColor,
        ),
      ),
    );
  }

  Widget _buildMetalStatus(BuildContext context, GameState gameState, _MarketScreenView view) {
    return _buildMarketCard(
      title: 'Stock de Métal',
      value: '${gameState.player.metal.toStringAsFixed(1)} / ${gameState.player.maxMetalStorage}',
      icon: Icons.inventory_2,
      color: Colors.grey.shade200,
      tooltip: 'Production possible: ${view.currentMetalForClips.toStringAsFixed(0)} trombones',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Stock de Métal',
        'Métal disponible pour la production:\n'
            '- Stock actuel: ${gameState.player.metal.toStringAsFixed(1)} unités\n'
            '- Capacité maximale: ${gameState.player.maxMetalStorage} unités\n'
            '- Prix actuel: ${gameState.market.currentMetalPrice.toStringAsFixed(2)} €\n\n'
            'Production possible:\n'
            '- Métal par trombone: ${view.metalPerClip.toStringAsFixed(2)} unités\n'
            '- Trombones possibles: ${view.currentMetalForClips.toStringAsFixed(0)} unités',
      ),
    );
  }

  Widget _buildPriceControlCard(BuildContext context, _MarketScreenView view) {
    final qualityBonus = view.qualityBonus;

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prix de Vente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      view.formattedSellPrice,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (qualityBonus > 1.0)
                      Text(
                        'Prix effectif: ${view.formattedEffectiveSellPrice}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min: ${GameFormat.money(GameConstants.MIN_PRICE, decimals: 2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Max: ${GameFormat.money(GameConstants.MAX_PRICE, decimals: 2)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    double newValue = view.sellPrice - 0.01;
                    if (newValue >= GameConstants.MIN_PRICE) {
                      context.read<GameState>().setSellPrice(newValue);
                    }
                  },
                ),
                Expanded(
                  child: Slider(
                    value: view.sellPrice,
                    min: GameConstants.MIN_PRICE,
                    max: GameConstants.MAX_PRICE,
                    divisions: 200,
                    label: view.formattedSellPrice,
                    onChanged: (value) => context.read<GameState>().setSellPrice(value),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    double newValue = view.sellPrice + 0.01;
                    if (newValue <= GameConstants.MAX_PRICE) {
                      context.read<GameState>().setSellPrice(newValue);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<GameState, _MarketScreenView>(
      selector: (context, gameState) {
        final visibleElements = gameState.getVisibleUiElements();
        final showMarketPrice = visibleElements[UiElement.marketPrice] == true;
        final sellPrice = gameState.player.sellPrice;
        final marketingLevel = gameState.player.getMarketingLevel();
        final autoClipperCount = gameState.player.autoClipperCount;
        final qualityLevel = gameState.player.upgrades['quality']?.level ?? 0;
        final speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
        final bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;

        final metrics = _metricsService.computeMarket(gameState);

        final demandPerSecEstimated = metrics.demandPerSecondEstimated.value;
        final productionPerSecEstimated = metrics.productionPerSecondEstimated.value;
        final salesPerSecEstimated = metrics.salesPerSecondEstimated.value;
        final profitabilityPerSecEstimated = metrics.revenuePerSecondEstimated.value;

        final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
        final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);
        final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
        final efficiencyBonus = 1.0 - UpgradeEffectsCalculator.efficiencyReduction(level: efficiencyLevel);

        final productionBonuses = <String>[];
        if (speedLevel > 0) {
          productionBonuses.add(_formatBonusText('Vitesse', speedBonus));
        }
        if (bulkLevel > 0) {
          productionBonuses.add(_formatBonusText('Production en masse', bulkBonus));
        }
        if (efficiencyLevel > 0) {
          productionBonuses.add('Efficacité: -${((1.0 - efficiencyBonus) * 100).toStringAsFixed(1)}%');
        }

        final baseAutoclipperProductionPerSec = gameState.player.autoClipperCount *
            GameConstants.BASE_AUTOCLIPPER_PRODUCTION;

        final metalPerClip = UpgradeEffectsCalculator.metalPerPaperclip(
          efficiencyLevel: efficiencyLevel,
        );

        final currentMetalForClips = metalPerClip > 0
            ? (gameState.player.metal / metalPerClip)
            : 0.0;

        final productionDelta = productionPerSecEstimated - demandPerSecEstimated;
        late final String productionStatus;
        late final Color productionStatusColor;
        if (productionDelta > 0) {
          productionStatus = "(Excédent: +${productionDelta.toStringAsFixed(1)})";
          productionStatusColor = Colors.red;
        } else if (productionDelta < 0) {
          productionStatus = "(Déficit: ${productionDelta.toStringAsFixed(1)})";
          productionStatusColor = Colors.green;
        } else {
          productionStatus = "(Équilibrée)";
          productionStatusColor = Colors.black;
        }

        final salesHistory = gameState.market.salesHistory;
        final lastSaleTimestampMs = salesHistory.isEmpty
            ? 0
            : salesHistory.last.timestamp.millisecondsSinceEpoch;

        return _MarketScreenView(
          visibleElements: visibleElements,
          showMarketPrice: showMarketPrice,
          sellPrice: sellPrice,
          marketingLevel: marketingLevel,
          autoClipperCount: autoClipperCount,
          qualityLevel: qualityLevel,
          speedLevel: speedLevel,
          bulkLevel: bulkLevel,

          demand: demandPerSecEstimated,
          autoclipperProduction: productionPerSecEstimated,
          effectiveProduction: salesPerSecEstimated,
          profitability: profitabilityPerSecEstimated,
          qualityBonus: metrics.qualityBonus,
          effectiveSellPrice: metrics.effectiveSellPrice,

          reputation: gameState.marketManager.reputation,
          salesHistory: salesHistory,
          lastSaleTimestampMs: lastSaleTimestampMs,

          productionBonuses: productionBonuses,
          baseAutoclipperProductionPerSec: baseAutoclipperProductionPerSec,
          metalPerClip: metalPerClip,
          currentMetalForClips: currentMetalForClips,
          productionDelta: productionDelta,
          productionStatus: productionStatus,
          productionStatusColor: productionStatusColor,

          formattedDemandPerSec: _formatUnitsPerSec(demandPerSecEstimated, decimals: 2),
          formattedDemandPerMinDisplay: _formatUnitsPerMinApprox(demandPerSecEstimated),
          formattedProductionPerSec: _formatUnitsPerSec(productionPerSecEstimated, decimals: 2),
          formattedProductionPerMinDisplay: _formatUnitsPerMinApprox(productionPerSecEstimated),
          formattedSalesPerSec: _formatUnitsPerSec(salesPerSecEstimated, decimals: 2),
          formattedSalesPerMinDisplay: _formatUnitsPerMinApprox(salesPerSecEstimated),
          formattedProfitabilityPerSec: _formatMoneyPerSec(profitabilityPerSecEstimated, decimals: 2),
          formattedProfitabilityPerMinDisplay: GameFormat.moneyPerMin(
            profitabilityPerSecEstimated * 60.0,
            decimals: 1,
          ),
          formattedSellPrice: GameFormat.money(sellPrice, decimals: 2),
          formattedEffectiveSellPrice: GameFormat.money(metrics.effectiveSellPrice, decimals: 2),
          formattedReputationPercent: GameFormat.percentFromRatio(gameState.marketManager.reputation, decimals: 1),
        );
      },

      builder: (context, view, child) {
        final gameState = context.read<GameState>();

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 12),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Production et Stocks
                      _buildMetalStatus(context, gameState, view),
                      const SizedBox(height: 8),
                      if (view.autoClipperCount > 0)
                        _buildProductionCard(
                          context,
                          gameState,
                          view,
                        ),
                      const SizedBox(height: 12),

                      if (view.showMarketPrice) ...[
                        // Ajout du contrôle du prix de vente en premier
                        _buildPriceControlCard(context, view),
                        const SizedBox(height: 12),

                        Card(
                          elevation: 2,
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.show_chart, color: Colors.deepPurple),
                                    SizedBox(width: 8),
                                    Text(
                                      'Historique des ventes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 220,
                                  child: SalesChartOptimized(
                                    salesHistory: view.salesHistory,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Affichage de la rentabilité estimée avec plus de détails
                        _buildMarketCard(
                          title: 'Rentabilité Estimée',
                          value: '${view.formattedProfitabilityPerSec}\n${view.formattedProfitabilityPerMinDisplay}',
                          icon: Icons.assessment,
                          color: view.autoclipperProduction > view.demand
                              ? Colors.orange.shade100
                              : Colors.indigo.shade100, // Orange si surproduction
                          tooltip: 'Basé sur la production et la demande',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Rentabilité',
                            'Estimation des revenus:\n\n'
                                '• Paramètres de base:\n'
                                '- Prix de vente: ${view.formattedSellPrice}\n'
                                '- Production totale (estimée): ${view.formattedProductionPerSec}\n'
                                '  ${view.formattedProductionPerMinDisplay}\n'
                                '- Demande du marché (estimée): ${view.formattedDemandPerSec}\n'
                                '  ${view.formattedDemandPerMinDisplay}\n\n'
                                '• Ventes effectives (estimées): ${view.formattedSalesPerSec}\n'
                                '  ${view.formattedSalesPerMinDisplay}\n'
                                '(= le minimum entre votre production et la demande du marché)\n\n'
                                '• Calcul des revenus:\n'
                                '- Ventes effectives × Prix de vente\n'
                                '- ${GameFormat.number(view.effectiveProduction, decimals: 2)} × ${view.formattedSellPrice} = ${view.formattedProfitabilityPerSec}\n'
                                '  ${view.formattedProfitabilityPerMinDisplay}\n\n'
                                '${view.autoclipperProduction > view.demand ? "⚠️ ALERTE: Vous produisez plus que la demande estimée!\nSeules ${view.formattedDemandPerSec} (${view.formattedDemandPerMinDisplay}) seront vendues." : ""}\n'
                                '${view.demand > view.autoclipperProduction ? "💡 CONSEIL: La demande estimée (${view.formattedDemandPerSec}) dépasse votre production (${view.formattedProductionPerSec}).\nVous pourriez augmenter vos revenus en développant votre production." : ""}',
                          ),
                          trailing: view.autoclipperProduction > view.demand
                              ? const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange)
                              : (view.demand > view.autoclipperProduction
                                  ? const Icon(Icons.lightbulb,
                                      color: Colors.green)
                                  : null),
                        ),
                        const SizedBox(height: 8),

                        // Affichage des autres cartes ensuite
                        _buildMarketCard(
                          title: 'Demande du Marché',
                          value: '${view.formattedDemandPerSec}\n${view.formattedDemandPerMinDisplay}',
                          icon: Icons.trending_up,
                          color: Colors.amber.shade100,
                          tooltip: 'Demande actuelle',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Demande du Marché',
                            'Demande (estimée): ${view.formattedDemandPerSec}\n'
                                '${view.formattedDemandPerMinDisplay}\n\n'
                                'Ventes effectives (estimées): ${view.formattedSalesPerSec}\n'
                                '${view.formattedSalesPerMinDisplay}',
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildMarketCard(
                          title: 'Réputation',
                          value: view.formattedReputationPercent,
                          icon: Icons.star,
                          color: Colors.blue.shade100,
                          tooltip: 'Influence la demande globale',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Réputation',
                            'La réputation influence directement la demande du marché.\n'
                                'Une meilleure réputation augmente les ventes potentielles.',
                          ),
                        ),
                      const SizedBox(height: 8),

                      _buildMarketCard(
                        title: 'Marketing',
                        value: 'Niveau ${view.marketingLevel}',
                        icon: Icons.campaign,
                        color: Colors.cyan.shade100,
                        tooltip: 'Augmente la visibilité',
                        onInfoPressed: () => _showInfoDialog(
                          context,
                          'Marketing',
                          'Le niveau de marketing augmente la demande de base.\n'
                              'Chaque niveau ajoute +${(GameConstants.MARKETING_BOOST_PER_LEVEL * 100).toStringAsFixed(0)}% à la demande.',
                        ),
                      ),  
                      const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DemandCalculationScreen()),
                      ),
                      icon: Icons.calculate,
                      label: 'Calculateur',
                      backgroundColor: Colors.blue,
                      textColor: Colors.white,
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (view.showMarketPrice)
                    Expanded(
                      child: ActionButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SalesHistoryScreen()),
                        ),
                        icon: Icons.history,
                        label: 'Historique',
                        backgroundColor: Colors.purple,
                        textColor: Colors.white,
                        fullWidth: true,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
// Cette méthode a été remplacée par le widget ActionButton réutilisable
}