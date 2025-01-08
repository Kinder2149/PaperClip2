import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/constants.dart';
import '../models/market/market_manager.dart';
import '../widgets/money_display.dart';
import '../widgets/sales_chart.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  String _formatTimeDifference(DateTime? time1, DateTime? time2) {
    if (time1 == null || time2 == null) return '-';
    final difference = time1.difference(time2);
    return '${difference.inSeconds}.${(difference.inMilliseconds % 1000).toString().padLeft(3, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const MoneyDisplay(),
              const SizedBox(height: 20),
              Text(
                'Métal disponible: ${gameState.metal.toStringAsFixed(3)}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                'Réputation: ${(gameState.marketManager.reputation * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Prix de vente: ${gameState.sellPrice.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: Slider(
                      value: gameState.sellPrice,
                      min: MarketManager.MIN_PRICE,
                      max: MarketManager.MAX_PRICE,
                      divisions: 99,
                      onChanged: (value) => gameState.setSellPrice(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: gameState.money >= gameState.currentMetalPrice
                    ? gameState.buyMetal
                    : null,
                child: Text(
                  'Acheter ${GameConstants.METAL_PACK_AMOUNT} métal (${gameState.currentMetalPrice.toStringAsFixed(2)} €)',
                ),
              ),
              // ... reste du code ...
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SalesChart(salesHistory: gameState.marketManager.salesHistory),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}