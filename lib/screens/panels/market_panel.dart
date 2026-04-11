import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/widgets/design_system/design_system.dart';

/// Panel marché — Marché mondial simulé + vente de trombones
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
              _buildWorldMarketSection(gameState),
              DesignTokens.sectionGap,
              _buildPlayerPriceSection(context, gameState),
              DesignTokens.sectionGap,
              _buildSalesStatsSection(gameState),
              DesignTokens.sectionGap,
              _buildAutoSellSection(gameState),
              DesignTokens.sectionGap,
              _buildMarketingSection(gameState),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // En-tête
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return const PanelHeader(
      emoji: '🌍',
      title: 'Marché Mondial',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Section 1 — Données du marché mondial (concurrent, demande, part)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildWorldMarketSection(GameState gameState) {
    final market = gameState.marketManager;
    final worldDemand = market.worldDemand;
    final competitorPrice = market.competitorPrice;
    final playerShare = market.playerMarketShare;
    final salesPerSec = market.lastTickSalesPerSecond;

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(emoji: '📡', title: 'Marché Mondial en Temps Réel'),
            DesignTokens.sectionGap,

            // Demande mondiale
            StatCard(
              emoji: '🌐',
              label: 'Demande mondiale',
              value: '${worldDemand.toStringAsFixed(0)} trombones/s',
              color: Colors.blue,
            ),
            DesignTokens.mediumGap,

            // Prix concurrent
            StatCard(
              emoji: '🏭',
              label: 'Prix concurrent',
              value: '${competitorPrice.toStringAsFixed(3)} €',
              color: Colors.orange,
            ),
            DesignTokens.mediumGap,

            // Part de marché du joueur
            _buildMarketShareRow(playerShare),
            DesignTokens.mediumGap,

            // Ventes réelles/s
            StatCard(
              emoji: '💸',
              label: 'Ventes réalisées',
              value: '${salesPerSec.toStringAsFixed(1)} trombones/s',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketShareRow(double share) {
    final percent = (share * 100).toStringAsFixed(1);
    final color = _shareColor(share);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Part de marché', style: TextStyle(fontSize: 14)),
            Text(
              '$percent %',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Color _shareColor(double share) {
    if (share >= 0.45) return Colors.green;
    if (share >= 0.20) return Colors.orange;
    return Colors.red;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Section 2 — Prix du joueur + indicateur compétitivité
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildPlayerPriceSection(BuildContext context, GameState gameState) {
    final playerPrice = gameState.player.sellPrice;
    final competitorPrice = gameState.marketManager.competitorPrice;

    final delta = (competitorPrice - playerPrice) / competitorPrice;
    final competitivity = _competitivityLabel(delta);

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(emoji: '💰', title: 'Votre Prix de Vente'),
            DesignTokens.sectionGap,

            // Prix actuel + indicateur
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${playerPrice.toStringAsFixed(3)} €',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: competitivity.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: competitivity.color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(competitivity.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        competitivity.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: competitivity.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Concurrent : ${competitorPrice.toStringAsFixed(3)} €',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            DesignTokens.mediumGap,

            // Slider de prix
            Slider(
              value: playerPrice.clamp(GameConstants.MIN_PRICE, GameConstants.MAX_PRICE),
              min: GameConstants.MIN_PRICE,
              max: GameConstants.MAX_PRICE,
              divisions: 49, // paliers de 0.01€
              label: '${playerPrice.toStringAsFixed(2)} €',
              activeColor: competitivity.color,
              onChanged: (value) {
                gameState.setSellPrice(double.parse(value.toStringAsFixed(2)));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${GameConstants.MIN_PRICE.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '${GameConstants.MAX_PRICE.toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            DesignTokens.smallGap,

            // Revenu estimé par seconde
            _buildEstimatedRevenue(gameState, playerPrice),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedRevenue(GameState gameState, double playerPrice) {
    final market = gameState.marketManager;
    final player = gameState.player;
    final demand = market.calculateDemand(playerPrice, player.getMarketingLevel());
    final revenuePerSec = playerPrice * demand;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Revenu estimé : ${revenuePerSec.toStringAsFixed(2)} €/s',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  _CompetitivityInfo _competitivityLabel(double delta) {
    if (delta >= 0.15) {
      return _CompetitivityInfo('🟢', 'Très compétitif', Colors.green);
    } else if (delta >= 0) {
      return _CompetitivityInfo('🟡', 'Compétitif', Colors.orange.shade700);
    } else if (delta >= -0.15) {
      return _CompetitivityInfo('🟠', 'Légèrement cher', Colors.deepOrange);
    } else {
      return _CompetitivityInfo('🔴', 'Trop cher', Colors.red);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Section 3 — Statistiques de ventes
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildSalesStatsSection(GameState gameState) {
    final market = gameState.marketManager;
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(emoji: '📊', title: 'Statistiques de Vente'),
            DesignTokens.sectionGap,
            StatCard(
              emoji: '💵',
              label: 'Fonds disponibles',
              value: '${gameState.playerManager.money.toStringAsFixed(2)} €',
              color: Colors.green.shade700,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '📈',
              label: 'Revenus totaux',
              value: '${market.totalSalesRevenue.toStringAsFixed(2)} €',
              color: Colors.teal,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '📎',
              label: 'Trombones en stock',
              value: '${gameState.playerManager.paperclips.toStringAsFixed(0)}',
              color: Colors.blue,
            ),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '⭐',
              label: 'Réputation',
              value: market.reputation.toStringAsFixed(2),
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Section 4 — Vente automatique
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildAutoSellSection(GameState gameState) {
    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(emoji: '🤝', title: 'Vente Automatique'),
            DesignTokens.mediumGap,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text('Vendre automatiquement au prix fixé'),
                ),
                Switch(
                  value: gameState.autoSellEnabled,
                  onChanged: (value) => gameState.setAutoSellEnabled(value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Section 5 — Marketing
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildMarketingSection(GameState gameState) {
    final marketingLevel = gameState.player.getMarketingLevel();
    final marketingMultiplier = 1.0 + marketingLevel * GameConstants.MARKETING_BOOST_PER_LEVEL;

    return Card(
      child: Padding(
        padding: DesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(emoji: '📢', title: 'Marketing'),
            DesignTokens.mediumGap,
            StatCard(
              emoji: '📣',
              label: 'Niveau marketing',
              value: 'Niv. $marketingLevel (×${marketingMultiplier.toStringAsFixed(2)} demande)',
              color: Colors.orange,
            ),
            DesignTokens.mediumGap,
            Text(
              'Améliorez le marketing dans l\'onglet Améliorations pour augmenter votre part de la demande mondiale.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Modèle interne — Indicateur de compétitivité
// ────────────────────────────────────────────────────────────────────────────

class _CompetitivityInfo {
  final String emoji;
  final String label;
  final Color color;
  const _CompetitivityInfo(this.emoji, this.label, this.color);
}
