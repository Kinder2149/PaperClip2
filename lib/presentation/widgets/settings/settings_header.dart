import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/game_viewmodel.dart';

class SettingsHeader extends StatelessWidget {
  const SettingsHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Consumer<GameViewModel>(
              builder: (context, gameViewModel, child) {
                return Column(
                  children: [
                    _buildInfoRow(
                      context,
                      'Version',
                      gameViewModel.gameVersion,
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      context,
                      'Mode de Jeu',
                      gameViewModel.gameMode.toString().split('.').last,
                      Icons.games,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
} 