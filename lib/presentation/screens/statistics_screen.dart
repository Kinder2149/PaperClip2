// lib/presentation/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';
import '../widgets/statistics/stats_header.dart';
import '../widgets/statistics/production_stats.dart';
import '../widgets/statistics/market_stats.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: Consumer<GameViewModel>(
        builder: (context, gameViewModel, child) {
          if (gameViewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (gameViewModel.error != null) {
            return Center(
              child: Text(
                gameViewModel.error!,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                StatsHeader(),
                SizedBox(height: 24),
                ProductionStats(),
                SizedBox(height: 24),
                MarketStats(),
              ],
            ),
          );
        },
      ),
    );
  }
}