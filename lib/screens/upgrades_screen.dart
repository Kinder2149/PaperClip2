import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../widgets/money_display.dart';
import '../models/upgrade.dart';

class UpgradesScreen extends StatelessWidget {
  const UpgradesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: gameState.upgrades.entries.map((entry) {
                    String id = entry.key;
                    Upgrade upgrade = entry.value;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(upgrade.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(upgrade.description),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: upgrade.level / upgrade.maxLevel,
                              minHeight: 8,
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Niveau ${upgrade.level}/${upgrade.maxLevel}'),
                            Text('${upgrade.currentCost.toStringAsFixed(1)} €'),
                          ],
                        ),
                        enabled: gameState.money >= upgrade.currentCost &&
                            upgrade.level < upgrade.maxLevel,
                        onTap: () => gameState.purchaseUpgrade(id),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
