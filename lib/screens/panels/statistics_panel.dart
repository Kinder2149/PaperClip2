import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import '../../models/reset_history_entry.dart';

/// Panel Statistiques - Statistiques détaillées du jeu
/// 
/// Affiche les statistiques de production, économiques et l'historique
class StatisticsPanel extends StatelessWidget {
  const StatisticsPanel({Key? key}) : super(key: key);

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
          _buildProductionStats(gameState),
          const SizedBox(height: 16),
          _buildEconomicStats(gameState),
          const SizedBox(height: 16),
          _buildTimeStats(gameState),
          const SizedBox(height: 16),
          _buildResetHistory(gameState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.bar_chart, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Text(
          'Statistiques',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProductionStats(GameState gameState) {
    final stats = gameState.statistics;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.factory, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Production',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Trombones produits (total)',
              '${stats.totalPaperclipsProduced}',
              Icons.attach_file,
            ),
            _buildStatRow(
              'Trombones manuels',
              '${stats.manualPaperclipsProduced}',
              Icons.touch_app,
            ),
            _buildStatRow(
              'Trombones automatiques',
              '${stats.totalPaperclipsProduced - stats.manualPaperclipsProduced}',
              Icons.smart_toy,
            ),
            _buildStatRow(
              'Métal utilisé',
              '${stats.totalMetalUsed.toStringAsFixed(1)}',
              Icons.construction,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomicStats(GameState gameState) {
    final stats = gameState.statistics;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Économie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              'Argent gagné (total)',
              '${stats.totalMoneyEarned.toStringAsFixed(2)}€',
              Icons.trending_up,
            ),
            _buildStatRow(
              'Argent dépensé',
              '${stats.totalMoneySpent.toStringAsFixed(2)}€',
              Icons.trending_down,
            ),
            _buildStatRow(
              'Argent actuel',
              '${gameState.playerManager.money.toStringAsFixed(2)}€',
              Icons.account_balance_wallet,
            ),
            _buildStatRow(
              'Métal acheté',
              '${stats.totalMetalPurchased.toStringAsFixed(1)}',
              Icons.shopping_cart,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeStats(GameState gameState) {
    final totalSeconds = gameState.statistics.totalGameTimeSec;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Temps de jeu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '${hours}h ${minutes}m ${seconds}s',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Total: $totalSeconds secondes',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetHistory(GameState gameState) {
    final history = gameState.resetHistory;
    
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
                const Icon(Icons.history, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Historique des Resets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Aucun reset effectué',
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  _buildResetSummary(gameState),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  ...history.reversed.take(5).map((entry) => _buildResetEntry(entry)),
                  if (history.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... et ${history.length - 5} autres resets',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSummary(GameState gameState) {
    final history = gameState.resetHistory;
    final totalQuantum = history.fold<int>(0, (sum, entry) => sum + entry.quantumGained);
    final totalInnovation = history.fold<int>(0, (sum, entry) => sum + entry.innovationGained);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '${history.length} reset${history.length > 1 ? 's' : ''} effectué${history.length > 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Icon(Icons.flash_on, color: Colors.blue, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '$totalQuantum',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Text(
                    'Quantum total',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              Column(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    '$totalInnovation',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    'PI total',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetEntry(ResetHistoryEntry entry) {
    final date = entry.timestamp;
    final dateStr = '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Niveau ${entry.levelBefore}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flash_on, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text('+${entry.quantumGained}', style: const TextStyle(color: Colors.blue)),
                const SizedBox(width: 16),
                const Icon(Icons.lightbulb, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text('+${entry.innovationGained}', style: const TextStyle(color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
