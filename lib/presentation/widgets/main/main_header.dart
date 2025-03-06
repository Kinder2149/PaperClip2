import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/player_viewmodel.dart';
import '../viewmodels/market_viewmodel.dart';
import '../widgets/resource_widgets.dart';

class MainHeader extends StatelessWidget {
  const MainHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayerViewModel, MarketViewModel>(
      builder: (context, playerViewModel, marketViewModel, child) {
        final playerState = playerViewModel.playerState;
        final marketState = marketViewModel.marketState;

        if (playerState == null || marketState == null) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Niveau ${playerState.level}',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Text(
                      '${playerState.experience}/${playerState.experienceToNextLevel} XP',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: playerState.experience / playerState.experienceToNextLevel,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
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
                    Text(
                      'Prix: ${marketState.currentPrice.toStringAsFixed(2)}€',
                      style: TextStyle(
                        color: _getPriceColor(marketState.currentPrice),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Demande: ${marketState.currentDemand.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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

  Color _getPriceColor(double price) {
    if (price > 1.0) {
      return Colors.green;
    } else if (price < 0.5) {
      return Colors.red;
    }
    return Colors.orange;
  }
} 