import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';

/// Panel Dashboard - Vue d'ensemble du jeu
/// 
/// Affiche les statistiques clés, la progression et les objectifs
class DashboardPanel extends StatelessWidget {
  const DashboardPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildStatsGrid(gameState),
          const SizedBox(height: 24),
          _buildProgressionCard(gameState),
          const SizedBox(height: 24),
          _buildRareResourcesCard(gameState),
          const SizedBox(height: 24),
          _buildQuickActions(context, gameState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.dashboard, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(
          'Tableau de Bord',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(GameState gameState) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.attach_money,
          label: 'Argent',
          value: '${gameState.playerManager.money.toStringAsFixed(2)}€',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.attach_file,
          label: 'Trombones',
          value: '${gameState.playerManager.paperclips.toStringAsFixed(0)}',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.construction,
          label: 'Métal',
          value: '${gameState.playerManager.metal.toStringAsFixed(0)}',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.smart_toy,
          label: 'Autoclippers',
          value: '${gameState.playerManager.autoClipperCount}',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressionCard(GameState gameState) {
    final level = gameState.levelSystem.currentLevel;
    final xp = gameState.levelSystem.currentXP;
    final xpToNext = gameState.levelSystem.xpToNextLevel;
    final progress = xpToNext > 0 ? (xp / xpToNext).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau $level',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${xp.toStringAsFixed(0)} / ${xpToNext.toStringAsFixed(0)} XP',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRareResourcesCard(GameState gameState) {
    return Card(
      elevation: 2,
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stars, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Ressources Rares',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRareResourceChip(
                  icon: Icons.flash_on,
                  label: 'Quantum',
                  value: '${gameState.quantum}',
                  color: Colors.blue,
                ),
                _buildRareResourceChip(
                  icon: Icons.lightbulb,
                  label: 'Points Innovation',
                  value: '${gameState.pointsInnovation}',
                  color: Colors.orange,
                ),
              ],
            ),
            if (gameState.resetCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Resets effectués : ${gameState.resetCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRareResourceChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, GameState gameState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Actions Rapides',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionChip(
                  icon: Icons.shopping_cart,
                  label: 'Acheter Métal',
                  onTap: () => _buyMetal(gameState),
                  enabled: gameState.canBuyMetal(),
                ),
                if (gameState.resetManager.canReset())
                  _buildActionChip(
                    icon: Icons.restart_alt,
                    label: 'Reset Progression',
                    onTap: () => _showResetInfo(context, gameState),
                    enabled: true,
                    color: Colors.purple,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
    Color? color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: enabled ? (color ?? Colors.blue) : Colors.grey),
      label: Text(label),
      onPressed: enabled ? onTap : null,
      backgroundColor: enabled ? (color?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1)) : Colors.grey.shade200,
    );
  }

  void _buyMetal(GameState gameState) {
    gameState.purchaseMetal();
  }

  void _showResetInfo(BuildContext context, GameState gameState) {
    final rewards = gameState.resetManager.calculatePotentialRewards();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💼 Reset Progression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vous pouvez effectuer un reset progression !'),
            const SizedBox(height: 16),
            Text('Gains potentiels :'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text('${rewards.quantum} Quantum', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('${rewards.innovationPoints} Points Innovation', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Rendez-vous dans l\'onglet Progression pour plus de détails.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
