// lib/presentation/screens/market_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/market_viewmodel.dart';
import '../viewmodels/production_viewmodel.dart';
import '../widgets/market/market_header.dart';
import '../widgets/market/market_controls.dart';
import '../widgets/market/market_stats.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marché'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MarketViewModel>().loadMarketState();
            },
          ),
        ],
      ),
      body: Consumer2<MarketViewModel, ProductionViewModel>(
        builder: (context, marketViewModel, productionViewModel, child) {
          if (marketViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (marketViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    marketViewModel.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      marketViewModel.loadMarketState();
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                MarketHeader(),
                SizedBox(height: 16),
                MarketControls(),
                SizedBox(height: 16),
                MarketStats(),
              ],
            ),
          );
        },
      ),
    );
  }
}