import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
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
                'Demande du marché: ${(gameState.marketDemand * 100).toStringAsFixed(1)}%',
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
                      min: 0.01,
                      max: 1.0,
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
                  'Acheter ${GameState.METAL_PACK_AMOUNT} métal (${gameState.currentMetalPrice.toStringAsFixed(2)} €)',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Évolution des ventes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.7,
                          maxChildSize: 0.9,
                          minChildSize: 0.5,
                          builder: (context, scrollController) => Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Historique des ventes',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: gameState.salesHistory.length,
                                    itemBuilder: (context, index) {
                                      final sale = gameState.salesHistory[
                                      gameState.salesHistory.length - 1 - index
                                      ];
                                      final previousSale = index < gameState.salesHistory.length - 1
                                          ? gameState.salesHistory[gameState.salesHistory.length - 2 - index]
                                          : null;
                                      return ListTile(
                                        dense: true,
                                        title: Text(
                                          '${sale.quantity} trombones à ${sale.price.toStringAsFixed(2)}€',
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Text(
                                          'Revenu: ${sale.revenue.toStringAsFixed(2)}€\n'
                                              'Temps depuis dernière vente: ${_formatTimeDifference(sale.timestamp, previousSale?.timestamp)}',
                                        ),
                                        trailing: Text(
                                          '${sale.timestamp.hour}:${sale.timestamp.minute}:${sale.timestamp.second}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SalesChart(salesHistory: gameState.salesHistory),
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