import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel marché - Vente de trombones
class MarketPanel extends StatefulWidget {
  const MarketPanel({Key? key}) : super(key: key);

  @override
  State<MarketPanel> createState() => _MarketPanelState();
}

class _MarketPanelState extends State<MarketPanel> with AutomaticKeepAliveClientMixin {
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
              _buildHeader(),
              DesignTokens.sectionGap,
              _buildMarketStats(gameState),
              DesignTokens.sectionGap,
              _buildSellSection(gameState),
              DesignTokens.sectionGap,
              _buildMarketingSection(gameState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const PanelHeader(
      emoji: '🏪',
      title: 'Marché',
    );
  }

  Widget _buildMarketStats(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              emoji: '📊',
              title: 'Statistiques Marché',
            ),
            DesignTokens.sectionGap,
            StatCard(
              emoji: '💰',
              label: 'Prix actuel',
              value: '\$${gameState.marketManager.currentPrice.toStringAsFixed(3)}',
              color: Colors.green,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '💵',
              label: 'Fonds disponibles',
              value: '\$${gameState.playerManager.money.toStringAsFixed(2)}',
              color: Colors.green.shade700,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '📈',
              label: 'Revenus totaux',
              value: '\$${gameState.statistics.totalMoneyEarned.toStringAsFixed(2)}',
              color: Colors.teal,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '📎',
              label: 'Trombones en stock',
              value: '${gameState.playerManager.paperclips.toStringAsFixed(0)}',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              emoji: '🤝',
              title: 'Vente Automatique',
            ),
            DesignTokens.mediumGap,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vente auto activée'),
                Switch(
                  value: gameState.autoSellEnabled,
                  onChanged: (value) => gameState.setAutoSellEnabled(value),
                ),
              ],
            ),
            DesignTokens.smallGap,
            Text(
              'Les trombones sont vendus automatiquement au prix du marché',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketingSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              emoji: '📢',
              title: 'Marketing',
            ),
            DesignTokens.mediumGap,
            Text(
              'Améliorez votre marketing pour augmenter la demande',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            DesignTokens.mediumGap,
            ActionButton(
              emoji: '📢',
              label: 'Campagne Marketing (Bientôt)',
              onPressed: null, // TODO: Implémenter marketing
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}
