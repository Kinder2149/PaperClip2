import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/game_constants.dart';
import '../../domain/entities/game_state.dart';
import 'package:flutter/services.dart';




class ProductionButton extends StatelessWidget {
  const ProductionButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = Provider.of<GameState>(context);
    bool canProduce = gameState.player.metal >= GameConstants.METAL_PER_PAPERCLIP;

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: canProduce
            ? () {
          HapticFeedback.mediumImpact();
          gameState.producePaperclip();
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canProduce ? Colors.blue.shade400 : Colors.grey.shade400,
          elevation: canProduce ? 4.0 : 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: canProduce ? Colors.white : Colors.grey.shade300,
              size: 20,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.push_pin,  // Utilisation de l'icÃ´ne attachment Ã  la place
              color: canProduce ? Colors.white : Colors.grey.shade300,
              size: 18,
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produire',
                  style: TextStyle(
                    color: canProduce ? Colors.white : Colors.grey.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${GameConstants.METAL_PER_PAPERCLIP} mÃ©tal',
                  style: TextStyle(
                    color: canProduce
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey.shade300,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}






