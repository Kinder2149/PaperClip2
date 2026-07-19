import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';
import 'package:paperclip2/constants/game_config.dart';

/// Panel de production - Interface principale pour créer des trombones
class ProductionPanel extends StatefulWidget {
  const ProductionPanel({Key? key}) : super(key: key);

  @override
  State<ProductionPanel> createState() => _ProductionPanelState();
}

class _ProductionPanelState extends State<ProductionPanel> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(gameState),
              DesignTokens.sectionGap,
              _buildProductionStats(gameState),
              DesignTokens.sectionGap,
              _buildManualProduction(gameState),
              DesignTokens.sectionGap,
              _buildAutoProduction(gameState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(GameState gameState) {
    return PanelHeader(
      emoji: '📎',
      title: 'Production de Trombones',
      metrics: [
        MetricData(
          label: 'En stock',
          value: gameState.playerManager.paperclips.toStringAsFixed(0),
          color: Colors.blue,
        ),
        MetricData(
          label: 'Total produit',
          value: gameState.statistics.totalPaperclipsProduced.toString(),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildProductionStats(GameState gameState) {
    final productionRate = gameState.productionManager.currentProductionRatePerSecond;
    final metalPrice = gameState.effectiveMetalUnitPrice;
    final bonuses = gameState.activeProductionBonuses;
    final metalEfficiency = bonuses['metalEfficiency'] ?? 0.0;
    final productionSpeed = bonuses['productionSpeed'] ?? 0.0;
    final productionBulk = bonuses['productionBulk'] ?? 0.0;
    final metalPurchaseDiscount = bonuses['metalPurchaseDiscount'] ?? 0.0;
    final hasActiveBonus =
        metalEfficiency > 0.0 ||
        productionSpeed > 0.0 ||
        productionBulk > 0.0 ||
        metalPurchaseDiscount > 0.0;

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              emoji: '📊',
              title: 'Statistiques',
            ),
            DesignTokens.sectionGap,
            StatCard(
              emoji: '🤖',
              label: 'Autoclippers',
              value: '${gameState.playerManager.autoClipperCount}',
              color: Colors.purple,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '⚡',
              label: 'Production',
              value: '${productionRate.toStringAsFixed(1)} trombones/s',
              color: Colors.blue,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '⚙️',
              label: 'Métal disponible',
              value: '${gameState.playerManager.metal.toStringAsFixed(2)} kg',
              color: Colors.grey,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '💲',
              label: 'Prix effectif du métal',
              value: '${metalPrice.toStringAsFixed(3)} €/kg',
              color: Colors.brown,
            ),
            if (hasActiveBonus) ...[
              if (metalEfficiency > 0.0) ...[
                DesignTokens.mediumGap,
                StatCard(
                  emoji: '⚡',
                  label: 'Efficacité métal totale',
                  value: '-${(metalEfficiency * 100).toStringAsFixed(0)} %',
                  color: Colors.indigo,
                ),
              ],
              if (productionSpeed > 0.0) ...[
                DesignTokens.mediumGap,
                StatCard(
                  emoji: '🚀',
                  label: 'Vitesse production totale',
                  value: '+${(productionSpeed * 100).toStringAsFixed(0)} %',
                  color: Colors.blueAccent,
                ),
              ],
              if (productionBulk > 0.0) ...[
                DesignTokens.mediumGap,
                StatCard(
                  emoji: '📦',
                  label: 'Production en masse',
                  value: '+${(productionBulk * 100).toStringAsFixed(0)} %',
                  color: Colors.deepPurple,
                ),
              ],
              if (metalPurchaseDiscount > 0.0) ...[
                DesignTokens.mediumGap,
                StatCard(
                  emoji: '🛒',
                  label: 'Remise achat métal totale',
                  value: '-${(metalPurchaseDiscount * 100).toStringAsFixed(0)} %',
                  color: Colors.green,
                ),
              ],
            ] else ...[
              DesignTokens.mediumGap,
              const Text(
                'Aucun bonus actif — débloquez des recherches pour voir les effets ici',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualProduction(GameState gameState) {
    final canProduce = gameState.canBuyMetal();
    final canCreatePaperclip = gameState.playerManager.metal > 0;
    final metalPrice = gameState.effectiveMetalUnitPrice;
    final metalAmount = GameConstants.METAL_PACK_AMOUNT;
    
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              emoji: '✋',
              title: 'Production Manuelle',
            ),
            DesignTokens.sectionGap,
            ActionButton(
              emoji: '📎',
              label: 'Créer un trombone',
              onPressed: canCreatePaperclip ? () => gameState.producePaperclip() : null,
              color: Colors.blue,
            ),
            if (!canCreatePaperclip) ...[
              DesignTokens.smallGap,
              Text(
                'Achetez du métal pour produire',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            DesignTokens.mediumGap,
            ActionButton(
              emoji: '⚙️',
              label: 'Acheter Métal (${(metalAmount * metalPrice).toStringAsFixed(2)} €)',
              onPressed: canProduce ? () => gameState.purchaseMetal() : null,
              color: Colors.grey.shade700,
              isCompact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoProduction(GameState gameState) {
    final cost = gameState.effectiveAutoclipperCost;
    final canBuy = gameState.productionManager.canBuyAutoclipper();

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              emoji: '🤖',
              title: 'Production Automatique',
            ),
            DesignTokens.sectionGap,
            ActionButton(
              emoji: '🤖',
              label: 'Acheter Autoclipper (${cost.toStringAsFixed(0)} €)',
              onPressed: canBuy ? () => gameState.productionManager.buyAutoclipper() : null,
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }
}
