import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';
import 'money_indicator.dart';
import 'paperclip_indicator.dart';
import 'metal_indicator.dart';
import 'market_metal_indicator.dart';

class ResourceOverview extends StatelessWidget {
  const ResourceOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (context, gameState, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Ressources',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.spaceAround,
                  children: const [
                    MoneyIndicator(),
                    PaperclipIndicator(),
                    MetalIndicator(),
                    MarketMetalIndicator(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 