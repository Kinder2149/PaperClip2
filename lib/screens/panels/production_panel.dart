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
    final metalPrice = gameState.marketManager.marketMetalPrice;

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
              label: 'Prix du métal',
              value: '${metalPrice.toStringAsFixed(3)} €/kg',
              color: Colors.brown,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualProduction(GameState gameState) {
    final canProduce = gameState.resourceManager.canPurchaseMetal();
    final metalPrice = gameState.marketManager.marketMetalPrice;
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
              onPressed: () => gameState.productionManager.producePaperclip(),
              color: Colors.blue,
            ),
            DesignTokens.mediumGap,
            ActionButton(
              emoji: '⚙️',
              label: 'Acheter Métal (${(metalAmount * metalPrice).toStringAsFixed(2)} €)',
              onPressed: canProduce ? () => gameState.resourceManager.purchaseMetal() : null,
              color: Colors.grey.shade700,
              isCompact: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoProduction(GameState gameState) {
    final cost = gameState.productionManager.calculateAutoclipperCost();
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
