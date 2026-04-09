import 'package:paperclip2/models/game_state.dart';

/// Utilitaires pour simuler des actions de jeu
class GameSimulator {
  /// Simuler le passage du temps avec production automatique
  static void simulateTimePassing(GameState gs, Duration duration) {
    final seconds = duration.inSeconds;
    final autoclippers = gs.playerManager.autoClipperCount;
    
    if (autoclippers == 0) return;
    
    // Simuler production automatique (1 trombone/sec/autoclipper)
    for (int i = 0; i < seconds; i++) {
      // Vérifier si assez de métal
      final metalNeeded = autoclippers * 0.1;
      
      if (gs.playerManager.metal < metalNeeded) {
        // Acheter du métal si possible
        if (gs.resourceManager.canPurchaseMetal()) {
          gs.resourceManager.purchaseMetal();
        } else {
          break; // Pas assez d'argent, arrêter la production
        }
      }
      
      // Produire avec autoclippers
      if (gs.playerManager.metal >= metalNeeded) {
        for (int j = 0; j < autoclippers; j++) {
          gs.productionManager.producePaperclip();
        }
      }
    }
  }

  /// Simuler des clics manuels de production
  static int simulateManualClicks(GameState gs, int count) {
    int produced = 0;
    for (int i = 0; i < count; i++) {
      // Acheter du métal si nécessaire
      if (gs.playerManager.metal < 0.1) {
        if (gs.resourceManager.canPurchaseMetal()) {
          gs.resourceManager.purchaseMetal();
        } else {
          break; // Pas assez d'argent pour acheter métal
        }
      }
      
      // Produire un trombone
      if (gs.playerManager.metal >= 0.1) {
        gs.productionManager.producePaperclip();
        produced++;
      }
    }
    return produced;
  }

  /// Acheter des autoclippers jusqu'à atteindre un nombre cible
  static int buyAutoclippersUntil(GameState gs, int targetCount) {
    int bought = 0;
    while (gs.playerManager.autoClipperCount < targetCount) {
      if (gs.productionManager.canBuyAutoclipper()) {
        final success = gs.productionManager.buyAutoclipperOfficial();
        if (success) {
          bought++;
        } else {
          break;
        }
      } else {
        break; // Pas assez d'argent
      }
    }
    return bought;
  }

  /// Vendre des trombones avec le VRAI MarketManager.processSales()
  static double sellPaperclipsReal(GameState gs, double price, {int quantity = 100}) {
    final result = gs.marketManager.processSales(
      playerPaperclips: gs.playerManager.paperclips,
      sellPrice: price,
      marketingLevel: gs.playerManager.getMarketingLevel(),
      qualityLevel: 0, // Quality upgrade pas encore implémenté
      updatePaperclips: (delta) => gs.playerManager.updatePaperclips(
        gs.playerManager.paperclips + delta
      ),
      updateMoney: (delta) => gs.playerManager.updateMoney(
        gs.playerManager.money + delta
      ),
      requireAutoSellEnabled: false, // Pour tests
      verboseLogs: false,
    );
    
    return result.revenue;
  }

  /// Vendre des trombones (simplifié - vente directe, pour compatibilité)
  static double sellPaperclipsSimple(GameState gs, double price, {int quantity = 100}) {
    final paperclipsBefore = gs.playerManager.paperclips;
    
    if (paperclipsBefore <= 0) {
      return 0.0;
    }

    // Vente simple : vendre N trombones au prix spécifié
    final toSell = (quantity < paperclipsBefore) ? quantity : paperclipsBefore.toInt();
    final revenue = toSell * price;
    
    gs.playerManager.updatePaperclips(paperclipsBefore - toSell);
    gs.playerManager.updateMoney(gs.playerManager.money + revenue);
    
    // Mettre à jour stats
    gs.statistics.updateEconomics(moneyEarned: revenue);
    
    return revenue;
  }

  /// Vendre des trombones (alias pour sellPaperclipsSimple, pour compatibilité)
  static double sellPaperclips(GameState gs, double price, {int quantity = 100}) {
    return sellPaperclipsSimple(gs, price, quantity: quantity);
  }

  /// Acheter du métal si le stock est bas
  static bool buyMetalIfNeeded(GameState gs, {double threshold = 50.0}) {
    if (gs.playerManager.metal < threshold) {
      if (gs.resourceManager.canPurchaseMetal()) {
        return gs.resourceManager.purchaseMetal();
      }
    }
    return false;
  }
}
