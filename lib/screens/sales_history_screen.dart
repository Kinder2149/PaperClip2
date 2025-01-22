import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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
          final salesHistory = gameState.marketManager.salesHistory;

          if (salesHistory.isEmpty) {
            return const Center(
              child: Text(
                  'Aucune vente enregistrée',
                  style: TextStyle(fontSize: 18)
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: salesHistory.length,
            itemBuilder: (context, index) {
              final sale = salesHistory[salesHistory.length - 1 - index]; // Inverser l'ordre
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                      'Quantité : ${sale.quantity} trombones',
                      style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prix : ${sale.price.toStringAsFixed(2)} €'),
                      Text('Revenus : ${sale.revenue.toStringAsFixed(2)} €'),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(sale.timestamp),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}