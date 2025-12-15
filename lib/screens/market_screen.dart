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
import '../services/market/market_insights_service.dart';

class _MarketScreenView {
  final VisibleUiElements visibleElements;
  final bool showMarketPrice;
  final double sellPrice;
  final int marketingLevel;
  final int autoClipperCount;
  final double demand;
  final double autoclipperProduction;
  final double effectiveProduction;
  final double profitability;
  final int qualityLevel;
  final double qualityBonus;
  final double effectiveSellPrice;
  final double reputation;
  final List<SaleRecord> salesHistory;
  final int lastSaleTimestampMs;

  final String formattedDemandPerMin;
  final String formattedProductionPerMin;
  final String formattedSalesPerMin;
  final String formattedProfitabilityPerMin;
  final String formattedSellPrice;
  final String formattedEffectiveSellPrice;
  final String formattedReputationPercent;

  const _MarketScreenView({
    required this.visibleElements,
    required this.showMarketPrice,
    required this.sellPrice,
    required this.marketingLevel,
    required this.autoClipperCount,
    required this.demand,
    required this.autoclipperProduction,
    required this.effectiveProduction,
    required this.profitability,
    required this.qualityLevel,
    required this.qualityBonus,
    required this.effectiveSellPrice,
    required this.reputation,
    required this.salesHistory,
    required this.lastSaleTimestampMs,
    required this.formattedDemandPerMin,
    required this.formattedProductionPerMin,
    required this.formattedSalesPerMin,
    required this.formattedProfitabilityPerMin,
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
        other.lastSaleTimestampMs == lastSaleTimestampMs;
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
      );
}

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  static const MarketInsightsService _insightsService = MarketInsightsService();

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

  Widget _buildProductionCard(BuildContext context, GameState gameState, double autoclipperProduction, double demand) {
    List<String> bonuses = [];

    // Calcul des bonus
    final speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
    final bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;
    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;

    final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
    final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);
    final efficiencyBonus = 1.0 - UpgradeEffectsCalculator.efficiencyReduction(level: efficiencyLevel);

    if (speedLevel > 0) {
      bonuses.add(_formatBonusText('Vitesse', speedBonus));
    }
    if (bulkLevel > 0) {
      bonuses.add(_formatBonusText('Production en masse', bulkBonus));
    }
    if (efficiencyLevel > 0) {
      bonuses.add('Efficacité: -${((1.0 - efficiencyBonus) * 100).toStringAsFixed(1)}%');
    }

    double baseProduction = gameState.player.autoClipperCount *
        (GameConstants.BASE_AUTOCLIPPER_PRODUCTION * 60.0);

    final metalPerClip = UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );

    // Statut de production (excédent ou déficit)
    double productionDelta = autoclipperProduction - demand;
    String productionStatus;
    Color statusColor;

    if (productionDelta > 0) {
      productionStatus = "(Excédent: +${productionDelta.toStringAsFixed(1)})";
      statusColor = Colors.red; // Rouge pour surproduction
    } else if (productionDelta < 0) {
      productionStatus = "(Déficit: ${productionDelta.toStringAsFixed(1)})";
      statusColor = Colors.green; // Vert pour capacité insuffisante = opportunité
    } else {
      productionStatus = "(Équilibrée)";
      statusColor = Colors.black; // Équilibrée
    }

    return _buildMarketCard(
      title: 'Production des Autoclippers',
      value: '${GameFormat.number(autoclipperProduction, decimals: 1)}/min',
      icon: Icons.precision_manufacturing,
      color: Colors.orange.shade100,
      tooltip: 'Production avec bonus appliqués',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Production Détaillée',
        'Détails de la production :\n'
            '- Base (${gameState.player.autoClipperCount} autoClipperCount): ${baseProduction.toStringAsFixed(1)}/min\n'
            '${bonuses.isNotEmpty ? '\nBonus actifs:\n${bonuses.join("\n")}\n' : ''}'
            '\nMétal utilisé par trombone: ${metalPerClip.toStringAsFixed(2)} unités\n'
            '(Efficacité: -${((1.0 - efficiencyBonus) * 100).toStringAsFixed(1)}%)\n\n'
            'Comparaison avec la demande du marché:\n'
            '- Production: ${autoclipperProduction.toStringAsFixed(1)}/min\n'
            '- Demande: ${demand.toStringAsFixed(1)}/min\n'
            '- Statut: $productionStatus\n\n'
            "${productionDelta > 0 ? 'ATTENTION: Une surproduction par rapport à la demande implique des trombones non vendus!' : ''}\n"
            "${productionDelta < 0 ? 'OPPORTUNITÉ: La demande est supérieure à votre production actuelle. Envisagez d\'augmenter votre capacité!' : ''}",
      ),
      trailing: Text(
        productionStatus,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    );
  }

  Widget _buildMetalStatus(BuildContext context, GameState gameState) {
    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
    final metalPerClip = UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );

    double currentMetalForClips = gameState.player.metal / metalPerClip;

    return _buildMarketCard(
      title: 'Stock de Métal',
      value: '${gameState.player.metal.toStringAsFixed(1)} / ${gameState.player.maxMetalStorage}',
      icon: Icons.inventory_2,
      color: Colors.grey.shade200,
      tooltip: 'Production possible: ${currentMetalForClips.toStringAsFixed(0)} trombones',
      onInfoPressed: () => _showInfoDialog(
        context,
        'Stock de Métal',
        'Métal disponible pour la production:\n'
            '- Stock actuel: ${gameState.player.metal.toStringAsFixed(1)} unités\n'
            '- Capacité maximale: ${gameState.player.maxMetalStorage} unités\n'
            '- Prix actuel: ${gameState.market.currentMetalPrice.toStringAsFixed(2)} €\n\n'
            'Production possible:\n'
            '- Métal par trombone: ${metalPerClip.toStringAsFixed(2)} unités\n'
            '- Trombones possibles: ${currentMetalForClips.toStringAsFixed(0)} unités',
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

        final insights = _insightsService.compute(
          market: gameState.market,
          input: MarketInsightsInput(
            sellPrice: sellPrice,
            marketingLevel: marketingLevel,
            autoClipperCount: autoClipperCount,
            speedLevel: speedLevel,
            bulkLevel: bulkLevel,
            qualityLevel: qualityLevel,
          ),
        );

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
          demand: insights.demandPerMin,
          autoclipperProduction: insights.productionPerMin,
          effectiveProduction: insights.effectiveSalesPerMin,
          profitability: insights.profitabilityPerMin,
          qualityLevel: qualityLevel,
          qualityBonus: insights.qualityBonus,
          effectiveSellPrice: insights.effectiveSellPrice,
          reputation: gameState.marketManager.reputation,
          salesHistory: salesHistory,
          lastSaleTimestampMs: lastSaleTimestampMs,
          formattedDemandPerMin:
              '${GameFormat.number(insights.demandPerMin, decimals: 1)}/min',
          formattedProductionPerMin:
              '${GameFormat.number(insights.productionPerMin, decimals: 1)}/min',
          formattedSalesPerMin:
              '${GameFormat.number(insights.effectiveSalesPerMin, decimals: 1)}/min',
          formattedProfitabilityPerMin: GameFormat.moneyPerMin(
            insights.profitabilityPerMin,
            decimals: 1,
          ),
          formattedSellPrice: GameFormat.money(sellPrice, decimals: 2),
          formattedEffectiveSellPrice:
              GameFormat.money(insights.effectiveSellPrice, decimals: 2),
          formattedReputationPercent:
              GameFormat.percentFromRatio(gameState.marketManager.reputation, decimals: 1),
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
                      _buildMetalStatus(context, gameState),
                      const SizedBox(height: 8),
                      if (view.autoClipperCount > 0)
                        _buildProductionCard(
                          context,
                          gameState,
                          view.autoclipperProduction,
                          view.demand,
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
                          value: view.formattedProfitabilityPerMin,
                          icon: Icons.assessment,
                          color: view.autoclipperProduction > view.demand
                              ? Colors.orange.shade100
                              : Colors.indigo.shade100, // Orange si surproduction
                          tooltip: 'Basé sur la production et la demande',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Rentabilité',
                            'Estimation des revenus par minute:\n\n'
                                '• Paramètres de base:\n'
                                '- Prix de vente: ${view.formattedSellPrice}\n'
                                '- Production totale: ${GameFormat.number(view.autoclipperProduction, decimals: 1)} unités/min\n'
                                '- Demande du marché: ${GameFormat.number(view.demand, decimals: 1)} unités/min\n\n'
                                '• Production effective: ${GameFormat.number(view.effectiveProduction, decimals: 1)} unités/min\n'
                                '(= le minimum entre votre production et la demande du marché)\n\n'
                                '• Calcul des revenus:\n'
                                '- Production effective × Prix de vente\n'
                                '- ${view.effectiveProduction.toStringAsFixed(1)} × ${view.formattedSellPrice} = ${view.formattedProfitabilityPerMin}\n\n'
                                '${view.autoclipperProduction > view.demand ? "⚠️ ALERTE: Vous produisez plus que la demande actuelle!\nSeules ${GameFormat.number(view.demand, decimals: 1)} unités sur ${GameFormat.number(view.autoclipperProduction, decimals: 1)} seront vendues." : ""}\n'
                                '${view.demand > view.autoclipperProduction ? "💡 CONSEIL: La demande (${GameFormat.number(view.demand, decimals: 1)}) dépasse votre capacité de production (${GameFormat.number(view.autoclipperProduction, decimals: 1)}).\nVous pourriez augmenter vos revenus en développant votre production." : ""}',
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
                          value: view.formattedDemandPerMin,
                          icon: Icons.trending_up,
                          color: Colors.amber.shade100,
                          tooltip: 'Demande actuelle',
                          onInfoPressed: () => _showInfoDialog(
                            context,
                            'Demande du Marché',
                            'Demande actuelle: ${GameFormat.number(view.demand, decimals: 1)} unités/min\n'
                                'Production effective: ${GameFormat.number(view.effectiveProduction, decimals: 1)} unités/min',
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