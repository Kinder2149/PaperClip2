import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des ventes'),
      ),
      body: Consumer<GameState>(
        builder: (context, gameState, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: gameState.marketManager.salesHistory.length,
            itemBuilder: (context, index) {
              final sale = gameState.marketManager.salesHistory[index];
              return ListTile(
                title: Text('Quantité : ${sale.quantity}'),
                subtitle: Text('Prix : ${sale.price.toStringAsFixed(2)} € - Revenus : ${sale.revenue.toStringAsFixed(2)} €'),
                trailing: Text(sale.timestamp.toString()),
              );
            },
          );
        },
      ),
    );
  }
}