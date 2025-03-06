import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../widgets/resource_widgets.dart';

class SaveLoadHeader extends StatelessWidget {
  const SaveLoadHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerViewModel>(
      builder: (context, playerViewModel, child) {
        final playerState = playerViewModel.playerState;

        if (playerState == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sauvegarde et Chargement',
                  style: Theme.of(context).textTheme.headline6,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResourceWidget(
                      icon: Icons.attach_money,
                      label: 'Argent',
                      value: playerState.money,
                    ),
                    ResourceWidget(
                      icon: Icons.attachment,
                      label: 'Trombones',
                      value: playerState.clips,
                    ),
                    ResourceWidget(
                      icon: Icons.inventory,
                      label: 'Métal',
                      value: playerState.metal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      context,
                      'Niveau',
                      playerState.level.toString(),
                      Icons.star,
                    ),
                    _buildStatItem(
                      context,
                      'Production/s',
                      '${playerState.clipsPerSecond.toStringAsFixed(1)}',
                      Icons.speed,
                    ),
                    _buildStatItem(
                      context,
                      'Autoclippers',
                      playerState.autoclippers.toString(),
                      Icons.precision_manufacturing,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.caption,
        ),
      ],
    );
  }
} 